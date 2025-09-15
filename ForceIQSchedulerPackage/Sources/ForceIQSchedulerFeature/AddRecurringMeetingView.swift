import SwiftUI

public struct AddRecurringMeetingView: View {
    @ObservedObject var appModel: AppModel
    @Binding var recurringMeetings: [RecurringMeeting]
    @Environment(\.presentationMode) var presentationMode

    @State private var name = ""
    @State private var selectedClients: Set<UUID> = []
    @State private var messageTemplate = "Hi {name}! Here's my ForceIQ scheduling link: {link}\n\nPlease pick a slot and answer the game questions."
    @State private var frequency: RecurrenceFrequency = .weekly
    @State private var startDate = Date()
    @State private var hasEndDate = false
    @State private var endDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()

    public init(appModel: AppModel, recurringMeetings: Binding<[RecurringMeeting]>) {
        self.appModel = appModel
        self._recurringMeetings = recurringMeetings
    }

    public var body: some View {
        NavigationView {
            Form {
                Section("Meeting Details") {
                    HStack {
                        Text("Name")
                        TextField("Weekly YOUTH check-ins", text: $name)
                    }

                    HStack {
                        Text("Frequency")
                        Spacer()
                        Picker("", selection: $frequency) {
                            ForEach(RecurrenceFrequency.allCases, id: \.self) { freq in
                                Text(freq.rawValue).tag(freq)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)

                    Toggle("Set End Date", isOn: $hasEndDate)

                    if hasEndDate {
                        DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                            .disabled(!hasEndDate)
                    }
                }

                Section("Client Selection") {
                    HStack {
                        Text("Select Clients (\(selectedClients.count) selected)")
                        Spacer()
                        Button("Select All") {
                            selectedClients = Set(appModel.clients.map(\.id))
                        }
                        Button("Clear All") {
                            selectedClients.removeAll()
                        }
                    }

                    ForEach(appModel.clients) { client in
                        HStack {
                            Toggle("", isOn: Binding(
                                get: { selectedClients.contains(client.id) },
                                set: { if $0 { selectedClients.insert(client.id) } else { selectedClients.remove(client.id) } }
                            ))
                            .toggleStyle(.checkbox)

                            VStack(alignment: .leading) {
                                Text(client.name)
                                    .fontWeight(.medium)
                                Text(client.handle)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            if !client.active {
                                Text("Inactive")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(4)
                            }

                            if client.doNotDisturb {
                                Text("DND")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.red.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                        .opacity(client.active && !client.doNotDisturb ? 1.0 : 0.6)
                    }
                }

                Section("Message Template") {
                    VStack(alignment: .leading) {
                        Text("Available variables: {name}, {link}")
                            .font(.caption)
                            .foregroundColor(.gray)

                        TextEditor(text: $messageTemplate)
                            .font(.system(size: 16, design: .monospaced))
                            .frame(minHeight: 100)
                    }
                }

                Section("Schedule Preview") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("This meeting will run:")
                            .font(.headline)

                        HStack {
                            Image(systemName: "calendar")
                            Text("Every \(frequency.rawValue.lowercased())")
                        }

                        HStack {
                            Image(systemName: "play.circle")
                            Text("Starting \(startDate, style: .date)")
                        }

                        if hasEndDate {
                            HStack {
                                Image(systemName: "stop.circle")
                                Text("Ending \(endDate, style: .date)")
                            }
                        }

                        HStack {
                            Image(systemName: "person.3")
                            Text("\(selectedClients.count) clients selected")
                        }

                        let nextDates = generateNextDates()
                        if !nextDates.isEmpty {
                            Text("Next 3 sends:")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, 4)

                            ForEach(nextDates.prefix(3), id: \.self) { date in
                                HStack {
                                    Image(systemName: "clock")
                                        .font(.caption)
                                    Text(date, style: .date)
                                        .font(.caption)
                                }
                                .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Recurring Meeting")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createMeeting()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(name.isEmpty || selectedClients.isEmpty)
                }
            }
        }
        .frame(minWidth: 600, minHeight: 700)
    }

    private func generateNextDates() -> [Date] {
        var dates: [Date] = []
        var currentDate = startDate

        for _ in 0..<5 {
            if let futureEndDate = hasEndDate ? endDate : nil,
               currentDate > futureEndDate {
                break
            }
            dates.append(currentDate)
            currentDate = Calendar.current.date(byAdding: .day, value: frequency.days, to: currentDate) ?? currentDate
        }

        return dates.filter { $0 >= Date() }
    }

    private func createMeeting() {
        let meeting = RecurringMeeting(
            name: name,
            selectedClients: selectedClients,
            messageTemplate: messageTemplate,
            frequency: frequency,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil
        )

        recurringMeetings.append(meeting)
        saveRecurringMeetings()
    }

    private func saveRecurringMeetings() {
        if let encoded = try? JSONEncoder().encode(recurringMeetings) {
            UserDefaults.standard.set(encoded, forKey: "RecurringMeetings")
        }
    }
}