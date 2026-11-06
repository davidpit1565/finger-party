import XCTest
import UIKit
import FingerPickerCore
@testable import FingerPicker

/// Drives the real `TouchSessionModel` with an injected fake clock, a deterministic picker and mock
/// haptics/sound. Only the selector hop sequence uses real time (Task.sleep); those tests use Reduce Motion
/// (one 0.3 s step) and bounded polling.
@MainActor
final class TouchSessionModelTests: XCTestCase {

    // MARK: Thresholds

    func testSingleFingerNeverStartsARound() {
        let h = Harness.make(testCase: self)
        h.down(1)
        XCTAssertEqual(h.model.phase, .collecting)
        h.advance(5); h.advance(5)
        XCTAssertEqual(h.model.phase, .collecting)
        XCTAssertNil(h.model.round)
        XCTAssertEqual(h.picker.calls, 0)
    }

    func testAllFingersLiftedBeforeTwoReturnsToIdle() {
        let h = Harness.make(testCase: self)
        h.down(1); h.up(1)
        XCTAssertEqual(h.model.phase, .idle)
        XCTAssertTrue(h.model.candidates.isEmpty)
    }

    // MARK: Settle -> countdown -> lock

    func testTwoFingersSettleCountdownLock() {
        let h = Harness.make(testCase: self)
        h.down(1, 0.2, 0.3); h.down(2, 0.8, 0.6)
        XCTAssertEqual(h.model.phase, .settling)
        h.advance(0.69)
        XCTAssertEqual(h.model.phase, .settling, "settle not yet elapsed")
        h.advance(0.01)
        XCTAssertEqual(h.model.phase, .countdown)
        XCTAssertNotNil(h.model.countdownProgress)
        h.advance(0.5)
        XCTAssertEqual(h.model.countdownProgress ?? -1, 0.5, accuracy: 0.001)
        h.advance(0.5)
        // tick() locks and immediately begins the reveal.
        guard case .revealing(let round) = h.model.phase else { return XCTFail("expected revealing, got \(h.model.phase)") }
        XCTAssertEqual(round.participants.count, 2)
        XCTAssertNil(h.model.countdownProgress)
    }

    func testNewFingerDuringCountdownRestartsSettling() {
        let h = Harness.make(testCase: self)
        h.down(1); h.down(2)
        h.advance(0.7)
        XCTAssertEqual(h.model.phase, .countdown)
        h.down(3)
        XCTAssertEqual(h.model.phase, .settling)
        XCTAssertEqual(h.model.candidates.count, 3)
        h.advance(0.7)
        XCTAssertEqual(h.model.phase, .countdown)
    }

    func testFingerLiftBeforeLockRemovesItFromCandidates() {
        let h = Harness.make(testCase: self)
        h.down(1); h.down(2); h.down(3)
        h.up(2)
        XCTAssertEqual(h.model.candidates.map(\.id), [TouchID(1), TouchID(3)])
        h.up(1)
        XCTAssertEqual(h.model.phase, .collecting)
        h.advance(10)
        XCTAssertNil(h.model.round)
    }

    func testMoveBeforeLockUpdatesPointAndMoveAfterLockIsIgnored() {
        let h = Harness.make(testCase: self)
        h.down(1, 0.1, 0.1); h.down(2, 0.9, 0.9)
        h.model.touchMoved(TouchID(1), to: NormalizedPoint(x: 0.3, y: 0.4))
        XCTAssertEqual(h.model.candidates.first?.point, NormalizedPoint(x: 0.3, y: 0.4))
        h.advance(0.7); h.advance(1.0)
        let frozen = h.model.round
        h.model.touchMoved(TouchID(1), to: NormalizedPoint(x: 0.0, y: 0.0))
        XCTAssertEqual(h.model.round, frozen)
    }

    // MARK: Winner selection

    func testWinnerChosenOnceFromFrozenSetAndMatchesRound() {
        let h2 = Harness.make(winnerIndex: 1, testCase: self)
        h2.reachReveal(fingers: 3)
        guard let round = h2.model.round else { return XCTFail("no round") }
        XCTAssertEqual(h2.picker.calls, 1)
        XCTAssertEqual(h2.picker.lastUpperBound, 3)
        // Index 1 of the id-sorted frozen set {1,2,3}.
        XCTAssertEqual(round.winnerID, TouchID(2))
        // Further ticks / reveal completion never re-run selection or change the winner.
        h2.advance(1); h2.advance(1)
        h2.model.revealCompleted(); h2.model.revealCompleted()
        XCTAssertEqual(h2.picker.calls, 1)
        XCTAssertEqual(h2.model.round?.winnerID, round.winnerID)
    }

    func testWinnerPositionIsOneBasedOrderOfWinnerAmongFingers() {
        let h = Harness.make(winnerIndex: 2, testCase: self)
        h.reachReveal(fingers: 4)
        XCTAssertEqual(h.model.winnerPosition?.index, 2)
        XCTAssertEqual(h.model.winnerPosition?.total, 4)
    }

