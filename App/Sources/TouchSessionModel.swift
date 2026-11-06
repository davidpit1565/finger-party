import Foundation
import Observation
import UIKit
import QuartzCore
import FingerPickerCore

/// Single source of truth for the play surface. Wraps the pure `RoundController`, drives its
/// clock, sequences the (purely visual) selector, and fires haptics/sound/announcements.
@MainActor
@Observable
final class TouchSessionModel {
    // MARK: Observable state (mirrors the controller)
    private(set) var phase: RoundPhase = .idle
    private(set) var candidates: [Participant] = []
    private(set) var round: Round?
    private(set) var canReplay = false
    /// Finger the selector is currently highlighting; nil outside the reveal.
    private(set) var selectorID: TouchID?
    /// True once the selector has landed on the winner and the colour takeover may start.
    private(set) var selectorFinished = false
    /// 0...1 during the countdown, nil otherwise.
    private(set) var countdownProgress: Double?

    @ObservationIgnored let settings: SettingsStore
    @ObservationIgnored private var controller: RoundController
    @ObservationIgnored private let clock: () -> Double
    @ObservationIgnored private let haptics: any HapticsProviding
    @ObservationIgnored private let sound: any SoundProviding
    @ObservationIgnored private let reduceMotion: () -> Bool
    @ObservationIgnored private var selectorTask: Task<Void, Never>?
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var announceTask: Task<Void, Never>?
    @ObservationIgnored private var observers: [NSObjectProtocol] = []

    init(controller: RoundController = RoundController(),
         clock: @escaping () -> Double,
         settings: SettingsStore,
         haptics: any HapticsProviding,
         sound: any SoundProviding,
         reduceMotion: @escaping () -> Bool) {
        self.controller = controller
        self.clock = clock
        self.settings = settings
        self.haptics = haptics
        self.sound = sound
        self.reduceMotion = reduceMotion

        let center = NotificationCenter.default
        for name in [UIApplication.willResignActiveNotification, UIApplication.didEnterBackgroundNotification] {
            observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    // A frozen result screen is safe to keep through a brief interruption.
                    if case .result = self.phase { return }
                    self.interrupt()
                }
            })
        }
        sync()
    }

    // MARK: Derived

    /// Zero-based position of the winner in touch order, and the number of fingers.
    var winnerPosition: (index: Int, total: Int)? {
        guard let round else { return nil }
        let ordered = round.participants.sorted { $0.id < $1.id }
        guard let i = ordered.firstIndex(where: { $0.id == round.winnerID }) else { return nil }
        return (i, ordered.count)
    }

    // MARK: Touch events

    func touchBegan(_ id: TouchID, at point: NormalizedPoint) {
        let before = candidates.count
        controller.touchBegan(id, at: point, now: clock())
        sync()
        if isCollectingPhase, candidates.count > before {
            if settings.hapticsEnabled { haptics.touchRegistered() }
            announceCount()
        }
    }

    func touchMoved(_ id: TouchID, to point: NormalizedPoint) {
        controller.touchMoved(id, to: point, now: clock())
        sync()
    }

    func touchEnded(_ id: TouchID) {
        let before = candidates.count
        controller.touchEnded(id, now: clock())
        sync()
        if isCollectingPhase, candidates.count != before { announceCount() }
    }

    func touchCancelled(_ id: TouchID) {
        let before = candidates.count
        controller.touchCancelled(id, now: clock())
        sync()
        if isCollectingPhase, candidates.count != before { announceCount() }
    }

    // MARK: Clock and round progression

    /// Advances the controller's timers. On lock it immediately starts the reveal; it never selects.
    func tick() {
        controller.tick(now: clock())
        sync()
        if case .locked(let locked) = controller.phase { startReveal(locked) }
    }

    /// Called when the colour takeover finishes. Idempotent.
    func revealCompleted() {
        guard case .revealing(let revealed) = controller.phase else { return }
        if !selectorFinished {
            selectorTask?.cancel()
            selectorTask = nil
            selectorID = revealed.winnerID
            markSelectorFinished()
        }
        controller.finishReveal()
        sync()
        if let pos = winnerPosition {
            announce("Finger \(pos.index + 1) of \(pos.total) selected")
        }
    }

    func replay() {
        guard controller.replay() else { return }
        resetPresentation()
        sync()
    }

    /// System interruption (background, rotation, view teardown): drop everything.
    func interrupt() {
        controller.cancelAll()
        resetPresentation()
        sync()
    }

    // MARK: Internals

    private var isCollectingPhase: Bool {
        switch controller.phase {
        case .idle, .collecting, .settling, .countdown: return true
        default: return false
        }
    }

    private func resetPresentation() {
        selectorTask?.cancel()
        selectorTask = nil
        announceTask?.cancel()
        announceTask = nil
        selectorID = nil
        selectorFinished = false
    }

    private func startReveal(_ locked: Round) {
        controller.beginReveal()
        sync()
        guard selectorTask == nil else { return }   // never start two selector sequences
        let reduced = reduceMotion()
        let steps = reduced
            ? SelectorRoute.reduced(winnerID: locked.winnerID)
            : SelectorRoute.make(participants: locked.participants, winnerID: locked.winnerID)
        selectorTask = Task { [weak self] in
            for step in steps {
                guard let self, !Task.isCancelled else { return }
                self.selectorID = step.id
                if !reduced, step.dwell >= 0.06 {
                    if self.settings.hapticsEnabled { self.haptics.selectorTick() }
                    if self.settings.soundEnabled { self.sound.tick() }
                }
                do { try await Task.sleep(nanoseconds: UInt64(step.dwell * 1_000_000_000)) } catch { return }
            }
            guard let self, !Task.isCancelled else { return }
            self.markSelectorFinished()
        }
    }

    /// Selector has landed on the winner: flip the flag and fire the cues once, in sync with the visuals.
    private func markSelectorFinished() {
        guard !selectorFinished else { return }
        selectorFinished = true
        if settings.hapticsEnabled { haptics.winner() }
        if settings.soundEnabled { sound.winner() }
    }

    /// Copies controller state into observed properties (only when changed, to limit view churn).
    private func sync() {
        let newPhase = controller.phase
        if phase != newPhase { phase = newPhase }
        let newCandidates = controller.candidates
        if candidates != newCandidates { candidates = newCandidates }
        let newRound = controller.activeRound
        if round != newRound { round = newRound }
        let replayable = controller.canReplay
        if canReplay != replayable { canReplay = replayable }
        let progress = controller.countdownProgress(now: clock())
        if countdownProgress != progress { countdownProgress = progress }
        updateTimer()
    }

    private func updateTimer() {
        if controller.needsTicks {
            guard timer == nil else { return }
            let t = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated { self?.tick() }
            }
            RunLoop.main.add(t, forMode: .common)
            timer = t
        } else {
            timer?.invalidate()
            timer = nil
        }
    }

    // MARK: Accessibility

    private func announceCount() {
        announceTask?.cancel()
        guard !candidates.isEmpty else { return }
        announceTask = Task { [weak self] in
            do { try await Task.sleep(nanoseconds: 400_000_000) } catch { return }
            guard let self, !Task.isCancelled, self.isCollectingPhase else { return }
            let count = self.candidates.count
            guard count > 0 else { return }
            self.announce(count == 1 ? "1 finger detected" : "\(count) fingers detected")
        }
    }

    private func announce(_ text: String) {
        UIAccessibility.post(notification: .announcement, argument: text)
    }
}

