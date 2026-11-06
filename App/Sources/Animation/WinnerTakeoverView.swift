import SwiftUI
import FingerPickerCore

/// A cinematic reveal that preserves the dark canvas instead of flooding the screen
/// with the winner's palette color.
struct WinnerTakeoverView: View {
    let origin: CGPoint
    let color: Color
    let ink: Color
    let started: Bool
    let reduceMotion: Bool
    let onCompleted: () -> Void

    @State private var reveal: CGFloat = 0
    @State private var completed = false

    private var duration: Double { reduceMotion ? 0.24 : 1.05 }

    var body: some View {
        GeometryReader { geo in
            let maxRadius: CGFloat = coverRadius(in: geo.size)
            ZStack {
                ringsLayer(maxRadius: maxRadius)
                if !reduceMotion {
                    sparksLayer
                }
                sealLayer
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task(id: started) { await run() }
    }

    // The body is split into small, explicitly typed pieces so the Swift type-checker
    // never has to solve one huge expression.

    private func coverRadius(in size: CGSize) -> CGFloat {
        let distance: Double = RevealGeometry.coverRadius(
            origin: (x: Double(origin.x), y: Double(origin.y)),
            width: Double(size.width),
            height: Double(size.height)
        )
        return CGFloat(distance) + 28
    }

    /// Three fine rings travel outward; no opaque color wash.
    private func ringsLayer(maxRadius: CGFloat) -> some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                shockRing(index: index, maxRadius: maxRadius)
            }
        }
    }

    private func shockRing(index: Int, maxRadius: CGFloat) -> some View {
        let gradient = LinearGradient(
            colors: [Color.white.opacity(0.88), color.opacity(0.68), color.opacity(0.08)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        let lineWidth: CGFloat = index == 0 ? 2.2 : 1.15
        let spread: CGFloat = 0.72 + CGFloat(index) * 0.18
        let scale: CGFloat = 1 + reveal * (maxRadius / 27) * spread
        let fade: Double = 0.78 + Double(index) * 0.08
        let alpha: Double = max(0.0, 0.78 - Double(reveal) * fade)
        return Circle()
            .stroke(gradient, lineWidth: lineWidth)
            .frame(width: 54, height: 54)
            .scaleEffect(scale)
            .opacity(alpha)
            .position(origin)
    }

    /// Small sparks travel only a short distance, keeping the result readable.
    private var sparksLayer: some View {
        ZStack {
            ForEach(0..<16, id: \.self) { index in
                spark(index: index)
            }
        }
    }

    private func spark(index: Int) -> some View {
        let angle: Double = Double(index) * (Double.pi * 2.0 / 16.0)
        let travel: CGFloat = 18 + reveal * 76
        let isAccent: Bool = index % 4 == 0
        let size: CGFloat = isAccent ? 3.5 : 2
        let dx: CGFloat = CGFloat(cos(angle)) * travel
        let dy: CGFloat = CGFloat(sin(angle)) * travel
        let alpha: Double = Double(1 - reveal) * 0.85
        let fill: Color = isAccent ? Color.white : color
        return Circle()
            .fill(fill)
            .frame(width: size, height: size)
            .shadow(color: color.opacity(0.8), radius: 5)
            .position(x: origin.x + dx, y: origin.y + dy)
            .opacity(alpha)
    }

    /// A crisp winner seal appears at the touch point.
    private var sealLayer: some View {
        ZStack {
            Circle().fill(color.opacity(0.13)).frame(width: 112, height: 112).blur(radius: 12)
            Circle().stroke(Color.white.opacity(0.78), lineWidth: 2).frame(width: 86, height: 86)
            Circle().stroke(ink.opacity(0.96), lineWidth: 4).frame(width: 68, height: 68)
            Circle().stroke(ink.opacity(0.9), lineWidth: 2).frame(width: 58, height: 58)
            Image(systemName: "crown.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(ink)
                .shadow(color: Color.white.opacity(0.55), radius: 5)
        }
        .scaleEffect(0.72 + reveal * 0.28)
        .opacity(Double(min(1, reveal * 3)))
        .position(origin)
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
