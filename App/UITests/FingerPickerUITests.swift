import XCTest

/// UI tests against the real app. The "collecting" / "winner" scenarios are a DEBUG-only launch hook in
/// TouchSessionModel that feeds real touch events into the real model/UI (see README.md), so these need a
/// Debug build (the default for `xcodebuild test`).
class FingerPickerUITestCase: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    func launch(scenario: String? = nil) {
        if let scenario { app.launchArguments += ["-ui-scenario", scenario] }
        app.launch()
    }

    /// Identifier lookup that does not depend on the element type SwiftUI maps a view to.
    func element(_ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    func toggleValue(_ id: String) -> String? {
        let sw = app.switches[id]
        let target = sw.exists ? sw : element(id)
        return target.value as? String
    }

    /// In a SwiftUI Form the identifier lands on a full-width element; tapping its center hits the label,
    /// which does not toggle. Tap the trailing edge, where the switch control is.
    func flip(_ id: String) {
        let target = app.switches[id].waitForExistence(timeout: 2) ? app.switches[id] : element(id)
        target.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
    }
}

final class FingerPickerUITests: FingerPickerUITestCase {

    func testIdlePromptExists() {
        launch()
        XCTAssertTrue(element("idleHint").waitForExistence(timeout: 5))
        XCTAssertTrue(element("touchSurface").exists)
        XCTAssertTrue(element("settingsButton").exists)
    }

    func testCollectingScenarioShowsFingerCountAndHidesIdleHint() {
        launch(scenario: "collecting")
        let count = element("fingerCount")
        XCTAssertTrue(count.waitForExistence(timeout: 5))
        XCTAssertTrue(count.label.contains("4"), "seeded 4 fingers, label was '\(count.label)'")
        XCTAssertFalse(element("idleHint").exists)
        XCTAssertFalse(element("winnerLabel").exists)
    }

    func testSettingsSheetOpensTogglesFlipAndDoneCloses() {
        launch()
        let gear = element("settingsButton")
        XCTAssertTrue(gear.waitForExistence(timeout: 5))
        gear.tap()

        XCTAssertTrue(element("soundToggle").waitForExistence(timeout: 3))
        XCTAssertTrue(element("hapticsToggle").exists)
        XCTAssertTrue(element("colorMoodPicker").exists)

        // Persisted state survives between launches on a simulator, so assert "flips", not an absolute value.
        let soundBefore = toggleValue("soundToggle")
        XCTAssertNotNil(soundBefore)
        flip("soundToggle")
        XCTAssertNotEqual(toggleValue("soundToggle"), soundBefore)
        flip("soundToggle")   // restore
        XCTAssertEqual(toggleValue("soundToggle"), soundBefore)

        let hapticsBefore = toggleValue("hapticsToggle")
        XCTAssertNotNil(hapticsBefore)
        flip("hapticsToggle")
        XCTAssertNotEqual(toggleValue("hapticsToggle"), hapticsBefore)
        flip("hapticsToggle") // restore
        XCTAssertEqual(toggleValue("hapticsToggle"), hapticsBefore)

        let done = app.buttons["settingsDone"]
        XCTAssertTrue(done.exists)
        done.tap()
        XCTAssertTrue(element("idleHint").waitForExistence(timeout: 3))
        XCTAssertFalse(element("soundToggle").exists)
    }

    func testTenFingerCrowdScenarioDisplaysAllParticipants() {
        launch(scenario: "crowd")
        let count = element("fingerCount")
        XCTAssertTrue(count.waitForExistence(timeout: 5))
        XCTAssertTrue(count.label.contains("10"), "seeded 10 fingers, label was '\(count.label)'")
        XCTAssertFalse(element("idleHint").exists)
    }

