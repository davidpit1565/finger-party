import AVFoundation

@MainActor
protocol SoundProviding: AnyObject {
    func tick()
    func winner()
}

/// Plays the two bundled sounds. Uses the ambient session category so the user's music keeps playing.
@MainActor
final class SoundService: SoundProviding {
    private let settings: SettingsStore
    private var players: [String: AVAudioPlayer] = [:]
    private var sessionConfigured = false

    init(settings: SettingsStore) {
        self.settings = settings
    }

    func tick() { play("tick") }
    func winner() { play("win") }

    private func play(_ name: String) {
        guard settings.soundEnabled else { return }
        configureSessionIfNeeded()
        guard let player = player(named: name) else { return }
        player.currentTime = 0
        player.play()
    }

    private func configureSessionIfNeeded() {
        guard !sessionConfigured else { return }
        sessionConfigured = true
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [])
        try? session.setActive(true)
    }

    private func player(named name: String) -> AVAudioPlayer? {
        if let p = players[name] { return p }
        let url = Bundle.main.url(forResource: name, withExtension: "wav")
            ?? Bundle.main.url(forResource: name, withExtension: "wav", subdirectory: "Sounds")
        guard let url, let p = try? AVAudioPlayer(contentsOf: url) else { return nil }
        p.volume = 0.6
        p.prepareToPlay()
        players[name] = p
        return p
    }
}
