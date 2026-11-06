import SwiftUI
import FingerPickerCore

/// A cinematic reveal that preserves the dark canvas instead of flooding the screen
/// with the winner's palette color.
struct WinnerTakeoverView: View {
    let origin: CGPoint
    let color: Color
    let started: Bool
    let reduceMotion: Bool
    let onCompleted: () -> Void

    @State private var reveal: CGFloat = 0
    @State private var completed = false

    private var duration: Double { reduceMotion ? 0.24 : 1.05 }

    var body: some View {
        GeometryReader { geo in
            let maxRadius = CGFloat(RevealGeometry.coverRadius(
                origin: (x: Double(origin.x), y: Double(origin.y)),
                width: Double(geo.size.width), height: Double(geo.size.height)
            )) + 28

            ZStack {
                // Three fine rings travel outward; no opaque color wash.
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.88), color.opacity(0.68), color.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: index == 0 ? 2.2 : 1.15
                        )
                        .frame(width: 54, height: 54)
                        .scaleEffect(1 + reveal * (maxRadius / 27) * (0.72 + CGFloat(index) * 0.18))
                        .opacity(Double(max(0, 0.78 - reveal * (0.78 + Double(index) * 0.08))))
                        .position(origin)
                }

                // Small sparks travel only a short distance, keeping the result readable.
                if !reduceMotion {
                    ForEach(0..<16, id: \.self) { index in
                        let angle = Double(index) * (.pi * 2 / 16)
                        let travel = CGFloat(18) + reveal * 76
                        Circle()
                            .fill(index.isMultiple(of: 4) ? .white : color)
                            .frame(width: index.isMultiple(of: 4) ? 3.5 : 2, height: index.isMultiple(of: 4) ? 3.5 : 2)
                            .shadow(color: color.opacity(0.8), radius: 5)
                            .position(
                                x: origin.x + CGFloat(cos(angle)) * travel,
                                y: origin.y + CGFloat(sin(angle)) * travel
                            )
                            .opacity(Double(1 - reveal) * 0.85)
                    }
                }

                // A crisp winner seal appears at the touch point.
                ZStack {
                    Circle().fill(color.opacity(0.13)).frame(width: 112, height: 112).blur(radius: 12)
                    Circle().stroke(color.opacity(0.72), lineWidth: 1.4).frame(width: 82, height: 82)
                    Circle().stroke(.white.opacity(0.92), lineWidth: 2.5).frame(width: 62, height: 62)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 23, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: color.opacity(0.9), radius: 9)
                }
                .scaleEffect(0.72 + reveal * 0.28)
                .opacity(reveal)
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
            reveal = 0
            completed = false
            return
        }
        guard !completed else { return }

        withAnimation(reduceMotion
            ? .easeOut(duration: duration)
            : .timingCurve(0.12, 0.82, 0.22, 1, duration: duration)
        ) {
            reveal = 1
        }

        do { try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000)) }
        catch { return }

        if !completed {
            completed = true
            onCompleted()
        }
    }
}
