import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appModel: AppModel

    @State private var sundayEnabled: Bool = false
    @State private var sendTime: Date = Date()
    @State private var messageTemplate: String = ""
    @State private var bookingPageUrl: String = ""
    @State private var showingTestMessage = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                ForceIQSectionHeader(title: "Configuration")

                // Sunday Auto-Send
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("SUNDAY AUTO-SEND")
                            .font(.system(size: 12, weight: .black, design: .default))
                            .tracking(2)
                            .foregroundColor(ForceIQColors.highlightYellow)

                        Spacer()

                        Toggle("", isOn: $sundayEnabled)
                            .labelsHidden()
                            .tint(ForceIQColors.electricGreen)
                            .onChange(of: sundayEnabled) { _, newValue in
                                appModel.toggleSundayScheduler(newValue)
                            }
                    }

                    if sundayEnabled {
                        // Send Time
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SEND TIME")
                                .font(.system(size: 11, weight: .bold, design: .default))
                                .tracking(1.5)
                                .foregroundColor(ForceIQColors.textMuted)

                            DatePicker("", selection: $sendTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .colorMultiply(ForceIQColors.highlightYellow)
                                .onChange(of: sendTime) { _, newValue in
                                    var config = appModel.config.sundayConfig
                                    config.sendTime = newValue
                                    appModel.updateSundayConfig(config)
                                }
                        }

                        // Message Template
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("MESSAGE TEMPLATE")
                                    .font(.system(size: 11, weight: .bold, design: .default))
                                    .tracking(1.5)
                                    .foregroundColor(ForceIQColors.textMuted)

                                Spacer()

                                Text("Use {name} and {link}")
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundColor(ForceIQColors.textMuted.opacity(0.7))
                            }

                            TextEditor(text: $messageTemplate)
                                .font(.system(size: 13, weight: .regular, design: .monospaced))
                                .foregroundColor(ForceIQColors.textPrimary)
                                .frame(height: 120)
                                .padding(12)
                                .background(ForceIQColors.iceCharcoalDark)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(ForceIQColors.forceRed.opacity(0.3), lineWidth: 1)
                                )
                                .onChange(of: messageTemplate) { _, newValue in
                                    var config = appModel.config.sundayConfig
                                    config.messageTemplate = newValue
                                    appModel.updateSundayConfig(config)
                                }
                        }

                        // Test Message
                        Button(action: { showingTestMessage = true }) {
                            Label("Test iMessage Connection", systemImage: "message.badge.waveform.fill")
                        }
                        .buttonStyle(ForceIQButtonStyle(type: .secondary))
                    }
                }
                .padding(20)
                .forceIQCard(level: 1)

                // Booking Page URL
                VStack(alignment: .leading, spacing: 16) {
                    Text("BOOKING PAGE")
                        .font(.system(size: 12, weight: .black, design: .default))
                        .tracking(2)
                        .foregroundColor(ForceIQColors.highlightYellow)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("URL")
                            .font(.system(size: 11, weight: .bold, design: .default))
                            .tracking(1.5)
                            .foregroundColor(ForceIQColors.textMuted)

                        TextField("https://schedule.forcehockeyiq.com", text: $bookingPageUrl)
                            .textFieldStyle(ForceIQTextFieldStyle())
                            .onChange(of: bookingPageUrl) { _, newValue in
                                var config = appModel.config
                                config.bookingPageUrl = newValue
                                appModel.updateConfig(config)
                            }
                    }

                    Button(action: {
                        NSWorkspace.shared.open(URL(string: bookingPageUrl)!)
                    }) {
                        Label("Open Booking Page", systemImage: "safari")
                    }
                    .buttonStyle(ForceIQButtonStyle(type: .secondary))
                    .disabled(bookingPageUrl.isEmpty)
                }
                .padding(20)
                .forceIQCard(level: 1)

                // Coach Configuration
                VStack(alignment: .leading, spacing: 16) {
                    Text("COACHES")
                        .font(.system(size: 12, weight: .black, design: .default))
                        .tracking(2)
                        .foregroundColor(ForceIQColors.highlightYellow)

                    ForEach(appModel.config.coaches) { coach in
                        CoachConfigCard(coach: coach)
                    }
                }
                .padding(20)
                .forceIQCard(level: 1)

                // Data Management
                VStack(alignment: .leading, spacing: 16) {
                    Text("DATA MANAGEMENT")
                        .font(.system(size: 12, weight: .black, design: .default))
                        .tracking(2)
                        .foregroundColor(ForceIQColors.highlightYellow)

                    HStack(spacing: 12) {
                        Button(action: exportClients) {
                            Label("Export Clients", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(ForceIQButtonStyle(type: .secondary))

                        Button(action: importClients) {
                            Label("Import Clients", systemImage: "square.and.arrow.down")
                        }
                        .buttonStyle(ForceIQButtonStyle(type: .secondary))
                    }
                }
                .padding(20)
                .forceIQCard(level: 1)
            }
            .padding(24)
        }
        .background(ForceIQColors.black)
        .onAppear {
            loadSettings()
        }
        .alert("Test iMessage", isPresented: $showingTestMessage) {
            Button("Cancel", role: .cancel) {}
            Button("Send Test") {
                sendTestMessage()
            }
        } message: {
            Text("This will send a test message to your own phone number to verify iMessage works.")
        }
    }

    private func loadSettings() {
        sundayEnabled = appModel.config.sundayConfig.enabled
        sendTime = appModel.config.sundayConfig.sendTime
        messageTemplate = appModel.config.sundayConfig.messageTemplate
        bookingPageUrl = appModel.config.bookingPageUrl
    }

    private func sendTestMessage() {
        let testMessage = "🏒 ForceIQ Test Message\n\nIf you received this, iMessage integration is working!"
        let success = appModel.iMessageService.sendMessage(testMessage, to: appModel.config.coaches[0].email)

        if success {
            print("✅ Test message sent")
        } else {
            print("❌ Test message failed")
        }
    }

    private func exportClients() {
        do {
            let url = try appModel.exportClients()
            NSWorkspace.shared.activateFileViewerSelecting([url])
        } catch {
            print("❌ Export failed: \(error)")
        }
    }

    private func importClients() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.json]

        if panel.runModal() == .OK, let url = panel.url {
            do {
                try appModel.importClients(from: url)
                print("✅ Imported clients")
            } catch {
                print("❌ Import failed: \(error)")
            }
        }
    }
}

// MARK: - Coach Config Card

struct CoachConfigCard: View {
    @EnvironmentObject var appModel: AppModel
    let coach: Coach

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            Circle()
                .fill(Color(hex: coach.color))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(coach.name.prefix(1)).uppercased())
                        .font(.system(size: 16, weight: .black, design: .default))
                        .foregroundColor(ForceIQColors.black)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(coach.name)
                    .font(.system(size: 14, weight: .bold, design: .default))
                    .foregroundColor(ForceIQColors.textPrimary)

                Text(coach.email)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(ForceIQColors.textSecondary)

                if !coach.calendarId.isEmpty {
                    Text("CALENDAR: \(coach.calendarId)")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(ForceIQColors.electricGreen)
                } else {
                    Text("NO CALENDAR CONNECTED")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(ForceIQColors.forceRed)
                }
            }

            Spacer()

            Button(action: {
                Task {
                    try? await appModel.googleAuth.signIn(for: coach.id)
                }
            }) {
                Label("Connect", systemImage: "link")
            }
            .buttonStyle(ForceIQButtonStyle(type: .secondary))
        }
        .padding(16)
        .background(ForceIQColors.iceCharcoalDark)
        .cornerRadius(6)
    }
}
