import SwiftUI

enum PrivacyPolicy {
    static let url = URL(string: "https://davidpit1565.github.io/finger-party/privacy.html")!
}

struct SettingsSheet: View {
    @Bindable var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss

    private var versionText: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            GeometryReader { geo in
                Circle()
                    .fill(Theme.violet.opacity(0.16))
                    .frame(width: 300, height: 300)
                    .blur(radius: 75)
                    .offset(x: geo.size.width - 190, y: -130)
                Circle()
                    .fill(Theme.cyan.opacity(0.10))
                    .frame(width: 250, height: 250)
                    .blur(radius: 70)
                    .offset(x: -130, y: geo.size.height * 0.48)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Capsule()
                    .fill(.white.opacity(0.22))
                    .frame(width: 38, height: 5)
                    .padding(.top, 12)

                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("YOUR EXPERIENCE")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .tracking(2.4)
                            .foregroundStyle(Theme.cyan)
                        Text("Settings")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white.opacity(0.85))
                            .frame(width: 38, height: 38)
                            .background(.white.opacity(0.09), in: Circle())
                            .overlay(Circle().stroke(.white.opacity(0.12), lineWidth: 1))
                    }
                    .accessibilityLabel("Close settings")
                    .accessibilityIdentifier("settingsDone")
                }
                .padding(.horizontal, 24)
                .padding(.top, 25)
                .padding(.bottom, 24)

                VStack(spacing: 0) {
                    settingRow(
                        icon: "waveform",
                        tint: Theme.cyan,
                        title: "Sound",
                        subtitle: "Audio cues during the pick",
                        isOn: $settings.soundEnabled,
                        identifier: "soundToggle"
                    )
                    Rectangle().fill(.white.opacity(0.08)).frame(height: 1).padding(.leading, 68)
                    settingRow(
                        icon: "waveform.path",
                        tint: Theme.violet,
                        title: "Haptics",
                        subtitle: "Feel every selection",
                        isOn: $settings.hapticsEnabled,
                        identifier: "hapticsToggle"
                    )
                    Rectangle().fill(.white.opacity(0.08)).frame(height: 1).padding(.leading, 68)
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            Image(systemName: "paintpalette.fill")
                                .foregroundStyle(Theme.lime)
                            Text("Color mood")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        Picker("Color mood", selection: $settings.colorMood) {
                            ForEach(ColorMood.allCases, id: \.self) { mood in
                                Text(mood.rawValue).tag(mood)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityIdentifier("colorMoodPicker")
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 13)
                }
                .padding(.horizontal, 16)
                .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.09), lineWidth: 1))
                .padding(.horizontal, 20)

                Spacer(minLength: 20)

                HStack {
                    Link(destination: PrivacyPolicy.url) {
                        HStack(spacing: 7) {
                            Image(systemName: "hand.raised")
                            Text("Privacy")
                        }
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.65))
                    }
                    Spacer()
                    Text("VERSION  \(versionText)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.38))
                }
                .padding(.horizontal, 26)
                .padding(.bottom, 28)
            }
        }
        .presentationDetents([.height(430)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(30)
        .preferredColorScheme(.dark)
    }

    private func settingRow(
        icon: String,
        tint: Color,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>,
        identifier: String
    ) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(tint.opacity(0.14))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(tint)
                }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.48))
            }
            Spacer()
            Toggle(title, isOn: isOn)
                .labelsHidden()
                .tint(Theme.cyan)
                .accessibilityIdentifier(identifier)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
    }
}
