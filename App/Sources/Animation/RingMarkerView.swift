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
    @State private var breathe = false

    init(color: Color, emphasis: RingEmphasis, reduceMotion: Bool) {
        self.color = color
        self.emphasis = emphasis
        self.reduceMotion = reduceMotion
    }

    private var emphasisScale: CGFloat {
        switch emphasis {
        case .normal: return 1
        case .selectorOn: return 1.34
        case .winner: return 1.24
        case .dimmed: return 0.88
        }
    }

    private var glowIntensity: Double {
        switch emphasis {
        case .normal: return 1.25
        case .selectorOn: return 2.5
        case .winner: return 2.8
        case .dimmed: return 0.25
        }
    }

    private var opacity: Double { emphasis == .dimmed ? 0.24 : 1 }

    var body: some View {
        ZStack {
            GlowDisc(color: color, intensity: glowIntensity * (pulse ? 1.4 : 0.62))
                .frame(width: 158, height: 158)

            Circle()
                .fill(RadialGradient(colors: [color.opacity(0.22), color.opacity(0.035), .clear],
                                     center: .center, startRadius: 3, endRadius: 62))
                .frame(width: 126, height: 126)

            Circle()
                .stroke(color.opacity(0.17), lineWidth: 13)
                .frame(width: 108, height: 108)

            Circle()
                .trim(from: 0.04, to: 0.30)
                .stroke(AngularGradient(colors: [color.opacity(0.08), color, .white, color.opacity(0.08)],
                                        center: .center),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 116, height: 116)
                .rotationEffect(.degrees(orbit ? 360 : 0))

            Circle()
                .trim(from: 0.56, to: 0.72)
                .stroke(.white.opacity(0.9), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 96, height: 96)
                .rotationEffect(.degrees(orbit ? -240 : 0))

            Circle()
                .stroke(color.opacity(0.20), lineWidth: 1)
                .frame(width: 82, height: 82)
                .scaleEffect(breathe ? 1.16 : 0.94)
                .opacity(breathe ? 0.16 : 0.58)

            GlowRing(color: color, diameter: 84, lineWidth: 5, glowOpacity: 0.72)

            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
                .offset(y: -55)
                .shadow(color: color, radius: 8)

            Circle()
                .fill(.white)
                .frame(width: 3, height: 3)
                .offset(x: orbit ? 53 : -53, y: 0)
                .shadow(color: .white, radius: 5)
        }
        .frame(width: 158, height: 158)
        .scaleEffect(pulse ? 1.06 : 0.96)
        .scaleEffect(emphasisScale)
        .opacity(opacity)
        .animation(.spring(response: 0.20, dampingFraction: 0.52), value: emphasis)
        .scaleEffect(appeared ? 1 : 0.42)
        .opacity(appeared ? opacity : 0)
        .onAppear {
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.54)) { appeared = true }
                withAnimation(.easeInOut(duration: 1.05).repeatForever(autoreverses: true)) { pulse = true }
                withAnimation(.linear(duration: 5.5).repeatForever(autoreverses: false)) { orbit = true }
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) { breathe = true }
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
