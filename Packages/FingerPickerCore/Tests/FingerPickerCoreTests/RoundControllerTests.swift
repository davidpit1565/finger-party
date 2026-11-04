import XCTest
@testable import FingerPickerCore

final class RoundControllerTests: XCTestCase {
    func make(_ script: [Int] = [0]) -> RoundController { RoundController(picker: ScriptedPicker(script)) }
    func id(_ n: Int) -> TouchID { TouchID(n) }

    /// Drive a controller through settle + countdown to the lock.
    func runToLock(_ c: inout RoundController, from t: Double) -> Double {
        var now = t
        while c.needsTicks { now += 0.05; c.tick(now: now) }
        return now
    }

    func testIdleAndSingleTouchNeverStartSelection() {
        var c = make()
        XCTAssertEqual(c.phase, .idle)
        c.touchBegan(id(1), at: pt, now: 0)
        XCTAssertEqual(c.phase, .collecting)
        c.tick(now: 100)
        XCTAssertEqual(c.phase, .collecting)
        XCTAssertEqual(c.selectionRunCount, 0)
        c.touchEnded(id(1), now: 101)
        XCTAssertEqual(c.phase, .idle)
    }

    func testTwoTouchesSettleThenCountdownThenLock() {
        var c = make([1])
        c.touchBegan(id(1), at: pt, now: 0)
        c.touchBegan(id(2), at: pt, now: 0.1)
        XCTAssertEqual(c.phase, .settling)
        c.tick(now: 0.5); XCTAssertEqual(c.phase, .settling)
        c.tick(now: 0.8); XCTAssertEqual(c.phase, .countdown)
        XCTAssertNotNil(c.countdownProgress(now: 1.3))
        c.tick(now: 1.7); XCTAssertEqual(c.phase, .countdown)
        c.tick(now: 1.9)
        guard case .locked(let r) = c.phase else { return XCTFail("expected locked, got \(c.phase)") }
        XCTAssertEqual(r.winnerID, id(2))   // scripted index 1 -> second participant
        XCTAssertEqual(c.selectionRunCount, 1)
    }

    func testNewFingerDuringSettleAndCountdownRestartsSettling() {
        var c = make()
        c.touchBegan(id(1), at: pt, now: 0); c.touchBegan(id(2), at: pt, now: 0)
        c.tick(now: 0.7); XCTAssertEqual(c.phase, .countdown)
        c.touchBegan(id(3), at: pt, now: 1.0)
        XCTAssertEqual(c.phase, .settling)
        c.tick(now: 1.5); XCTAssertEqual(c.phase, .settling)   // only 0.5s stable
        c.tick(now: 1.7); XCTAssertEqual(c.phase, .countdown)
        XCTAssertEqual(c.candidates.count, 3)
    }

    func testFingerLiftBeforeLockRemovesCandidateAndCanDropBelowTwo() {
        var c = make()
        c.touchBegan(id(1), at: pt, now: 0); c.touchBegan(id(2), at: pt, now: 0); c.touchBegan(id(3), at: pt, now: 0)
        c.touchEnded(id(3), now: 0.2)
        XCTAssertEqual(c.candidates.map(\.id), [id(1), id(2)]); XCTAssertEqual(c.phase, .settling)
        c.touchCancelled(id(2), now: 0.3)
        XCTAssertEqual(c.phase, .collecting)
        c.touchEnded(id(1), now: 0.4)
        XCTAssertEqual(c.phase, .idle)
        c.tick(now: 50); XCTAssertEqual(c.selectionRunCount, 0)
    }

    func testMoveBeforeLockUpdatesPointAndAfterLockIsIgnored() {
        var c = make([0])
        c.touchBegan(id(1), at: NormalizedPoint(x: 0.1, y: 0.1), now: 0)
        c.touchBegan(id(2), at: NormalizedPoint(x: 0.9, y: 0.9), now: 0)
        c.touchMoved(id(1), to: NormalizedPoint(x: 0.2, y: 0.3), now: 0.1)
        XCTAssertEqual(c.candidates.first?.point, NormalizedPoint(x: 0.2, y: 0.3))
        _ = runToLock(&c, from: 0.1)
        guard let r = c.activeRound else { return XCTFail() }
        XCTAssertEqual(r.winnerPoint, NormalizedPoint(x: 0.2, y: 0.3))    // exact captured coordinate
        c.touchMoved(id(1), to: NormalizedPoint(x: 0.8, y: 0.8), now: 9)
        XCTAssertEqual(c.activeRound, r)                                  // frozen, immutable
    }

    func testWinnerAndColorAreFrozenAtLockAndLateTouchIgnored() {
        var c = make([1])
        c.touchBegan(id(1), at: pt, now: 0); c.touchBegan(id(2), at: pt, now: 0)
        _ = runToLock(&c, from: 0)
        let r = c.activeRound!
        c.touchBegan(id(3), at: pt, now: 5)            // late finger
        XCTAssertEqual(c.activeRound, r)
        XCTAssertEqual(r.participants.map(\.id), [id(1), id(2)])
        XCTAssertEqual(c.selectionRunCount, 1)
        c.tick(now: 10); XCTAssertEqual(c.selectionRunCount, 1)  // never re-selects
    }

