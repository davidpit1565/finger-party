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
    @State private var burst = false
    @State private var completed = false

    init(origin: CGPoint, color: Color, started: Bool, reduceMotion: Bool, onCompleted: @escaping () -> Void) {
        self.origin = origin
        self.color = color
        self.started = started
        self.reduceMotion = reduceMotion
        self.onCompleted = onCompleted
    }

    private var duration: Double { reduceMotion ? 0.35 : 0.95 }

    var body: some View {
        GeometryReader { geo in
            let radius = CGFloat(RevealGeometry.coverRadius(
                origin: (x: Double(origin.x), y: Double(origin.y)),
                width: Double(geo.size.width), height: Double(geo.size.height)
            )) + 34
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: radius * 2, height: radius * 2)
                    .scaleEffect(reduceMotion ? 1 : max(progress, 0.0001))
                    .opacity(reduceMotion ? Double(progress) : 1)
                    .position(origin)

                if !reduceMotion {
                    Circle()
                        .stroke(.white.opacity(burst ? 0 : 0.72), lineWidth: 3)
                        .frame(width: 76, height: 76)
                        .scaleEffect(burst ? 3.8 : 0.7)
                        .position(origin)
                }

                ZStack {
                    Circle().fill(Theme.ink.opacity(0.16)).frame(width: 126, height: 126)
                    Circle().stroke(Theme.ink.opacity(0.22), lineWidth: 15).frame(width: 82, height: 82)
                    Circle().stroke(Theme.ink, lineWidth: 5).frame(width: 58, height: 58)
                    Circle().fill(Theme.ink).frame(width: 11, height: 11)
                }
                .opacity(haloOpacity)
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
            haloOpacity = 0
            burst = false
            completed = false
            return
        }
        guard !completed else { return }
        let d = duration
        if reduceMotion {
            withAnimation(.easeInOut(duration: d)) { progress = 1 }
        } else {
            withAnimation(.timingCurve(0.12, 0.82, 0.22, 1, duration: d)) { progress = 1 }
            withAnimation(.easeOut(duration: 0.62).delay(0.08)) { burst = true }
        }
        withAnimation(.easeOut(duration: 0.28).delay(0.04)) { haloOpacity = 1 }
        do { try await Task.sleep(nanoseconds: UInt64(d * 1_000_000_000)) }
        catch { return }
        if !completed {
            completed = true
            onCompleted()
        }
    }
}
