import SwiftUI

public struct SettingsView: View {
    @StateObject private var config = AppConfig()

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            headerSection
            configSection
            secretSection
            buttonSection
            Spacer()
        }
        .padding(24)
        .frame(minWidth: 500, minHeight: 400)
        .background(
            LinearGradient(gradient: Gradient(colors: [.forceBlack, .forceIceCharcoal]), startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FORCEIQ SETTINGS")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.forceYellow)
                .kerning(1.5)

            Text("Configure your booking system URLs and security")
                .foregroundColor(.gray)
                .font(.caption)
        }
    }

    private var configSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("URLs")
                .foregroundColor(.forceGreen)
                .font(.caption)
                .kerning(1)

            VStack(alignment: .leading, spacing: 8) {
                Text("Booking Page URL")
                    .foregroundColor(.gray)
                    .font(.caption2)
                TextField("https://schedule.forcehockeyiq.com", text: $config.webBase)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Google Apps Script URL")
                    .foregroundColor(.gray)
                    .font(.caption2)
                TextField("https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec", text: $config.gasBase)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var secretSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SECURITY")
                .foregroundColor(.forceYellow)
                .font(.caption)
                .kerning(1)

            VStack(alignment: .leading, spacing: 8) {
                Text("HMAC Secret (auto-generated, stored in Keychain)")
                    .foregroundColor(.gray)
                    .font(.caption2)

                HStack {
                    SecureField("HMAC Secret", text: $config.hmacSecret)
                        .textFieldStyle(.roundedBorder)
                        .disabled(true)

                    Button("Generate New") {
                        config.hmacSecret = generateRandomSecret()
                    }
                    .buttonStyle(.bordered)
                    .tint(.forceRed)
                }

                Text("⚠️ Changing this will invalidate all existing booking links")
                    .foregroundColor(.forceRed)
                    .font(.caption2)
            }
        }
    }

    private var buttonSection: some View {
        HStack(spacing: 12) {
            Button("Save Settings") {
                config.saveSettings()
            }
            .buttonStyle(.borderedProminent)
            .tint(.forceGreen)

            Button("Reset to Defaults") {
                config.webBase = "https://schedule.forcehockeyiq.com"
                config.gasBase = "https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec"
            }
            .buttonStyle(.bordered)
            .tint(.forceYellow)

            Spacer()
        }
    }

    private func generateRandomSecret() -> String {
        let length = 32
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in chars.randomElement()! })
    }
}