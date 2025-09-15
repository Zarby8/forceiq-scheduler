import SwiftUI

public struct ScheduleSettingsView: View {
    @StateObject private var scheduleModel = ScheduleModel()
    @StateObject private var oauthManager = GoogleOAuthManager()
    @Environment(\.presentationMode) var presentationMode
    @State private var gasScriptURL = ""

    public init() {}

    public var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [.forceBlack, .forceIceCharcoal]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    header
                    googleAccountSection
                    scheduleSection
                    sessionSettingsSection
                    recurringTemplatesSection
                    exportSection
                }
                .padding(24)
            }
        }
        .frame(minWidth: 900, minHeight: 700)
        .onAppear {
            scheduleModel.load()
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("SCHEDULE SETTINGS")
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .kerning(2)
                    .foregroundColor(.forceYellow)

                Text("Configure your availability and Google integration")
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundColor(.gray)
            }

            Spacer()

            HStack(spacing: 12) {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(ForceIQButtonStyle(style: .secondary))

                Button("Save Settings") {
                    scheduleModel.save()
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(ForceIQButtonStyle(style: .primary))
            }
        }
    }

    private var googleAccountSection: some View {
        ForceIQCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "globe")
                        .font(.title2)
                        .foregroundColor(.forceBlue)

                    Text("GOOGLE INTEGRATION")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.forceYellow)

                    Spacer()
                }

                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        if oauthManager.isAuthenticated {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.forceGreen)
                                Text("Signed in as \(oauthManager.userEmail)")
                                    .font(.system(size: 16, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                        } else {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.forceRed)
                                Text("Not authenticated")
                                    .font(.system(size: 16, design: .monospaced))
                                    .foregroundColor(.gray)
                            }
                        }
                    }

                    Spacer()

                    if oauthManager.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else if oauthManager.isAuthenticated {
                        Button("Sign Out") {
                            oauthManager.signOut()
                        }
                        .buttonStyle(ForceIQButtonStyle(style: .destructive))
                    } else {
                        Button("Authenticate with Google") {
                            oauthManager.signIn()
                        }
                        .buttonStyle(ForceIQButtonStyle(style: .primary))
                    }
                }

                if !oauthManager.errorMessage.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.forceRed)
                        Text(oauthManager.errorMessage)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.forceRed)
                    }
                    .padding(.top, 8)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Google Apps Script URL")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(.forceGreen)

                    TextField("https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec", text: $gasScriptURL)
                        .textFieldStyle(ForceIQTextFieldStyle())

                    Text("Enter your deployed Google Apps Script URL for calendar integration")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.gray)
                }
            }
        }
    }

    private var scheduleSection: some View {
        ForceIQCard {
            VStack(alignment: .leading, spacing: 16) {
                ForceIQSectionHeader("WEEKLY AVAILABILITY", icon: "calendar", color: .forceGreen)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(DayOfWeek.allCases, id: \.self) { day in
                        ForceIQDayScheduleCard(
                            day: day,
                            timeSlots: Binding(
                                get: { scheduleModel.schedule[day] ?? [] },
                                set: { scheduleModel.schedule[day] = $0 }
                            )
                        )
                    }
                }
            }
        }
    }

    private var sessionSettingsSection: some View {
        ForceIQCard {
            VStack(alignment: .leading, spacing: 16) {
                ForceIQSectionHeader("SESSION SETTINGS", icon: "clock", color: .forceBlue)

                VStack(spacing: 12) {
                    ForceIQPicker("Session Length", selection: $scheduleModel.sessionLength) {
                        Text("30 min").tag(30)
                        Text("45 min").tag(45)
                        Text("60 min").tag(60)
                        Text("90 min").tag(90)
                    }

                    ForceIQPicker("Buffer Time", selection: $scheduleModel.bufferMinutes) {
                        Text("0 min").tag(0)
                        Text("15 min").tag(15)
                        Text("30 min").tag(30)
                    }
                }
            }
        }
    }

    private var recurringTemplatesSection: some View {
        ForceIQCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    ForceIQSectionHeader("RECURRING TEMPLATES", icon: "repeat", color: .forceYellow)
                    Spacer()
                    Button("Add Template") {
                        scheduleModel.addTemplate()
                    }
                    .buttonStyle(ForceIQButtonStyle(style: .ghost))
                }

                if scheduleModel.recurringTemplates.isEmpty {
                    ForceIQEmptyState(
                        icon: "repeat",
                        title: "No Templates",
                        description: "Create recurring schedule templates for easy setup",
                        actionTitle: "Add First Template",
                        action: { scheduleModel.addTemplate() }
                    )
                } else {
                    VStack(spacing: 8) {
                        ForEach(scheduleModel.recurringTemplates, id: \.id) { template in
                            ForceIQTemplateRow(template: template) {
                                scheduleModel.applyTemplate(template)
                            }
                        }
                    }
                }
            }
        }
    }

    private var exportSection: some View {
        ForceIQCard {
            VStack(alignment: .leading, spacing: 16) {
                ForceIQSectionHeader("EXPORT CONFIGURATION", icon: "square.and.arrow.up", color: .forceRed)

                Button("Generate Apps Script Config") {
                    exportSchedule()
                }
                .buttonStyle(ForceIQButtonStyle(style: .primary))

                if !scheduleModel.exportedCode.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Copy this to your Google Apps Script CONFIG:")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(.forceYellow)

                        ScrollView(.horizontal, showsIndicators: false) {
                            Text(scheduleModel.exportedCode)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.forceGreen)
                                .padding()
                                .background(Color.forceIceCharcoal)
                                .cornerRadius(8)
                                .textSelection(.enabled)
                        }
                        .frame(height: 150)
                    }
                }
            }
        }
    }

    private func exportSchedule() {
        scheduleModel.generateAppsScriptConfig()
    }
}