    func testSelectorEndsOnWinnerWithReduceMotion() async {
        let h = Harness.make(winnerIndex: 1, reduceMotion: true, testCase: self)
        h.reachReveal(fingers: 3)
        let winner = h.model.round!.winnerID
        let done = await waitUntil(timeout: 1.8) { h.model.selectorFinished }
        XCTAssertTrue(done, "reduced selector (one 0.3 s step) should finish")
        XCTAssertEqual(h.model.selectorID, winner)
        h.model.revealCompleted()
        XCTAssertEqual(h.model.selectorID, winner)
        XCTAssertEqual(h.model.round?.winnerID, winner)
        guard case .result = h.model.phase else { return XCTFail("expected result") }
    }

    func testRevealCompletedSnapsSelectorToWinnerEvenIfFullRouteStillRunning() {
        let h = Harness.make(winnerIndex: 2, reduceMotion: false, testCase: self)
        h.reachReveal(fingers: 4)
        XCTAssertFalse(h.model.selectorFinished)
        h.model.revealCompleted()   // synchronous: does not wait for the 2.4 s route
        XCTAssertTrue(h.model.selectorFinished)
        XCTAssertEqual(h.model.selectorID, h.model.round?.winnerID)
    }

    func testFullSelectorRouteAlsoEndsOnWinnerInRealTime() async {
        // Real route is ~2.4 s; give it a bounded 2 s then fall back to the snap guarantee.
        let h = Harness.make(winnerIndex: 1, reduceMotion: false, testCase: self)
        h.reachReveal(fingers: 2)
        let winner = h.model.round!.winnerID
        _ = await waitUntil(timeout: 2.0) { h.model.selectorFinished }
        h.model.revealCompleted()
        XCTAssertEqual(h.model.selectorID, winner)
    }

    // MARK: Late touches, interrupt, replay

    func testLateTouchAfterLockIsIgnored() {
        let h = Harness.make(testCase: self)
        h.reachReveal()
        let before = h.model.round
        h.down(99)
        XCTAssertEqual(h.model.round, before)
        XCTAssertEqual(h.model.round?.participants.count, 2)
        XCTAssertTrue(h.model.candidates.isEmpty)
        XCTAssertEqual(h.picker.calls, 1)
    }

    func testInterruptDuringRevealReturnsToIdleAndCancelsSelector() async {
        let h = Harness.make(reduceMotion: true, testCase: self)
        h.reachReveal()
        h.model.interrupt()
        XCTAssertEqual(h.model.phase, .idle)
        XCTAssertNil(h.model.round)
        XCTAssertNil(h.model.selectorID)
        XCTAssertFalse(h.model.selectorFinished)
        XCTAssertFalse(h.model.canReplay)
        // Cancelled task must not resurrect state when its sleep ends.
        try? await Task.sleep(nanoseconds: 500_000_000)
        XCTAssertNil(h.model.selectorID)
        XCTAssertFalse(h.model.selectorFinished)
        XCTAssertEqual(h.model.phase, .idle)
    }

    func testInterruptWhileSettlingAndCountdownClearsCandidates() {
        let h = Harness.make(testCase: self)
        h.down(1); h.down(2)
        h.model.interrupt()
        XCTAssertEqual(h.model.phase, .idle)
        XCTAssertTrue(h.model.candidates.isEmpty)
        h.advance(5)
        XCTAssertEqual(h.model.phase, .idle, "no stale timer may lock a cancelled round")
        XCTAssertEqual(h.picker.calls, 0)
    }

    func testNewRoundWorksAfterInterrupt() {
        let h = Harness.make(testCase: self)
        h.reachReveal()
        h.model.interrupt()
        h.reachRevealWithIDs(10, 11)
        guard case .revealing = h.model.phase else { return XCTFail("expected revealing") }
        XCTAssertEqual(h.picker.calls, 2)
    }

    func testReplayGatedUntilAllFingersLifted() {
        let h = Harness.make(testCase: self)
        h.reachReveal()
        h.model.revealCompleted()
        guard case .result = h.model.phase else { return XCTFail("expected result") }
        XCTAssertFalse(h.model.canReplay, "both original fingers still down")
        h.model.replay()
        guard case .result = h.model.phase else { return XCTFail("replay must be a no-op while fingers held") }
        h.up(1)
        XCTAssertFalse(h.model.canReplay)
        h.up(2)
        XCTAssertTrue(h.model.canReplay)
        h.model.replay()
        XCTAssertEqual(h.model.phase, .idle)
        XCTAssertNil(h.model.round)
        XCTAssertNil(h.model.selectorID)
        // Repeated replay is a no-op, not a crash or a second reset side effect.
        h.model.replay()
        XCTAssertEqual(h.model.phase, .idle)
    }

    func testLateFingerMustAlsoLiftBeforeReplay() {
        let h = Harness.make(testCase: self)
        h.reachReveal()
        h.down(50)
        h.model.revealCompleted()
        h.up(1); h.up(2)
        XCTAssertFalse(h.model.canReplay)
        h.up(50)
        XCTAssertTrue(h.model.canReplay)
    }

