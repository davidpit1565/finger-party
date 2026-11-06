import SwiftUI
import FingerPickerCore

/// A restrained, cinematic winner reveal: the winner's color radiates outward,
/// while the game canvas stays dark and the result remains readable.
struct WinnerTakeoverView: View {
    let origin: CGPoint
    let color: Color
    let started: Bool
    let reduceMotion: Bool
    let onCompleted: () -> Void

    @State private var progress: CGFloat = 0
    @State private var ringProgress: CGFloat = 0
    @State private var completed = false

    private var duration: Double { reduceMotion ? 0.28 : 1.12 }

    var body: some View {
        GeometryReader { geo in
            let radius = CGFloat(RevealGeometry.coverRadius(
                origin: (x: Double(origin.x), y: Double(origin.y)),
                width: Double(geo.size.width), height: Double(geo.size.height)
            )) + 42

            ZStack {
                // A soft color wave, not a solid full-screen color wipe.
                Circle()
                    .fill(RadialGradient(
                        colors: [color.opacity(0.30), color.opacity(0.15), color.opacity(0.045), .clear],
                        center: .center, startRadius: 8, endRadius: radius
                    ))
                    .frame(width: radius * 2, height: radius * 2)
                    .scaleEffect(reduceMotion ? 1 : max(progress, 0.001))
                    .position(origin)

                // Expanding luminous shockwave.
                Circle()
                    .stroke(LinearGradient(colors: [.white.opacity(0.92), color.opacity(0.12)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 2.5)
                    .frame(width: 72, height: 72)
                    .scaleEffect(1 + ringProgress * 8)
                    .opacity(1 - Double(ringProgress))
                    .position(origin)

                // Fine orbiting sparks add a sense of energy without visual clutter.
                if !reduceMotion {
                    ForEach(0..<12, id: \.self) { index in
                        let angle = Double(index) * (.pi * 2 / 12)
                        let distance = CGFloat(28 + ringProgress * 112)
                        Circle()
                            .fill(index.isMultiple(of: 3) ? .white : color)
                            .frame(width: index.isMultiple(of: 3) ? 4 : 2.5,
                                   height: index.isMultiple(of: 3) ? 4 : 2.5)
                            .shadow(color: color.opacity(0.9), radius: 7)
                            .position(x: origin.x + CGFloat(cos(angle)) * distance,
                                      y: origin.y + CGFloat(sin(angle)) * distance)
                            .opacity(Double(1 - ringProgress) * 0.9)
                    }
                }

                // Winner marker resolves in the center of the wave.
                ZStack {
                    Circle().fill(color.opacity(0.16)).frame(width: 132, height: 132).blur(radius: 16)
                    Circle().stroke(color.opacity(0.65), lineWidth: 1.5).frame(width: 94, height: 94)
                    Circle().stroke(.white.opacity(0.9), lineWidth: 3).frame(width: 72, height: 72)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 27, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: color, radius: 14)
                }
                .scaleEffect(0.72 + progress * 0.28)
                .opacity(progress)
                .position(origin)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task(id: started) { await run() }
    }

    @MainActor
    private func run() async {
        guard started else {
            progress = 0
            ringProgress = 0
            completed = false
            return
        }
        guard !completed else { return }

        if reduceMotion {
            withAnimation(.easeOut(duration: duration)) {
                progress = 1
                ringProgress = 1
            }
        } else {
            withAnimation(.timingCurve(0.12, 0.82, 0.22, 1, duration: duration)) {
                progress = 1
            }
            withAnimation(.easeOut(duration: 0.72)) { ringProgress = 1 }
        }

        do { try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000)) }
        catch { return }

        if !completed {
            completed = true
            onCompleted()
        }
    }
}