    func testWinnerScenarioShowsWinnerAndEnabledPlayAgain() {
        launch(scenario: "winner")
        XCTAssertTrue(element("winnerLabel").waitForExistence(timeout: 5))
        let again = app.buttons["playAgainButton"]
        XCTAssertTrue(again.waitForExistence(timeout: 3))
        XCTAssertTrue(again.isEnabled, "scenario lifts all seeded fingers, so replay must be enabled")
        XCTAssertFalse(element("idleHint").exists)
        // Settings gear is hidden on the result screen (PlayScreen.showsGear).
        XCTAssertFalse(element("settingsButton").exists)
    }

    func testPlayAgainReturnsToIdleHint() {
        launch(scenario: "winner")
        let again = app.buttons["playAgainButton"]
        XCTAssertTrue(again.waitForExistence(timeout: 5))
        again.tap()
        XCTAssertTrue(element("idleHint").waitForExistence(timeout: 3))
        XCTAssertFalse(element("winnerLabel").exists)
        XCTAssertFalse(again.exists)
    }

    func testAccessibilityLabelsAreNonEmpty() {
        launch()
        XCTAssertTrue(element("idleHint").waitForExistence(timeout: 5))
        for id in ["idleHint", "settingsButton", "touchSurface"] {
            let e = element(id)
            XCTAssertTrue(e.exists, id)
            XCTAssertFalse(e.label.isEmpty, "\(id) has an empty accessibility label")
        }
        app.terminate()

        app.launchArguments = []
        launch(scenario: "winner")
        XCTAssertTrue(element("winnerLabel").waitForExistence(timeout: 5))
        XCTAssertFalse(element("winnerLabel").label.isEmpty)
        XCTAssertTrue(element("winnerLabel").label.lowercased().contains("winner"))
        let again = app.buttons["playAgainButton"]
        XCTAssertTrue(again.exists)
        XCTAssertFalse(again.label.isEmpty)
    }

    func testSettingsControlsHaveLabels() {
        launch()
        element("settingsButton").tap()
        XCTAssertTrue(element("soundToggle").waitForExistence(timeout: 3))
        XCTAssertFalse(element("soundToggle").label.isEmpty)
        XCTAssertFalse(element("hapticsToggle").label.isEmpty)
        XCTAssertFalse(app.buttons["settingsDone"].label.isEmpty)
    }
}

/// Captures real simulator screenshots of real app states (see README.md). Attachments are kept always so
/// CI can extract them from the .xcresult bundle.
final class ScreenshotTests: FingerPickerUITestCase {

    private func capture(_ name: String) {
        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func test01Idle() {
        launch()
        XCTAssertTrue(element("idleHint").waitForExistence(timeout: 5))
        capture("01-idle")
    }

    func test02Fingers() {
        launch(scenario: "collecting")
        XCTAssertTrue(element("fingerCount").waitForExistence(timeout: 5))
        capture("02-fingers")
    }

    func test03Crowd() {
        launch(scenario: "crowd")
        XCTAssertTrue(element("fingerCount").waitForExistence(timeout: 5))
        XCTAssertTrue(element("fingerCount").label.contains("10"))
        capture("03-crowd-10-fingers")
    }

    func test04Winner() {
        launch(scenario: "winner")
        XCTAssertTrue(element("winnerLabel").waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["playAgainButton"].waitForExistence(timeout: 3))
        // Give the colour takeover animation a moment to reach its final frame.
        Thread.sleep(forTimeInterval: 1.5)
        capture("03-winner")
    }

    func test05Settings() {
        // Idle launch: the gear is only shown in idle/collecting, and the "collecting" scenario is
        // actually in the settling phase (4 fingers), where the gear is hidden.
        launch()
        let gear = element("settingsButton")
        XCTAssertTrue(gear.waitForExistence(timeout: 5))
        gear.tap()
        XCTAssertTrue(element("soundToggle").waitForExistence(timeout: 3))
        Thread.sleep(forTimeInterval: 0.6)   // sheet presentation animation
        capture("05-settings")
    }
}
