/// Explicit round states (see PRODUCT/TECHNICAL-PLAN.md §2). No view booleans can contradict these.
public enum RoundPhase: Equatable, Sendable {
    case idle                              // no touches
    case collecting                        // 1 touch (not enough to play)
    case settling                          // >= 2 touches, waiting for them to be stable
    case countdown                         // stable; short countdown before lock
    case locked(Round)                     // participants frozen, winner chosen; UI should start reveal
    case revealing(Round)                  // selector + color takeover running
    case result(Round)                     // winner screen; replay gated on all fingers lifted
}

public struct RoundTiming: Equatable, Sendable {
    public var settleDuration: Double      // stable time before countdown starts
    public var countdownDuration: Double   // countdown before lock
    public init(settleDuration: Double = 0.7, countdownDuration: Double = 1.0) {
        self.settleDuration = settleDuration; self.countdownDuration = countdownDuration
    }
    public static let standard = RoundTiming()
}

/// Pure, time-injected state machine for one play surface. It owns the participant set,
/// calls `SelectionEngine` exactly once per round, and never touches UI or real clocks:
/// the host feeds touch events and calls `tick(now:)` from a timer.
public struct RoundController {
    public private(set) var phase: RoundPhase = .idle
    /// Live candidates (only meaningful before lock). Ordered by touch id.
    public private(set) var candidates: [Participant] = []
    /// Fingers currently down on the surface after lock (ignored as participants, tracked for replay gating).
    public private(set) var heldAfterLock: Set<TouchID> = []

    public let timing: RoundTiming
    private var picker: any IndexPicker
    private var stableSince: Double = 0        // time of last change to the candidate set
    private var countdownStart: Double = 0
    private var selectionCount = 0             // how many times the engine ran (tests assert == rounds)

    public var selectionRunCount: Int { selectionCount }

    public init(timing: RoundTiming = .standard, picker: any IndexPicker = SystemIndexPicker()) {
        self.timing = timing
        self.picker = picker
    }

    // MARK: Derived

    public var activeRound: Round? {
        switch phase {
        case .locked(let r), .revealing(let r), .result(let r): return r
        default: return nil
        }
    }

    /// Replay is allowed only on the result screen once every old finger is lifted.
    public var canReplay: Bool {
        if case .result = phase { return heldAfterLock.isEmpty }
        return false
    }

    /// 0...1 progress through the countdown (for UI), nil outside countdown.
    public func countdownProgress(now: Double) -> Double? {
        guard case .countdown = phase else { return nil }
        return min(max((now - countdownStart) / timing.countdownDuration, 0), 1)
    }

    // MARK: Touch events

    public mutating func touchBegan(_ id: TouchID, at point: NormalizedPoint, now: Double) {
        switch phase {
        case .idle, .collecting, .settling, .countdown:
            guard !candidates.contains(where: { $0.id == id }) else { return } // duplicate begin
            let used = Set(candidates.map(\.colorIndex))
            candidates.append(Participant(id: id, point: point, colorIndex: Palette.nextFreeIndex(used: used)))
            candidates.sort { $0.id < $1.id }
            candidatesChanged(now: now)
        case .locked, .revealing, .result:
            heldAfterLock.insert(id)        // late touch: ignored for the round, but must lift before replay
        }
    }

    public mutating func touchMoved(_ id: TouchID, to point: NormalizedPoint, now: Double) {
        switch phase {
        case .idle, .collecting, .settling, .countdown:
            if let i = candidates.firstIndex(where: { $0.id == id }) { candidates[i].point = point }
        case .locked, .revealing, .result:
            break                           // frozen
        }
    }

    public mutating func touchEnded(_ id: TouchID, now: Double) { remove(id, now: now) }
    public mutating func touchCancelled(_ id: TouchID, now: Double) { remove(id, now: now) }

    private mutating func remove(_ id: TouchID, now: Double) {
        switch phase {
        case .idle, .collecting, .settling, .countdown:
            guard let i = candidates.firstIndex(where: { $0.id == id }) else { return }
            candidates.remove(at: i)
            candidatesChanged(now: now)
        case .locked, .revealing, .result:
            heldAfterLock.remove(id)        // frozen participant record is kept
        }
    }

    // MARK: Clock

    /// Advance timers. Call from a ~60 Hz timer or display link while `needsTicks`.
    public mutating func tick(now: Double) {
        switch phase {
        case .settling:
            if now - stableSince >= timing.settleDuration {
                countdownStart = now
                phase = .countdown
            }
        case .countdown:
            if now - countdownStart >= timing.countdownDuration { lock() }
        default:
            break
        }
    }

    public var needsTicks: Bool {
        switch phase { case .settling, .countdown: return true; default: return false }
    }

    // MARK: Round progression

    /// UI calls this when it begins the reveal presentation. Idempotent.
    public mutating func beginReveal() {
        if case .locked(let r) = phase { phase = .revealing(r) }
    }

    /// UI calls this when the reveal presentation completes. Idempotent.
    public mutating func finishReveal() {
        if case .revealing(let r) = phase { phase = .result(r) }
    }

    /// Returns true if the surface was reset. Gated: no-op while any old finger is still down.
    @discardableResult
    public mutating func replay() -> Bool {
        guard canReplay else { return false }
        resetToIdle()
        return true
    }

    /// System interruption (background, call, rotation, view teardown): drop everything.
    public mutating func cancelAll() { resetToIdle() }

    // MARK: Internals

    private mutating func candidatesChanged(now: Double) {
        stableSince = now
        switch candidates.count {
        case 0: phase = .idle
        case 1: phase = .collecting
        default: phase = .settling          // joins/leaves restart settle, even mid-countdown
        }
    }

    private mutating func lock() {
        guard candidates.count >= SelectionEngine.minimumParticipants else { return }
        let frozen = candidates
        // Winner is chosen here, once, from the frozen set — before any animation exists.
        guard let winner = try? SelectionEngine.selectWinner(from: frozen, using: &picker) else {
            resetToIdle(); return
        }
        selectionCount += 1
        heldAfterLock = Set(frozen.map(\.id))   // these fingers are still down until they end
        candidates = []
        phase = .locked(Round(participants: frozen, winnerID: winner))
    }

    private mutating func resetToIdle() {
        candidates = []
        heldAfterLock = []
        phase = .idle
    }
}
