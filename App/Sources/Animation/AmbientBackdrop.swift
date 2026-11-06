import SwiftUI

/// Atmospheric background and idle invitation. Decorative layers never participate in hit testing.
struct AmbientBackdrop: View {
    let reduceMotion: Bool
    @State private var drift = false
    @State private var shimmer = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Theme.background
                // Two broad, slowly moving aurora fields create depth without competing with the game.
                Circle()
                    .fill(RadialGradient(colors: [Theme.violet.opacity(0.30), Theme.violet.opacity(0.04), .clear],
                                         center: .center, startRadius: 8, endRadius: 250))
                    .frame(width: 520, height: 520)
                    .offset(x: drift ? -150 : 120, y: drift ? -260 : -80)
                    .blur(radius: 18)
                Circle()
                    .fill(RadialGradient(colors: [Theme.cyan.opacity(0.23), Theme.cyan.opacity(0.035), .clear],
                                         center: .center, startRadius: 4, endRadius: 230))
                    .frame(width: 500, height: 500)
                    .offset(x: drift ? 150 : -130, y: drift ? 250 : 100)
                    .blur(radius: 22)
                Circle()
                    .fill(RadialGradient(colors: [Theme.coral.opacity(0.12), .clear],
                                         center: .center, startRadius: 2, endRadius: 190))
                    .frame(width: 380, height: 380)
                    .offset(x: drift ? 170 : -170, y: shimmer ? 30 : 180)
                    .blur(radius: 30)

                // Fine luminous grain / star points. Their positions remain deterministic.
                ForEach(0..<18, id: \.self) { index in
                    Circle()
                        .fill(index.isMultiple(of: 3) ? Theme.cyan : .white)
                        .frame(width: index.isMultiple(of: 4) ? 2.5 : 1.4,
                               height: index.isMultiple(of: 4) ? 2.5 : 1.4)
                        .shadow(color: Theme.cyan.opacity(0.8), radius: 5)
                        .position(
                            x: geo.size.width * CGFloat((index * 37 % 97) + 1) / 99,
                            y: geo.size.height * CGFloat((index * 53 % 91) + 3) / 100
                        )
                        .opacity(reduceMotion ? 0.26 : ((index % 2 == 0) == shimmer ? 0.62 : 0.12))
                }

                LinearGradient(colors: [.white.opacity(0.045), .clear, .black.opacity(0.18)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                Rectangle().fill(.white.opacity(0.018))
                    .overlay(alignment: .top) {
                        LinearGradient(colors: [.white.opacity(0.07), .clear],
                                       startPoint: .top, endPoint: .bottom)
                            .frame(height: 1)
                    }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) { drift = true }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) { shimmer = true }
        }
    }
}

struct IdleWelcome: View {
    let reduceMotion: Bool
    @State private var pulse = false
    @State private var orbit = false
    @State private var titleGlow = false

    private let colors: [Color] = [Theme.cyan, Theme.coral, Theme.violet, Theme.lime, Color.orange]

    var body: some View {
        GeometryReader { geo in
            // Ring cluster sits above the copy block so nodes never overlap the text.
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height * 0.35)
            ZStack {
                // A soft, breathing target field.
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .stroke(LinearGradient(colors: [.white.opacity(0.13), .white.opacity(0.015)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 1)
                        .frame(width: CGFloat(178 + index * 78), height: CGFloat(178 + index * 78))
                        .scaleEffect(pulse ? 1.035 : 0.965)
                        .position(center)
                }

                // Five live energy nodes orbit the invitation instead of sitting still.
                ZStack {
                    ForEach(0..<5, id: \.self) { index in
                        let angle = Double(index) * (.pi * 2 / 5) - .pi / 2
                        let radius: CGFloat = 119
                        let point = CGPoint(x: center.x + CGFloat(cos(angle)) * radius,
                                            y: center.y + CGFloat(sin(angle)) * radius)
                        ZStack {
                            Circle().fill(colors[index].opacity(0.23))
                                .frame(width: 76, height: 76).blur(radius: 17)
                            Circle().stroke(colors[index].opacity(0.95), lineWidth: 2.5)
                                .frame(width: 43, height: 43)
                            Circle().fill(colors[index]).frame(width: 8, height: 8)
                                .shadow(color: colors[index], radius: 9)
                            Circle().stroke(colors[index].opacity(0.42), lineWidth: 1)
                                .frame(width: 59, height: 59)
                            Circle().trim(from: 0.08, to: 0.28)
                                .stroke(.white.opacity(0.9), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                .frame(width: 67, height: 67)
                                .rotationEffect(.degrees(orbit ? 360 : 0))
                        }
                        .scaleEffect(pulse ? 1.13 : 0.84)
                        .position(point)
                    }
                }
                .rotationEffect(.degrees(orbit ? 360 : 0))
                .shadow(color: Theme.cyan.opacity(0.08), radius: 24)

                VStack(spacing: 10) {
                    Text("BRING EVERYONE IN")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .tracking(3.2)
                        .foregroundStyle(Theme.cyan)
                        .shadow(color: Theme.cyan.opacity(titleGlow ? 0.9 : 0.25), radius: titleGlow ? 12 : 4)
                    Text("Who's\nfeeling lucky?")
                        .font(.system(size: 37, weight: .black, design: .rounded))
                        .tracking(-1.3)
                        .multilineTextAlignment(.center)
                        .lineSpacing(-2)
                        .foregroundStyle(.white)
                        .shadow(color: Theme.violet.opacity(titleGlow ? 0.25 : 0.08), radius: titleGlow ? 22 : 8)
                    Text("Place 2 or more fingers to find out")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                        .padding(.top, 2)
                }
                .position(x: center.x, y: center.y + 112 + 21 + 92)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .allowsHitTesting(false)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) { pulse = true }
            withAnimation(.linear(duration: 24).repeatForever(autoreverses: false)) { orbit = true }
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) { titleGlow = true }
        }
    }
}
