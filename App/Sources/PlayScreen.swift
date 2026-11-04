import SwiftUI
import FingerPickerCore

struct PlayScreen: View {
    let model: TouchSessionModel
    @State private var showSettings = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            playLayer
                .ignoresSafeArea()
            overlayLayer
        }
        .background(Theme.background.ignoresSafeArea())
        .sheet(isPresented: $showSettings) {
            SettingsSheet(settings: model.settings)
        }
    }

    // MARK: Play surface (full screen; its bounds are the coordinate space for touches)

    private var shownParticipants: [Participant] {
        model.round?.participants ?? model.candidates
    }

    private var playLayer: some View {
        GeometryReader { geo in
            ZStack {
                Theme.background
                TouchCaptureView(model: model)

                ForEach(shownParticipants) { p in
                    RingMarkerView(color: Theme.color(p.colorIndex),
                                   emphasis: emphasis(for: p),
                                   reduceMotion: reduceMotion)
                        .frame(width: 96, height: 96)
                        .position(point(p.point, in: geo.size))
                        .transition(.opacity)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
                .animation(reduceMotion ? nil : .easeOut(duration: 0.18),
                           value: shownParticipants.map(\.id))

                if let round = model.round, isRevealOrResult {
                    WinnerTakeoverView(origin: point(round.winnerPoint, in: geo.size),
                                       color: Theme.color(round.winnerColorIndex),
                                       started: model.selectorFinished,
                                       reduceMotion: reduceMotion) {
                        model.revealCompleted()
                    }
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }
            }
        }
    }

    private var isRevealOrResult: Bool {
        switch model.phase {
        case .revealing, .result: return true
        default: return false
        }
    }

    private func point(_ p: NormalizedPoint, in size: CGSize) -> CGPoint {
        let d = RevealGeometry.denormalize(p, width: Double(size.width), height: Double(size.height))
        return CGPoint(x: d.x, y: d.y)
    }

    private func emphasis(for p: Participant) -> RingEmphasis {
        guard let round = model.round else { return .normal }
        if model.selectorFinished { return p.id == round.winnerID ? .winner : .dimmed }
        return p.id == model.selectorID ? .selectorOn : .normal
    }

    // MARK: Controls and text (small, away from the play area; never block touches elsewhere)

    private var overlayLayer: some View {
        ZStack {
            if case .idle = model.phase {
                Text("Place 2 or more fingers")
                    .font(.title3)
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .allowsHitTesting(false)
                    .accessibilityLabel("Place 2 or more fingers")
                    .accessibilityHint("Touch the screen with two or more fingers to pick one at random")
                    .accessibilityIdentifier("idleHint")
            }

            VStack {
                HStack {
                    Spacer()
                    if showsGear { gearButton }
                }
                Spacer()
                bottomContent
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private var showsGear: Bool {
        switch model.phase {
        case .idle, .collecting: return true
        default: return false
        }
    }

    private var gearButton: some View {
        Button {
            showSettings = true
        } label: {
            Image(systemName: "gearshape")
                .font(.title3)
                .foregroundStyle(Theme.secondaryText)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .opacity(0.6)
        .accessibilityLabel("Settings")
        .accessibilityHint("Opens sound and haptics settings")
        .accessibilityIdentifier("settingsButton")
    }

    @ViewBuilder
    private var bottomContent: some View {
        switch model.phase {
        case .collecting:
            VStack(spacing: 8) {
                Text("Place 2 or more fingers")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
                    .accessibilityHidden(true)
                countText
            }
            .padding(.bottom, 12)
            .allowsHitTesting(false)
        case .settling:
            countText
                .padding(.bottom, 12)
                .allowsHitTesting(false)
        case .countdown:
            VStack(spacing: 10) {
                countText
                CountdownBar(model: model)
            }
            .padding(.bottom, 12)
            .allowsHitTesting(false)
        case .result(let round):
            resultContent(round)
        case .idle, .locked, .revealing:
            EmptyView()
        }
    }

    private var countText: some View {
        let n = model.candidates.count
        return Text(n == 1 ? "1 finger" : "\(n) fingers")
            .font(.footnote.weight(.medium))
            .foregroundStyle(Theme.secondaryText)
            .accessibilityLabel(n == 1 ? "1 finger detected" : "\(n) fingers detected")
            .accessibilityIdentifier("fingerCount")
    }

    private func resultContent(_ round: Round) -> some View {
        let ink = Theme.overlayText(onColorIndex: round.winnerColorIndex)
        let pos = model.winnerPosition
        let detail = pos.map { "Finger \($0.index + 1) of \($0.total)" } ?? ""
        return VStack(spacing: 12) {
            VStack(spacing: 4) {
                Text("Winner")
                    .font(.largeTitle.weight(.bold))
                if !detail.isEmpty {
                    Text(detail).font(.title3)
                }
            }
            .foregroundStyle(ink)
            .allowsHitTesting(false)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(detail.isEmpty ? "Winner" : "Winner: \(detail.lowercasedFirst)")
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("winnerLabel")

            Button {
                model.replay()
            } label: {
                Text("Play Again")
                    .font(.headline)
                    .foregroundStyle(ink)
                    .padding(.horizontal, 28)
                    .frame(minHeight: 48)
                    .overlay(Capsule().stroke(ink, lineWidth: 2))
                    .contentShape(Capsule())
            }
            .disabled(!model.canReplay)
            .opacity(model.canReplay ? 1 : 0.45)
            .accessibilityHint(model.canReplay ? "Starts a new round"
                                               : "Lift all fingers from the screen first")
            .accessibilityIdentifier("playAgainButton")

            if !model.canReplay {
                Text("Lift your fingers, then tap Play Again")
                    .font(.footnote)
                    .foregroundStyle(ink)
                    .multilineTextAlignment(.center)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .padding(.bottom, 24)
    }
}

private extension String {
    var lowercasedFirst: String { prefix(1).lowercased() + dropFirst() }
}

/// Split out so only this small view re-renders every timer tick.
private struct CountdownBar: View {
    let model: TouchSessionModel

    var body: some View {
        let progress = model.countdownProgress ?? 0
        Capsule()
            .fill(Theme.secondaryText.opacity(0.25))
            .frame(width: 120, height: 4)
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(Theme.secondaryText)
                    .frame(width: 120 * progress, height: 4)
            }
            .accessibilityElement()
            .accessibilityLabel("Selecting")
            .accessibilityValue("\(Int(progress * 100)) percent")
    }
}
