// WinnerTakeoverView.swift - expanding color reveal from the winner's point.

import SwiftUI
import FingerPickerCore

struct WinnerTakeoverView: View {
    let origin: CGPoint
    let color: Color
    let started: Bool
    let reduceMotion: Bool
    let onCompleted: () -> Void

    @State private var progress: CGFloat = 0
    @State private var haloOpacity: Double = 0
    @State private var completed = false

    init(origin: CGPoint, color: Color, started: Bool, reduceMotion: Bool, onCompleted: @escaping () -> Void) {
        self.origin = origin
        self.color = color
        self.started = started
        self.reduceMotion = reduceMotion
        self.onCompleted = onCompleted
    }

    private var duration: Double { reduceMotion ? 0.35 : 0.9 }

    var body: some View {
        GeometryReader { geo in
            let radius = CGFloat(
                RevealGeometry.coverRadius(
                    origin: (x: Double(origin.x), y: Double(origin.y)),
                    width: Double(geo.size.width),
                    height: Double(geo.size.height)
                )
            ) + 24
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: radius * 2, height: radius * 2)
                    .scaleEffect(reduceMotion ? 1.0 : max(progress, 0.0001))
                    .opacity(reduceMotion ? Double(progress) : 1.0)
                    .position(x: origin.x, y: origin.y)

                // Persistent winner halo: soft glow + crisp ring with a dark under-ring
                // so it stays visible on any winner color (including bright yellow).
                ZStack {
                    GlowDisc(color: .white, intensity: 0.7)
                        .frame(width: 150, height: 150)
                    Circle()
                        .strokeBorder(Color.black.opacity(0.28), lineWidth: 9)
                        .frame(width: 66, height: 66)
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 5)
                        .frame(width: 60, height: 60)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 12, height: 12)
                }
                .opacity(haloOpacity)
                .position(x: origin.x, y: origin.y)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task(id: started) {
            await run()
        }
    }

    @MainActor
    private func run() async {
        guard started else {
            // Reset for replay without animation.
            progress = 0
            haloOpacity = 0
            completed = false
            return
        }
        guard !completed else { return }
        let d = duration
        if reduceMotion {
            withAnimation(.easeInOut(duration: d)) { progress = 1 }
        } else {
            withAnimation(.timingCurve(0.16, 0.84, 0.3, 1.0, duration: d)) { progress = 1 }
        }
        withAnimation(.easeOut(duration: 0.3).delay(d * 0.55)) { haloOpacity = 1 }
        do {
            try await Task.sleep(nanoseconds: UInt64(d * 1_000_000_000))
        } catch {
            return // cancelled (view removed or started changed)
        }
        if !completed {
            completed = true
            onCompleted()
        }
    }
}

#Preview("Winner takeover") {
    ZStack {
        Theme.background.ignoresSafeArea()
        WinnerTakeoverView(origin: CGPoint(x: 120, y: 260), color: Theme.color(3),
                           started: true, reduceMotion: false, onCompleted: {})
    }
}

#Preview("Winner takeover (reduce motion)") {
    ZStack {
        Theme.background.ignoresSafeArea()
        WinnerTakeoverView(origin: CGPoint(x: 200, y: 400), color: Theme.color(2),
                           started: true, reduceMotion: true, onCompleted: {})
    }
}