    func testRevealTransitionsAreIdempotent() {
        var c = make()
        c.touchBegan(id(1), at: pt, now: 0); c.touchBegan(id(2), at: pt, now: 0)
        _ = runToLock(&c, from: 0)
        c.finishReveal()                                // before beginReveal: no-op
        if case .locked = c.phase {} else { XCTFail() }
        c.beginReveal(); c.beginReveal()
        if case .revealing = c.phase {} else { XCTFail() }
        c.finishReveal(); c.finishReveal()
        if case .result = c.phase {} else { XCTFail() }
        c.beginReveal()
        if case .result = c.phase {} else { XCTFail("must not go backwards") }
    }

    func testReplayGatedUntilAllOldAndLateFingersLift() {
        var c = make()
        c.touchBegan(id(1), at: pt, now: 0); c.touchBegan(id(2), at: pt, now: 0)
        _ = runToLock(&c, from: 0)
        c.beginReveal(); c.finishReveal()
        XCTAssertFalse(c.canReplay)
        XCTAssertFalse(c.replay())                      // fingers still down
        c.touchBegan(id(9), at: pt, now: 6)             // late finger also blocks replay
        c.touchEnded(id(1), now: 6.1); c.touchEnded(id(2), now: 6.2)
        XCTAssertFalse(c.canReplay)
        c.touchCancelled(id(9), now: 6.3)
        XCTAssertTrue(c.canReplay)
        XCTAssertTrue(c.replay())
        XCTAssertEqual(c.phase, .idle)
        XCTAssertTrue(c.candidates.isEmpty)
        XCTAssertFalse(c.replay())                      // second replay call is a no-op
    }

    func testStaleTouchEventsAfterReplayDoNotCreateParticipants() {
        var c = make()
        c.touchBegan(id(1), at: pt, now: 0); c.touchBegan(id(2), at: pt, now: 0)
        _ = runToLock(&c, from: 0); c.beginReveal(); c.finishReveal()
        c.touchEnded(id(1), now: 7); c.touchEnded(id(2), now: 7); XCTAssertTrue(c.replay())
        c.touchMoved(id(1), to: pt, now: 8); c.touchEnded(id(2), now: 8)   // stale ids
        XCTAssertEqual(c.phase, .idle); XCTAssertTrue(c.candidates.isEmpty)
        c.touchBegan(id(1), at: pt, now: 9)             // duplicate id from old round, treated as new begin
        c.touchBegan(id(1), at: pt, now: 9)             // duplicate begin ignored
        XCTAssertEqual(c.candidates.count, 1)
    }

    func testCancelAllFromEveryPhaseReturnsToIdleWithoutStaleState() {
        for stopAt in 0..<5 {
            var c = make()
            c.touchBegan(id(1), at: pt, now: 0)
            if stopAt >= 1 { c.touchBegan(id(2), at: pt, now: 0) }
            if stopAt >= 2 { c.tick(now: 0.7) }
            if stopAt >= 3 { c.tick(now: 1.7) }
            if stopAt >= 4 { c.beginReveal() }
            c.cancelAll()
            XCTAssertEqual(c.phase, .idle, "stopAt=\(stopAt)")
            XCTAssertTrue(c.candidates.isEmpty); XCTAssertTrue(c.heldAfterLock.isEmpty)
            XCTAssertTrue(c.canReplay == false)
        }
    }

    func testColorsAssignedDistinctAndStableAcrossLiftOfOtherFinger() {
        var c = make()
        c.touchBegan(id(1), at: pt, now: 0); c.touchBegan(id(2), at: pt, now: 0); c.touchBegan(id(3), at: pt, now: 0)
        let before = Dictionary(uniqueKeysWithValues: c.candidates.map { ($0.id, $0.colorIndex) })
        XCTAssertEqual(Set(before.values).count, 3)
        c.touchEnded(id(2), now: 1)
        for p in c.candidates { XCTAssertEqual(before[p.id], p.colorIndex) }
        c.touchBegan(id(4), at: pt, now: 1.1)           // takes freed color, no clash
        XCTAssertEqual(Set(c.candidates.map(\.colorIndex)).count, 3)
    }

    func testManyFingersBeyondPaletteDoesNotCrash() {
        var c = make()
        for i in 1...14 { c.touchBegan(id(i), at: pt, now: 0) }
        XCTAssertEqual(c.candidates.count, 14)
        _ = runToLock(&c, from: 0)
        XCTAssertNotNil(c.activeRound)
    }

    func testFairnessMappingEveryParticipantCanWinThroughController() {
        for w in 0..<4 {
            var c = RoundController(picker: ScriptedPicker([w]))
            for i in 1...4 { c.touchBegan(id(i), at: NormalizedPoint(x: Double(i)/5, y: 0.5), now: 0) }
            _ = runToLock(&c, from: 0)
            XCTAssertEqual(c.activeRound?.winnerID, id(w + 1))
            let route = SelectorRoute.make(participants: c.activeRound!.participants, winnerID: c.activeRound!.winnerID)
            XCTAssertEqual(route.last?.id, c.activeRound!.winnerID)   // animation end == stored winner
        }
    }
}
