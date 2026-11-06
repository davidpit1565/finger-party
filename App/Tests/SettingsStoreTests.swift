import XCTest
@testable import FingerPicker

final class SettingsStoreTests: XCTestCase {
    private func freshDefaults() -> (UserDefaults, String) {
        let suite = "FingerPickerTests.settings.\(UUID().uuidString)"
        let d = UserDefaults(suiteName: suite)!
        addTeardownBlock { d.removePersistentDomain(forName: suite) }
        return (d, suite)
    }

    func testDefaultsSoundOffHapticsOn() {
        let (d, _) = freshDefaults()
        let s = SettingsStore(defaults: d)
        XCTAssertFalse(s.soundEnabled)
        XCTAssertTrue(s.hapticsEnabled)
        XCTAssertEqual(s.colorMood, .vivid)
    }

    func testChangesPersistAcrossNewInstance() {
        let (d, _) = freshDefaults()
        let a = SettingsStore(defaults: d)
        a.soundEnabled = true
        a.hapticsEnabled = false
        a.colorMood = .cool
        let b = SettingsStore(defaults: d)
        XCTAssertTrue(b.soundEnabled)
        XCTAssertFalse(b.hapticsEnabled)
        XCTAssertEqual(b.colorMood, .cool)
    }

    func testPersistedValuesLandUnderPublicKeys() {
        let (d, _) = freshDefaults()
        let s = SettingsStore(defaults: d)
        s.soundEnabled = true
        XCTAssertEqual(d.object(forKey: SettingsStore.soundKey) as? Bool, true)
        s.hapticsEnabled = false
        XCTAssertEqual(d.object(forKey: SettingsStore.hapticsKey) as? Bool, false)
        s.colorMood = .warm
        XCTAssertEqual(d.string(forKey: SettingsStore.colorMoodKey), ColorMood.warm.rawValue)
    }

    func testExplicitFalseForHapticsIsNotReplacedByDefault() {
        let (d, _) = freshDefaults()
        d.set(false, forKey: SettingsStore.hapticsKey)
        XCTAssertFalse(SettingsStore(defaults: d).hapticsEnabled)
    }

    func testSuitesAreIsolatedFromEachOther() {
        let (d1, _) = freshDefaults()
        let (d2, _) = freshDefaults()
        SettingsStore(defaults: d1).soundEnabled = true
        XCTAssertFalse(SettingsStore(defaults: d2).soundEnabled)
    }
}
