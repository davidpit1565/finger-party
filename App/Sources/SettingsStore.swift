import Foundation
import Observation
import FingerPickerCore

/// Local sound, haptics and color-mood preferences. No touch or player data is persisted.
@Observable
final class SettingsStore {
    static let soundKey = "soundEnabled"
    static let hapticsKey = "hapticsEnabled"
    static let colorMoodKey = "colorMood"

    @ObservationIgnored private let defaults: UserDefaults

    // Tracked backing storage; the public properties persist on every write.
    private var storedSound: Bool
    private var storedHaptics: Bool
    private var storedColorMood: ColorMood

    var soundEnabled: Bool {
        get { storedSound }
        set { storedSound = newValue; defaults.set(newValue, forKey: Self.soundKey) }
    }

    var hapticsEnabled: Bool {
        get { storedHaptics }
        set { storedHaptics = newValue; defaults.set(newValue, forKey: Self.hapticsKey) }
    }

    var colorMood: ColorMood {
        get { storedColorMood }
        set { storedColorMood = newValue; defaults.set(newValue.rawValue, forKey: Self.colorMoodKey) }
    }

    /// Pass a throwaway `UserDefaults(suiteName:)` in tests.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.storedSound = defaults.object(forKey: Self.soundKey) as? Bool ?? false
        self.storedHaptics = defaults.object(forKey: Self.hapticsKey) as? Bool ?? true
        self.storedColorMood = ColorMood(rawValue: defaults.string(forKey: Self.colorMoodKey) ?? "") ?? .vivid
    }
}