    func testRevealCompletedBeforeRevealIsNoOp() {
        let h = Harness.make(testCase: self)
        h.down(1); h.down(2)
        h.model.revealCompleted()
        XCTAssertEqual(h.model.phase, .settling)
        XCTAssertEqual(h.haptics.winnerCount, 0)
    }

    // MARK: Haptics / sound gating

    func testHapticsAndSoundNotCalledWhenSettingsOff() async {
        let h = Harness.make(reduceMotion: false, sound: false, haptics: false, testCase: self)
        h.reachReveal()
        _ = await waitUntil(timeout: 0.5) { false }   // let a few selector hops run (bounded 0.5 s)
        h.model.revealCompleted()
        XCTAssertEqual(h.haptics.touchRegisteredCount, 0)
        XCTAssertEqual(h.haptics.selectorTickCount, 0)
        XCTAssertEqual(h.haptics.winnerCount, 0)
        XCTAssertEqual(h.sound.tickCount, 0)
        XCTAssertEqual(h.sound.winnerCount, 0)
    }

    func testHapticsAndSoundCalledWhenSettingsOn() async {
        let h = Harness.make(reduceMotion: false, sound: true, haptics: true, testCase: self)
        h.reachReveal(fingers: 3)
        XCTAssertEqual(h.haptics.touchRegisteredCount, 3)
        _ = await waitUntil(timeout: 0.5) { h.haptics.selectorTickCount > 0 }
        XCTAssertGreaterThan(h.haptics.selectorTickCount, 0)
        XCTAssertGreaterThan(h.sound.tickCount, 0)
        h.model.revealCompleted()
        h.model.revealCompleted()   // idempotent: no second winner cue
        XCTAssertEqual(h.haptics.winnerCount, 1)
        XCTAssertEqual(h.sound.winnerCount, 1)
    }

    func testSoundOnHapticsOffAreIndependent() {
        let h = Harness.make(sound: true, haptics: false, testCase: self)
        h.reachReveal()
        h.model.revealCompleted()
        XCTAssertEqual(h.haptics.winnerCount, 0)
        XCTAssertEqual(h.sound.winnerCount, 1)
    }

    func testTogglingSettingsMidSessionTakesEffectImmediately() {
        let h = Harness.make(haptics: false, testCase: self)
        h.down(1)
        XCTAssertEqual(h.haptics.touchRegisteredCount, 0)
        h.settings.hapticsEnabled = true
        h.down(2)
        XCTAssertEqual(h.haptics.touchRegisteredCount, 1)
    }

    func testReduceMotionPathSkipsSelectorTicksButStillRevealsWinner() async {
        let h = Harness.make(winnerIndex: 1, reduceMotion: true, sound: true, haptics: true, testCase: self)
        h.reachReveal(fingers: 3)
        let ok = await waitUntil(timeout: 1.8) { h.model.selectorFinished }
        XCTAssertTrue(ok)
        XCTAssertEqual(h.haptics.selectorTickCount, 0)
        XCTAssertEqual(h.sound.tickCount, 0)
        XCTAssertEqual(h.model.selectorID, h.model.round?.winnerID)
        h.model.revealCompleted()
        XCTAssertEqual(h.haptics.winnerCount, 1)
    }

    // MARK: Orientation / bounds change -> interrupt (real UIView, best effort without a scene)

    func testBoundsChangeInterruptsRound() async {
        let h = Harness.make(testCase: self)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        let view = TouchCaptureUIView(frame: window.bounds)
        view.model = h.model
        window.addSubview(view)
        view.setNeedsLayout()
        view.layoutIfNeeded()           // first layout only records the size
        h.down(1); h.down(2)
        XCTAssertEqual(h.model.phase, .settling)
        view.frame = CGRect(x: 0, y: 0, width: 800, height: 400)   // "rotation"
        view.setNeedsLayout()
        view.layoutIfNeeded()
        // The reset is deliberately deferred to the next main-queue turn (never mutate state inside layout).
        let reset = await waitUntil { h.model.phase == .idle }
        XCTAssertTrue(reset)
        XCTAssertEqual(h.model.phase, .idle)
        XCTAssertTrue(h.model.candidates.isEmpty)
    }

    func testRemovingTouchSurfaceFromWindowInterruptsRound() async {
        let h = Harness.make(testCase: self)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        let view = TouchCaptureUIView(frame: window.bounds)
        view.model = h.model
        window.addSubview(view)
        h.down(1); h.down(2)
        view.removeFromSuperview()
        let reset = await waitUntil { h.model.phase == .idle }   // reset is deferred one main-queue turn
        XCTAssertTrue(reset)
        XCTAssertEqual(h.model.phase, .idle)
    }

    func testBackgroundNotificationInterruptsRound() {
        let h = Harness.make(testCase: self)
        h.down(1); h.down(2)
        NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil)
        XCTAssertEqual(h.model.phase, .idle)
    }
}

@MainActor
private extension Harness {
    /// Like `reachReveal` but with explicit touch ids (ids are never reused by the real touch layer).
    func reachRevealWithIDs(_ a: Int, _ b: Int) {
        down(a, 0.3, 0.3); down(b, 0.7, 0.7)
        advance(0.7)
        advance(1.0)
    }
}
