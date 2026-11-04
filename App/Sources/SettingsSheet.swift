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
        NavigationStack {
            Form {
                Section {
                    Toggle("Sound", isOn: $settings.soundEnabled)
                        .accessibilityIdentifier("soundToggle")
                    Toggle("Haptics", isOn: $settings.hapticsEnabled)
                        .accessibilityIdentifier("hapticsToggle")
                }
                Section {
                    Link("Privacy Policy", destination: PrivacyPolicy.url)
                    LabeledContent("Version", value: versionText)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("settingsDone")
                }
            }
        }
        .presentationDetents([.medium])
        .preferredColorScheme(.dark)
    }
}
