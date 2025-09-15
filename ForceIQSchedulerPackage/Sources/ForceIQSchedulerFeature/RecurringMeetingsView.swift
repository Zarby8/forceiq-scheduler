import SwiftUI

public struct RecurringMeeting: Identifiable, Codable {
    public var id = UUID()
    public var name: String
    public var selectedClients: Set<UUID>
    public var messageTemplate: String
    public var frequency: RecurrenceFrequency
    public var startDate: Date
    public var endDate: Date?
    public var lastSent: Date?
    public var isActive: Bool

    public init(name: String, selectedClients: Set<UUID> = [], messageTemplate: String = "", frequency: RecurrenceFrequency = .weekly, startDate: Date = Date(), endDate: Date? = nil) {
        self.id = UUID()
        self.name = name
        self.selectedClients = selectedClients
        self.messageTemplate = messageTemplate
        self.frequency = frequency
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = true
    }
}

public enum RecurrenceFrequency: String, CaseIterable, Codable {
    case daily = "Daily"
    case weekly = "Weekly"
    case biweekly = "Bi-weekly"
    case monthly = "Monthly"

    public var days: Int {
        switch self {
        case .daily: return 1
        case .weekly: return 7
        case .biweekly: return 14
        case .monthly: return 30
        }
    }
}

public struct RecurringMeetingsView: View {
    @ObservedObject var appModel: AppModel
    @Environment(\.presentationMode) var presentationMode
    @State private var recurringMeetings: [RecurringMeeting] = []
    @State private var showingAddMeeting = false

    // Admin check - only you and Shane can access this
    private let adminEmails = ["coachzarby@gmail.com", "shaneb@forcehockeyiq.com"]
    private var isAdmin: Bool {
        // In a real app, you'd check current user. For now, always allow for demo
        return true
    }

    public init(appModel: AppModel) {
        self.appModel = appModel
    }

    public var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [.forceBlack, .forceIceCharcoal]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            if !isAdmin {
                accessDeniedView
            } else {
                adminView
            }
        }
        .frame(minWidth: 900, minHeight: 700)
        .onAppear {
            loadRecurringMeetings()
        }
        .sheet(isPresented: $showingAddMeeting) {
            AddRecurringMeetingView(appModel: appModel, recurringMeetings: $recurringMeetings)
        }
    }

    private var accessDeniedView: some View {
        ForceIQEmptyState(
            icon: "exclamationmark.shield",
            title: "Admin Access Only",
            description: "Recurring meetings can only be configured by Christopher or Shane."
        )
    }

    private var adminView: some View {
        VStack(spacing: 24) {
            header

            if recurringMeetings.isEmpty {
                emptyStateView
            } else {
                meetingsList
            }
        }
        .padding(24)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("RECURRING MEETINGS")
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .kerning(2)
                    .foregroundColor(.forceYellow)

                Text("Admin-only automated meeting management")
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundColor(.gray)
            }

            Spacer()

            HStack(spacing: 12) {
                Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(ForceIQButtonStyle(style: .secondary))

                Button("Add Meeting") {
                    showingAddMeeting = true
                }
                .buttonStyle(ForceIQButtonStyle(style: .primary))
            }
        }
    }

    private var emptyStateView: some View {
        ForceIQEmptyState(
            icon: "calendar.badge.clock",
            title: "No Recurring Meetings",
            description: "Set up automated weekly, monthly, or custom recurring meetings for your client groups.",
            actionTitle: "Create First Meeting",
            action: { showingAddMeeting = true }
        )
    }

    private var meetingsList: some View {
        ForceIQCard {
            VStack(alignment: .leading, spacing: 16) {
                ForceIQSectionHeader("ACTIVE MEETINGS", icon: "calendar.badge.clock", color: .forceGreen)

                VStack(spacing: 12) {
                    ForEach(recurringMeetings) { meeting in
                        ForceIQRecurringMeetingRow(meeting: meeting, clients: appModel.clients) {
                            executeMeeting(meeting)
                        } onToggle: { isActive in
                            toggleMeeting(meeting, isActive: isActive)
                        } onDelete: {
                            if let index = recurringMeetings.firstIndex(where: { $0.id == meeting.id }) {
                                recurringMeetings.remove(at: index)
                                saveRecurringMeetings()
                            }
                        }
                    }
                }
            }
        }
    }

    private func loadRecurringMeetings() {
        // Load from UserDefaults or file - simplified for demo
        if let data = UserDefaults.standard.data(forKey: "RecurringMeetings"),
           let decoded = try? JSONDecoder().decode([RecurringMeeting].self, from: data) {
            recurringMeetings = decoded
        }
    }

    private func saveRecurringMeetings() {
        if let encoded = try? JSONEncoder().encode(recurringMeetings) {
            UserDefaults.standard.set(encoded, forKey: "RecurringMeetings")
        }
    }

    private func executeMeeting(_ meeting: RecurringMeeting) {
        // Select the clients for this meeting
        for i in appModel.clients.indices {
            appModel.clients[i].selected = meeting.selectedClients.contains(appModel.clients[i].id)
        }

        // Update message template
        appModel.messageTemplate = meeting.messageTemplate

        // Execute send
        appModel.sendSelected()

        // Update last sent date
        if let index = recurringMeetings.firstIndex(where: { $0.id == meeting.id }) {
            recurringMeetings[index].lastSent = Date()
            saveRecurringMeetings()
        }

        appModel.status = "✅ Executed recurring meeting: \(meeting.name)"
    }

    private func toggleMeeting(_ meeting: RecurringMeeting, isActive: Bool) {
        if let index = recurringMeetings.firstIndex(where: { $0.id == meeting.id }) {
            recurringMeetings[index].isActive = isActive
            saveRecurringMeetings()
        }
    }

    private func deleteMeetings(at offsets: IndexSet) {
        recurringMeetings.remove(atOffsets: offsets)
        saveRecurringMeetings()
    }
}

