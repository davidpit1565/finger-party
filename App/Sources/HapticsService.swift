import CoreHaptics
import UIKit

@MainActor
protocol HapticsProviding: AnyObject {
    /// A finger joined the round.
    func touchRegistered()
    /// The selector hopped to another finger.
    func selectorTick()
    /// The winner was revealed.
    func winner()
}

/// Core Haptics where supported, UIKit feedback generators otherwise. Every failure is a silent no-op.
@MainActor
final class HapticsService: HapticsProviding {
    private let settings: SettingsStore
    private let supportsCoreHaptics: Bool
    private var engine: CHHapticEngine?

    private var impact: UIImpactFeedbackGenerator?
    private var notification: UINotificationFeedbackGenerator?

    init(settings: SettingsStore) {
        self.settings = settings
        self.supportsCoreHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }

    func touchRegistered() {
        guard settings.hapticsEnabled else { return }
        play(events: [transient(intensity: 0.5, sharpness: 0.5, at: 0)]) {
            self.lightImpact()
        }
    }

    func selectorTick() {
        guard settings.hapticsEnabled else { return }
        play(events: [transient(intensity: 0.35, sharpness: 0.8, at: 0)]) {
            self.lightImpact()
        }
    }

    func winner() {
        guard settings.hapticsEnabled else { return }
        let events = [
            transient(intensity: 1.0, sharpness: 0.6, at: 0),
            transient(intensity: 0.7, sharpness: 0.5, at: 0.12),
            CHHapticEvent(eventType: .hapticContinuous,
                          parameters: [
                            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                          ],
                          relativeTime: 0.2, duration: 0.25)
        ]
        play(events: events) {
            if self.notification == nil { self.notification = UINotificationFeedbackGenerator() }
            self.notification?.notificationOccurred(.success)
        }
    }

    // MARK: Core Haptics

    private func transient(intensity: Float, sharpness: Float, at time: TimeInterval) -> CHHapticEvent {
        CHHapticEvent(eventType: .hapticTransient,
                      parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                      ],
                      relativeTime: time)
    }

    /// Plays the events with Core Haptics, or runs `fallback` if that is unavailable or fails.
    private func play(events: [CHHapticEvent], fallback: () -> Void) {
        guard supportsCoreHaptics, let engine = makeEngineIfNeeded() else { fallback(); return }
        do {
            try engine.start()   // no-op when already running
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            self.engine = nil    // rebuild on next use
            fallback()
        }
    }

    private func makeEngineIfNeeded() -> CHHapticEngine? {
        if let engine { return engine }
        do {
            let e = try CHHapticEngine()
            e.isAutoShutdownEnabled = true
            e.stoppedHandler = { [weak self] _ in
                Task { @MainActor in self?.engine = nil }
            }
            e.resetHandler = { [weak self] in
                Task { @MainActor in self?.engine = nil }
            }
            engine = e
            return e
        } catch {
            return nil
        }
    }

    private func lightImpact() {
        if impact == nil { impact = UIImpactFeedbackGenerator(style: .light) }
        impact?.impactOccurred()
    }
}
