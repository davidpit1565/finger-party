// GlowRing.swift - cheap shared glow primitives (internal). No blur, no shadow stacks.

import SwiftUI

/// Soft radial halo: color fading to clear. Cheap single gradient fill.
struct GlowDisc: View {
    var color: Color
    var intensity: Double = 1.0

    var body: some View {
        GeometryReader { geo in
            let r = min(geo.size.width, geo.size.height) / 2
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(stops: [
                            .init(color: color.opacity(0.55 * intensity), location: 0.0),
                            .init(color: color.opacity(0.22 * intensity), location: 0.55),
                            .init(color: color.opacity(0.0), location: 1.0)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: r
                    )
                )
        }
    }
}

/// Crisp ring plus a wider translucent stroke underneath for a glow feel.
struct GlowRing: View {
    var color: Color
    var diameter: CGFloat
    var lineWidth: CGFloat = 4
    var glowOpacity: Double = 0.3

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(color.opacity(glowOpacity), lineWidth: lineWidth * 2.6)
                .frame(width: diameter + lineWidth, height: diameter + lineWidth)
            Circle()
                .strokeBorder(color, lineWidth: lineWidth)
                .frame(width: diameter, height: diameter)
        }
    }
}