struct ForceIQRecurringMeetingRow: View {
    let meeting: RecurringMeeting
    let clients: [Client]
    let onExecute: () -> Void
    let onToggle: (Bool) -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(meeting.name.uppercased())
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)

                    if meeting.isActive {
                        ForceIQStatusBadge("Active", status: .active)
                    } else {
                        ForceIQStatusBadge("Inactive", status: .inactive)
                    }
                }

                HStack(spacing: 16) {
                    HStack {
                        Image(systemName: "repeat")
                            .foregroundColor(.forceBlue)
                        Text(meeting.frequency.rawValue)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.gray)
                    }

                    HStack {
                        Image(systemName: "person.2")
                            .foregroundColor(.forceGreen)
                        Text("\(meeting.selectedClients.count) clients")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                }

                if let lastSent = meeting.lastSent {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.forceYellow)
                        Text("Last sent \(lastSent.formatted(.relative(presentation: .numeric))) ago")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                }

                if let endDate = meeting.endDate, endDate < Date() {
                    ForceIQStatusBadge("Ended \(endDate.formatted(.dateTime.day().month()))", status: .warning)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                Toggle("", isOn: Binding(
                    get: { meeting.isActive },
                    set: { onToggle($0) }
                ))
                .toggleStyle(ForceIQToggleStyle())

                Button("Execute") {
                    onExecute()
                }
                .buttonStyle(ForceIQButtonStyle(style: meeting.isActive ? .primary : .ghost))
                .disabled(!meeting.isActive)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.forceRed)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color.forceIceCharcoal)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(meeting.isActive ? Color.forceGreen.opacity(0.5) : Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct RecurringMeetingRow: View {
    let meeting: RecurringMeeting
    let clients: [Client]
    let onExecute: () -> Void
    let onToggle: (Bool) -> Void

    var body: some View {
        ForceIQRecurringMeetingRow(meeting: meeting, clients: clients, onExecute: onExecute, onToggle: onToggle) {
            // Legacy support - no delete action
        }
    }
}