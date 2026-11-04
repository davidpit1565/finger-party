// RingMarkerView.swift - glowing touch marker.

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

    init(color: Color, emphasis: RingEmphasis, reduceMotion: Bool) {
        self.color = color
        self.emphasis = emphasis
        self.reduceMotion = reduceMotion
    }

    private var emphasisScale: CGFloat {
        switch emphasis {
        case .normal: return 1.0
        case .selectorOn: return 1.25
        case .winner: return 1.15
        case .dimmed: return 0.94
        }
    }

    private var glowIntensity: Double {
        switch emphasis {
        case .normal: return 0.8
        case .selectorOn: return 1.5
        case .winner: return 1.9
        case .dimmed: return 0.4
        }
    }

    private var ringGlowOpacity: Double {
        switch emphasis {
        case .normal: return 0.28
        case .selectorOn: return 0.5
        case .winner: return 0.6
        case .dimmed: return 0.12
        }
    }

    private var contentOpacity: Double {
        emphasis == .dimmed ? 0.38 : 1.0
    }

    var body: some View {
        ZStack {
            GlowDisc(color: color, intensity: glowIntensity * (pulse ? 1.0 : 0.85))
                .frame(width: 96, height: 96)
            GlowRing(color: color, diameter: 56, lineWidth: 4, glowOpacity: ringGlowOpacity)
            Circle()
                .fill(color.opacity(emphasis == .selectorOn || emphasis == .winner ? 1.0 : 0.85))
                .frame(width: 10, height: 10)
        }
        .frame(width: 96, height: 96)
        .scaleEffect(pulse ? 1.035 : 1.0)
        .scaleEffect(emphasisScale)
        .opacity(contentOpacity)
        .animation(.easeOut(duration: 0.12), value: emphasis)
        .scaleEffect(appeared ? 1.0 : 0.3)
        .opacity(appeared ? 1.0 : 0.0)
        .onAppear {
            if reduceMotion {
                withAnimation(.easeOut(duration: 0.2)) { appeared = true }
            } else {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { appeared = true }
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { pulse = true }
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview("Ring markers") {
    ZStack {
        Theme.background.ignoresSafeArea()
        HStack(spacing: 8) {
            RingMarkerView(color: Theme.color(0), emphasis: .normal, reduceMotion: false)
            RingMarkerView(color: Theme.color(1), emphasis: .selectorOn, reduceMotion: false)
            RingMarkerView(color: Theme.color(2), emphasis: .winner, reduceMotion: false)
            RingMarkerView(color: Theme.color(4), emphasis: .dimmed, reduceMotion: true)
        }
    }
}
