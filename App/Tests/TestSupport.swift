import XCTest
import FingerPickerCore
@testable import FingerPicker

/// Mutable fake clock handed to the model as `{ clock.now }`.
final class FakeClock {
    var now: Double = 0
}

/// Scripted picker defined locally (the Core package's ScriptedPicker is internal to its own test target).
/// `calls` is a shared reference so the test can observe how often the controller's *copy* of the picker ran.
struct TestScriptedPicker: IndexPicker {
    final class Counter { var calls = 0; var lastUpperBound = 0 }
    let index: Int
    let counter: Counter
    init(index: Int, counter: Counter = Counter()) { self.index = index; self.counter = counter }
    mutating func pick(upperBound: Int) -> Int {
        counter.calls += 1
        counter.lastUpperBound = upperBound
        return index % upperBound
    }
}

@MainActor
final class MockHaptics: HapticsProviding {
    private(set) var touchRegisteredCount = 0
    private(set) var selectorTickCount = 0
    private(set) var winnerCount = 0
    func touchRegistered() { touchRegisteredCount += 1 }
    func selectorTick() { selectorTickCount += 1 }
    func winner() { winnerCount += 1 }
}

@MainActor
final class MockSound: SoundProviding {
    private(set) var tickCount = 0
    private(set) var winnerCount = 0
    func tick() { tickCount += 1 }
    func winner() { winnerCount += 1 }
}

/// Everything a test needs, built with an isolated UserDefaults suite.
@MainActor
struct Harness {
    let model: TouchSessionModel
    let clock: FakeClock
    let haptics: MockHaptics
    let sound: MockSound
    let settings: SettingsStore
    let picker: TestScriptedPicker.Counter

    static func make(winnerIndex: Int = 0,
                     reduceMotion: Bool = true,
                     sound soundOn: Bool = false,
                     haptics hapticsOn: Bool = true,
                     timing: RoundTiming = .standard,
                     testCase: XCTestCase) -> Harness {
        let suite = "FingerPickerTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        testCase.addTeardownBlock { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsStore(defaults: defaults)
        settings.soundEnabled = soundOn
        settings.hapticsEnabled = hapticsOn
        let clock = FakeClock()
        let haptics = MockHaptics()
        let sound = MockSound()
        let counter = TestScriptedPicker.Counter()
        let controller = RoundController(timing: timing, picker: TestScriptedPicker(index: winnerIndex, counter: counter))
        let model = TouchSessionModel(controller: controller,
                                      clock: { clock.now },
                                      settings: settings,
                                      haptics: haptics,
                                      sound: sound,
                                      reduceMotion: { reduceMotion })
        return Harness(model: model, clock: clock, haptics: haptics, sound: sound, settings: settings, picker: counter)
    }

    func down(_ id: Int, _ x: Double = 0.5, _ y: Double = 0.5) {
        model.touchBegan(TouchID(id), at: NormalizedPoint(x: x, y: y))
    }
    func up(_ id: Int) { model.touchEnded(TouchID(id)) }

    /// Advances the fake clock then ticks the model once (what the 30 Hz timer would do).
    func advance(_ seconds: Double) {
        clock.now += seconds
        model.tick()
    }

    /// Two fingers down, run settle + countdown so the round locks and the reveal starts.
    func reachReveal(fingers: Int = 2) {
        for i in 1...fingers { down(i, Double(i) / Double(fingers + 1), 0.4) }
        advance(0.7)   // settling -> countdown
        advance(1.0)   // countdown -> locked -> revealing
    }
}

/// Polls (20 ms steps, bounded) until `condition` holds. Used only for the real-time selector task.
@MainActor
func waitUntil(timeout: TimeInterval = 1.5, _ condition: () -> Bool) async -> Bool {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition() && Date() < deadline {
        try? await Task.sleep(nanoseconds: 20_000_000)
    }
    return condition()
}
