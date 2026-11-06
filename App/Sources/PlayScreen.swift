import SwiftUI
import UIKit
import FingerPickerCore

struct PlayScreen: View {
    let model: TouchSessionModel
    @State private var showSettings = false
    @State private var flashOpacity: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            playLayer.ignoresSafeArea()
            overlayLayer
        }
        .background(Theme.background.ignoresSafeArea())
        .overlay {
            Rectangle()
                .fill(.white.opacity(flashOpacity))
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .blendMode(.screen)
        }
        .sheet(isPresented: $showSettings) { SettingsSheet(settings: model.settings) }
        .persistentSystemOverlays(.hidden)
        .defersSystemGestures(on: .all)
        .onChange(of: model.phase) { _, phase in
            UIApplication.shared.isIdleTimerDisabled = (phase != .idle)
            switch phase {
            case .countdown, .revealing:
                flashOpacity = 0.24
                withAnimation(.easeOut(duration: 0.42)) { flashOpacity = 0 }
            default:
                break
            }
        }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }

    private var shownParticipants: [Participant] { model.round?.participants ?? model.candidates }

    private var playLayer: some View {
        GeometryReader { geo in
            ZStack {
                AmbientBackdrop(reduceMotion: reduceMotion)
                TouchCaptureView(model: model)

                ForEach(shownParticipants) { p in
                    RingMarkerView(color: Theme.color(p.colorIndex, mood: model.settings.colorMood),
                                   emphasis: emphasis(for: p),
                                   reduceMotion: reduceMotion)
                        .frame(width: 144, height: 144)
                        .position(point(p.point, in: geo.size))
                        .transition(.scale(scale: 0.55).combined(with: .opacity))
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
                .animation(reduceMotion ? nil : .spring(response: 0.34, dampingFraction: 0.62),
                           value: shownParticipants.map(\.id))

                if let round = model.round, isRevealOrResult {
                    WinnerTakeoverView(origin: point(round.winnerPoint, in: geo.size),
                                       color: Theme.color(round.winnerColorIndex, mood: model.settings.colorMood),
                                       ink: Theme.overlayText(onColorIndex: round.winnerColorIndex),
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

    private var overlayLayer: some View {
        ZStack {
            if case .idle = model.phase {
                IdleWelcome(reduceMotion: reduceMotion)
                    .allowsHitTesting(false)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Finger Picker. Bring everyone in. Place two or more fingers to start.")
                    .accessibilityHint("Touch the screen with two or more fingers to pick one at random")
                    .accessibilityIdentifier("idleHint")
            }

            VStack {
                HStack(alignment: .center) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(Theme.cyan)
                        Text("FINGER PICKER")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .tracking(2.4)
                            .foregroundStyle(.white.opacity(0.78))
                    }
                    Spacer()
                    if showsGear { gearButton }
                }
                Spacer()
                bottomContent
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
        }
    }

    private var showsGear: Bool {
        if case .idle = model.phase { return true }
        return false
    }

    private var gearButton: some View {
        Button { showSettings = true } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.075), in: Circle())
                .overlay(Circle().stroke(.white.opacity(0.12), lineWidth: 1))
                .contentShape(Circle())
        }
        .accessibilityLabel("Settings")
        .accessibilityHint("Opens sound and haptics settings")
        .accessibilityIdentifier("settingsButton")
    }

    @ViewBuilder
    private var bottomContent: some View {
        switch model.phase {
        case .collecting:
            VStack(spacing: 9) {
                Text("HOLD YOUR SPOT")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(2.1)
                    .foregroundStyle(Theme.cyan.opacity(0.9))
                countPill
            }
            .padding(.bottom, 16)
            .allowsHitTesting(false)
        case .settling:
            countPill.padding(.bottom, 16).allowsHitTesting(false)
        case .countdown:
            VStack(spacing: 12) {
                Text("GET READY…")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(2.4)
                    .foregroundStyle(Theme.coral)
                countPill
                CountdownBar(model: model)
            }
            .padding(.bottom, 16)
            .allowsHitTesting(false)
        case .result(let round):
            resultContent(round)
        case .idle, .locked, .revealing:
            EmptyView()
        }
    }

    private var countPill: some View {
        let n = model.candidates.count
        return HStack(spacing: 8) {
            Circle().fill(Theme.lime).frame(width: 7, height: 7)
                .shadow(color: Theme.lime.opacity(0.8), radius: 6)
            Text(n == 1 ? "1 FINGER IN" : "\(n) FINGERS IN")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .tracking(1.8)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 17)
        .padding(.vertical, 11)
        .background(.ultraThinMaterial.opacity(0.72), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.15), lineWidth: 1))
        .accessibilityElement()
        .accessibilityLabel(n == 1 ? "1 finger detected" : "\(n) fingers detected")
        .accessibilityIdentifier("fingerCount")
    }

    private func resultContent(_ round: Round) -> some View {
        let ink = Theme.overlayText(onColorIndex: round.winnerColorIndex)
        let pos = model.winnerPosition
        let detail = pos.map { "Finger \($0.index + 1) of \($0.total)" } ?? ""
        return VStack(spacing: 18) {
            VStack(spacing: 7) {
                Text("IT'S A MATCH!")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(3)
                    .opacity(0.7)
                Text("WINNER")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .tracking(-1.5)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                if !detail.isEmpty {
                    Text(detail.uppercased())
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .tracking(2)
                        .opacity(0.76)
                }
            }
            .foregroundStyle(ink)
            .allowsHitTesting(false)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(detail.isEmpty ? "Winner" : "Winner: \(detail.lowercasedFirst)")
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("winnerLabel")

            Button { model.replay() } label: {
                HStack(spacing: 10) {
                    Text("PLAY AGAIN")
                        .tracking(1.6)
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .black))
                }
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(ink)
                .padding(.horizontal, 27)
                .frame(minHeight: 54)
                .background(.white.opacity(0.10), in: Capsule())
                .overlay(Capsule().stroke(.white.opacity(0.72), lineWidth: 1.2))
                .contentShape(Capsule())
            }
            .disabled(!model.canReplay)
            .opacity(model.canReplay ? 1 : 0.45)
            .accessibilityHint(model.canReplay ? "Starts a new round" : "Lift all fingers from the screen first")
            .accessibilityIdentifier("playAgainButton")

            Text("Lift your fingers, then play again")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(ink.opacity(0.72))
                .opacity(model.canReplay ? 0 : 1)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .padding(.bottom, 28)
        .transition(.opacity.combined(with: .offset(y: 12)))
        .animation(reduceMotion ? .easeOut(duration: 0.18) : .spring(response: 0.38, dampingFraction: 0.82), value: model.canReplay)
    }
}

private extension String {
    var lowercasedFirst: String { prefix(1).lowercased() + dropFirst() }
}

private struct CountdownBar: View {
    let model: TouchSessionModel
    var body: some View {
        let progress = model.countdownProgress ?? 0
        Capsule()
            .fill(.white.opacity(0.16))
            .frame(width: 142, height: 5)
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(LinearGradient(colors: [Theme.cyan, Theme.violet], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 142 * progress, height: 5)
            }
            .accessibilityElement()
            .accessibilityLabel("Selecting")
            .accessibilityValue("\(Int(progress * 100)) percent")
    }
}
