import SwiftUI

public struct ContentView: View {
    @StateObject private var model = AppModel()
    @State private var showingScheduleSettings = false
    @State private var showingContactsView = false
    @State private var showingContactsCategory = false
    @State private var showingRecurringMeetings = false
    @State private var showingSharedCalendar = false

    public init() {}

    public var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [.forceBlack, .forceIceCharcoal]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 14) {
                header
                messageTemplate
                clientList
                if !model.logs.isEmpty {
                    logsSection
                }
                footer
            }
            .padding(18)
        }
        .frame(minWidth: 900, minHeight: 640)
    }

    private var header: some View {
        HStack {
            Text("FORCEIQ SCHEDULER").font(.system(size: 22, weight: .bold, design: .monospaced))
                .kerning(2)
                .foregroundColor(.forceYellow)
            Spacer()
            Button("Schedule Settings") {
                showingScheduleSettings = true
            }
            .buttonStyle(.bordered)
            .tint(.forceYellow)
            Text(model.status)
                .foregroundColor(.gray)
                .font(.system(.footnote, design: .monospaced))
        }
        .sheet(isPresented: $showingScheduleSettings) {
            ScheduleSettingsView()
        }
        .sheet(isPresented: $showingContactsView) {
            ContactsView(clients: $model.clients)
        }
        .sheet(isPresented: $showingContactsCategory) {
            ContactsCategoryView(appModel: model)
        }
        .sheet(isPresented: $showingRecurringMeetings) {
            RecurringMeetingsView(appModel: model)
        }
        .sheet(isPresented: $showingSharedCalendar) {
            SharedCalendarView()
        }
    }

    private var messageTemplate: some View {
        VStack(alignment: .leading) {
            Text("Message Template {name} {link}").foregroundColor(.forceGreen)
            TextEditor(text: $model.messageTemplate)
                .font(.system(size: 16, design: .monospaced))
                .frame(minHeight: 110)
                .padding(8)
                .background(Color.forceCard)
                .cornerRadius(8)
        }
    }

    private var clientList: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("CLIENTS").foregroundColor(.forceYellow).font(.caption).kerning(1.5)
                Spacer()
                Menu("Contacts") {
                    Button("Organize Categories") { showingContactsCategory = true }
                    Button("Advanced Import") { showingContactsView = true }
                }
                .buttonStyle(.bordered)
                .tint(.forceBlue)
                Button("Import JSON") { importJSONFile() }
                    .buttonStyle(.bordered)
                    .tint(.forceGreen)
                Button("Export JSON") { exportJSONFile() }
                    .buttonStyle(.bordered)
                    .tint(.forceYellow)
                Button("Export CSV") { exportCSVFile() }
                    .buttonStyle(.bordered)
                    .tint(.forceYellow)
                Button("Add") { model.clients.append(Client(name: "New Client", handle: "", email: "")) }
                Button("Save List") { model.save() }
            }
            List {
                ForEach($model.clients) { $c in
                    HStack {
                        Toggle("", isOn: $c.selected).toggleStyle(.checkbox)

                        // Status indicator
                        statusIndicator(for: c)
                            .frame(width: 20)

                        TextField("Name", text: $c.name)
                            .textFieldStyle(.roundedBorder)
                            .frame(minWidth: 120)
                        TextField("Handle (phone/email)", text: $c.handle)
                            .textFieldStyle(.roundedBorder)
                            .frame(minWidth: 140)
                        TextField("Email", text: $c.email)
                            .textFieldStyle(.roundedBorder)
                            .frame(minWidth: 140)
                        VStack(spacing: 4) {
                            Toggle("Active", isOn: $c.active)
                                .font(.caption2)
                            Toggle("DND", isOn: $c.doNotDisturb)
                                .font(.caption2)
                        }
                        .frame(width: 60)
                        TextField("Notes", text: $c.notes)
                            .textFieldStyle(.roundedBorder)
                    }
                    .listRowBackground(Color.forceCard)
                }
                .onDelete { idx in model.clients.remove(atOffsets: idx) }
            }
            .background(Color.forceIceCharcoal)
            .scrollContentBackground(.hidden)
        }
    }

    private var footer: some View {
        HStack {
            Button(action: model.sendSelected) {
                HStack {
                    if model.sending { ProgressView() }
                    Text("Send to Selected").bold()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.forceGreen)
            
            Button("Preview First Selected") {
                if let c = model.clients.first(where: { $0.selected }) {
                    let msg = model.resolvedMessage(for: c, link: model.buildSignedLink(for: c))
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(msg, forType: .string)
                    model.status = "Preview copied for \(c.name)."
                } else {
                    model.status = "Select at least one client."
                }
            }
            .tint(.forceYellow)
            .buttonStyle(.bordered)

            Button("Recurring Meetings") {
                showingRecurringMeetings = true
            }
            .buttonStyle(.bordered)
            .tint(.forceYellow)

            Button("Team Calendar") {
                showingSharedCalendar = true
            }
            .buttonStyle(.bordered)
            .tint(.forceBlue)

            Spacer()
            Text("Electric analytics. Precision scheduling.")
                .foregroundColor(.gray)
                .font(.footnote)
        }
    }

    private var logsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("ACTIVITY LOG").foregroundColor(.forceYellow).font(.caption).kerning(1.5)
                Spacer()
                Button("Clear Logs") { model.logs.removeAll() }
                    .buttonStyle(.bordered)
                    .tint(.forceRed)
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(model.logs.indices.reversed(), id: \.self) { index in
                        Text(model.logs[index])
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.gray)
                            .textSelection(.enabled)
                    }
                }
            }
            .frame(maxHeight: 120)
            .padding(8)
            .background(Color.forceCard)
            .cornerRadius(8)
        }
    }

    @ViewBuilder
    private func statusIndicator(for client: Client) -> some View {
        if let result = model.sendResults[client.id.uuidString] {
            if result.success {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.forceGreen)
                    .help("Message sent successfully")
            } else {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.forceRed)
                    .help(result.error ?? "Send failed")
            }
        } else {
            // No status yet
            EmptyView()
        }
    }

    private func importJSONFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        if panel.runModal() == .OK, let url = panel.url {
            do {
                let data = try Data(contentsOf: url)
                _ = model.importClients(from: data)
            } catch {
                model.status = "Failed to read file: \(error.localizedDescription)"
            }
        }
    }

    private func exportJSONFile() {
        guard let data = model.exportClients() else {
            model.status = "Failed to export clients."
            return
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "ForceIQ_Clients.json"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                try data.write(to: url)
                model.status = "Exported \(model.clients.count) clients to JSON."
            } catch {
                model.status = "Failed to save file: \(error.localizedDescription)"
            }
        }
    }

    private func exportCSVFile() {
        let csv = model.exportClientsAsCSV()
        let data = csv.data(using: .utf8)!

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "ForceIQ_Clients.csv"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                try data.write(to: url)
                model.status = "Exported \(model.clients.count) clients to CSV."
            } catch {
                model.status = "Failed to save file: \(error.localizedDescription)"
            }
        }
    }

    private func extractCategory(from notes: String) -> String? {
        if notes.contains("Category: ") {
            let components = notes.components(separatedBy: "Category: ")
            if components.count > 1 {
                let category = components[1].components(separatedBy: "\n")[0].trimmingCharacters(in: .whitespaces)
                return category == "Unassigned" ? nil : category
            }
        }
        return nil
    }

    private func categoryColor(_ category: String) -> Color {
        switch category {
        case "YOUTH": return .blue
        case "JUNIOR": return .green
        case "COLLEGE": return .orange
        case "PRO": return .purple
        default: return .gray
        }
    }
}

