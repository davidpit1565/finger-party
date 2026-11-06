import SwiftUI

/// Atmospheric background and idle invitation. Decorative layers never participate in hit testing.
struct AmbientBackdrop: View {
    let reduceMotion: Bool
    @State private var drift = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Theme.background
                Circle()
                    .fill(RadialGradient(colors: [Theme.violet.opacity(0.22), .clear], center: .center, startRadius: 8, endRadius: 240))
                    .frame(width: 480, height: 480)
                    .offset(x: drift ? -125 : 115, y: drift ? -250 : -90)
                Circle()
                    .fill(RadialGradient(colors: [Theme.cyan.opacity(0.16), .clear], center: .center, startRadius: 4, endRadius: 220))
                    .frame(width: 440, height: 440)
                    .offset(x: drift ? 145 : -120, y: drift ? 230 : 90)
                LinearGradient(colors: [.white.opacity(0.035), .clear, .black.opacity(0.12)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                Rectangle().fill(.white.opacity(0.018))
                    .overlay(alignment: .top) {
                        LinearGradient(colors: [.white.opacity(0.06), .clear], startPoint: .top, endPoint: .bottom)
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
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) { drift = true }
        }
    }
}

struct IdleWelcome: View {
    let reduceMotion: Bool
    @State private var pulse = false

    private let colors: [Color] = [Theme.cyan, Theme.coral, Theme.violet, Theme.lime, Color.orange]

    var body: some View {
        GeometryReader { geo in
            // Ring cluster sits above the copy block so nodes never overlap the text.
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height * 0.35)
            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(.white.opacity(0.055), lineWidth: 1)
                        .frame(width: CGFloat(190 + index * 74), height: CGFloat(190 + index * 74))
                        .position(center)
                }

                ForEach(0..<5, id: \.self) { index in
                    let angle = Double(index) * (.pi * 2 / 5) - .pi / 2
                    let radius: CGFloat = 112
                    let point = CGPoint(x: center.x + CGFloat(cos(angle)) * radius,
                                        y: center.y + CGFloat(sin(angle)) * radius)
                    ZStack {
                        Circle().fill(colors[index].opacity(0.16)).frame(width: 66, height: 66).blur(radius: 13)
                        Circle().stroke(colors[index].opacity(0.9), lineWidth: 3)
                            .frame(width: 42, height: 42)
                        Circle().fill(colors[index]).frame(width: 7, height: 7)
                        Circle().stroke(colors[index].opacity(0.28), lineWidth: 1)
                            .frame(width: 54, height: 54)
                    }
                    .scaleEffect(pulse ? 1.13 : 0.88)
                    .position(point)
                }

                VStack(spacing: 10) {
                    Text("BRING EVERYONE IN")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .tracking(3.2)
                        .foregroundStyle(Theme.cyan)
                    Text("Who's\nfeeling lucky?")
                        .font(.system(size: 37, weight: .black, design: .rounded))
                        .tracking(-1.3)
                        .multilineTextAlignment(.center)
                        .lineSpacing(-2)
                        .foregroundStyle(.white)
                    Text("Place 2 or more fingers to find out")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.68))
                        .padding(.top, 2)
                }
                .position(x: center.x, y: center.y + 112 + 21 + 92)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .allowsHitTesting(false)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.1).repeatForever(autoreverses: true)) { pulse = true }
        }
    }
}