// MARK: - Live construction and DEBUG UI-test scenarios

extension TouchSessionModel {
    static func makeLive() -> TouchSessionModel {
        let settings = SettingsStore()
        let clock: () -> Double = { CACurrentMediaTime() }
        let reduce: () -> Bool = { UIAccessibility.isReduceMotionEnabled }
        let haptics = HapticsService(settings: settings)
        let sound = SoundService(settings: settings)
        #if DEBUG
        if let scenario = uiScenario() {
            return makeScenario(scenario, settings: settings, haptics: haptics, sound: sound, reduce: reduce)
        }
        #endif
        return TouchSessionModel(clock: clock, settings: settings, haptics: haptics, sound: sound,
                                 reduceMotion: reduce)
    }
}

#if DEBUG
/// Always picks a fixed index, so screenshots/UI tests get a known winner.
private struct FixedIndexPicker: IndexPicker {
    let index: Int
    mutating func pick(upperBound: Int) -> Int { min(index, upperBound - 1) }
}

extension TouchSessionModel {
    /// Launch with `-ui-scenario collecting` or `-ui-scenario winner`.
    fileprivate static func uiScenario() -> String? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-ui-scenario"), i + 1 < args.count else { return nil }
        let value = args[i + 1]
        return ["collecting", "winner", "crowd"].contains(value) ? value : nil
    }

    fileprivate static func makeScenario(_ scenario: String, settings: SettingsStore,
                                         haptics: any HapticsProviding, sound: any SoundProviding,
                                         reduce: @escaping () -> Bool) -> TouchSessionModel {
        let standardPoints = [(0.30, 0.30), (0.72, 0.36), (0.45, 0.62), (0.75, 0.78)]
        let crowdPoints = [(0.22, 0.16), (0.78, 0.16), (0.22, 0.32), (0.78, 0.32), (0.22, 0.48), (0.78, 0.48), (0.22, 0.64), (0.78, 0.64), (0.22, 0.80), (0.78, 0.80)]
        let points = scenario == "crowd" ? crowdPoints : standardPoints
        let isWinner = scenario == "winner"
        // "collecting"/"crowd": timers so long the round never advances. "winner": instant lock, fixed winner.
        let timing = isWinner ? RoundTiming(settleDuration: 0, countdownDuration: 0)
                              : RoundTiming(settleDuration: 1e9, countdownDuration: 1e9)
        let model = TouchSessionModel(controller: RoundController(timing: timing, picker: FixedIndexPicker(index: 2)),
                                      clock: { 0 }, settings: settings, haptics: haptics, sound: sound,
                                      reduceMotion: reduce)
        for (n, p) in points.enumerated() {
            model.touchBegan(TouchID(n + 1), at: NormalizedPoint(x: p.0, y: p.1))
        }
        if isWinner {
            model.tick()   // settling -> countdown
            model.tick()   // countdown -> locked -> reveal starts
            model.debugJumpToResult()
        }
        return model
    }

    /// Skips the animations and lifts every seeded finger, leaving the result screen with replay enabled.
    fileprivate func debugJumpToResult() {
        guard let round else { return }
        selectorTask?.cancel()
        selectorTask = nil
        selectorID = round.winnerID
        selectorFinished = true
        revealCompleted()
        for p in round.participants { touchEnded(p.id) }
    }
}
#endif
