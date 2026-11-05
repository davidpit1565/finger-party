import SwiftUI

enum RingEmphasis {
    case normal, selectorOn, winner, dimmed
}

struct RingMarkerView: View {
    let color: Color
    let emphasis: RingEmphasis
    let reduceMotion: Bool

    @State private var appeared = false
    @State private var pulse = false
    @State private var orbit = false

    init(color: Color, emphasis: RingEmphasis, reduceMotion: Bool) {
        self.color = color
        self.emphasis = emphasis
        self.reduceMotion = reduceMotion
    }

    private var emphasisScale: CGFloat {
        switch emphasis {
        case .normal: return 1
        case .selectorOn: return 1.28
        case .winner: return 1.18
        case .dimmed: return 0.92
        }
    }

    private var glowIntensity: Double {
        switch emphasis {
        case .normal: return 1.0
        case .selectorOn: return 1.8
        case .winner: return 2.0
        case .dimmed: return 0.35
        }
    }

    private var opacity: Double { emphasis == .dimmed ? 0.32 : 1 }

    var body: some View {
        ZStack {
            GlowDisc(color: color, intensity: glowIntensity * (pulse ? 1.15 : 0.78))
                .frame(width: 150, height: 150)

            Circle()
                .fill(color.opacity(0.10))
                .frame(width: 112, height: 112)

            Circle()
                .stroke(color.opacity(0.20), lineWidth: 12)
                .frame(width: 104, height: 104)

            Circle()
                .trim(from: 0.04, to: 0.30)
                .stroke(color.opacity(0.95), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .frame(width: 112, height: 112)
                .rotationEffect(.degrees(orbit ? 360 : 0))

            Circle()
                .trim(from: 0.56, to: 0.72)
                .stroke(.white.opacity(0.72), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                .frame(width: 98, height: 98)
                .rotationEffect(.degrees(orbit ? -180 : 0))

            GlowRing(color: color, diameter: 84, lineWidth: 5, glowOpacity: 0.52)

            Circle()
                .fill(color.opacity(0.95))
                .frame(width: 5, height: 5)
                .offset(y: -53)
                .shadow(color: color, radius: 5)
        }
        .frame(width: 150, height: 150)
        .scaleEffect(pulse ? 1.045 : 0.98)
        .scaleEffect(emphasisScale)
        .opacity(opacity)
        .animation(.spring(response: 0.22, dampingFraction: 0.58), value: emphasis)
        .scaleEffect(appeared ? 1 : 0.55)
        .opacity(appeared ? opacity : 0)
        .onAppear {
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.58)) { appeared = true }
                withAnimation(.easeInOut(duration: 1.25).repeatForever(autoreverses: true)) { pulse = true }
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) { orbit = true }
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview("Finger markers") {
    ZStack {
        AmbientBackdrop(reduceMotion: false)
        HStack(spacing: 0) {
            RingMarkerView(color: Theme.cyan, emphasis: .normal, reduceMotion: false)
            RingMarkerView(color: Theme.coral, emphasis: .selectorOn, reduceMotion: false)
        }
    }
}