// MARK: - Supporting Views

struct ForceIQDayScheduleCard: View {
    let day: DayOfWeek
    @Binding var timeSlots: [TimeSlot]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(day.displayName.uppercased())
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.forceYellow)

                Spacer()

                Button(action: addTimeSlot) {
                    Image(systemName: "plus")
                        .foregroundColor(.forceGreen)
                }
                .buttonStyle(.plain)
            }

            if timeSlots.isEmpty {
                Text("No availability")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(timeSlots.indices, id: \.self) { index in
                        ForceIQTimeSlotView(
                            startTime: timeSlots[index].start,
                            endTime: timeSlots[index].end,
                            isActive: true,
                            onToggle: { },
                            onRemove: { removeTimeSlot(at: index) }
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(Color.forceIceCharcoal)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.forceYellow.opacity(0.3), lineWidth: 1)
        )
    }

    private func addTimeSlot() {
        let newSlot = TimeSlot(start: "17:00", end: "20:00")
        timeSlots.append(newSlot)
    }

    private func removeTimeSlot(at index: Int) {
        timeSlots.remove(at: index)
    }
}

struct ForceIQTemplateRow: View {
    let template: RecurringTemplate
    let onApply: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name.uppercased())
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)

                Text(template.description)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.gray)
            }

            Spacer()

            Button("Apply") {
                onApply()
            }
            .buttonStyle(ForceIQButtonStyle(style: .ghost))
        }
        .padding(12)
        .background(Color.forceIceCharcoal)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.forceYellow.opacity(0.2), lineWidth: 1)
        )
    }
}

struct DayScheduleRow: View {
    let day: DayOfWeek
    @Binding var timeSlots: [TimeSlot]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(day.displayName)
                    .font(.headline)
                Spacer()
                Button("Add Slot") {
                    timeSlots.append(TimeSlot(start: "09:00", end: "17:00"))
                }
                .buttonStyle(.borderless)
            }

            ForEach(timeSlots.indices, id: \.self) { index in
                HStack {
                    TextField("Start", text: $timeSlots[index].start)
                        .frame(width: 60)
                    Text("to")
                    TextField("End", text: $timeSlots[index].end)
                        .frame(width: 60)
                    Spacer()
                    Button("Remove") {
                        timeSlots.remove(at: index)
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.red)
                }
            }

            if timeSlots.isEmpty {
                Text("No availability")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

struct RecurringTemplateRow: View {
    let template: RecurringTemplate
    let onApply: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(template.name)
                    .font(.headline)
                Text(template.description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            Button("Apply") {
                onApply()
            }
        }
    }
}