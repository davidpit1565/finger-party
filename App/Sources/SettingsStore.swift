import Foundation
import Observation

/// Local Sound / Haptics preferences. Nothing else is persisted.
@Observable
final class SettingsStore {
    static let soundKey = "soundEnabled"
    static let hapticsKey = "hapticsEnabled"

    @ObservationIgnored private let defaults: UserDefaults

    // Tracked backing storage; the public properties persist on every write.
    private var storedSound: Bool
    private var storedHaptics: Bool

    var soundEnabled: Bool {
        get { storedSound }
        set { storedSound = newValue; defaults.set(newValue, forKey: Self.soundKey) }
    }

    var hapticsEnabled: Bool {
        get { storedHaptics }
        set { storedHaptics = newValue; defaults.set(newValue, forKey: Self.hapticsKey) }
    }

    /// Pass a throwaway `UserDefaults(suiteName:)` in tests.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.storedSound = defaults.object(forKey: Self.soundKey) as? Bool ?? false
        self.storedHaptics = defaults.object(forKey: Self.hapticsKey) as? Bool ?? true
    }
}
