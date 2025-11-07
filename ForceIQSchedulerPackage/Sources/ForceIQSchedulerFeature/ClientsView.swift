import SwiftUI
import Contacts

struct ClientsView: View {
    @EnvironmentObject var appModel: AppModel
    @State private var searchText = ""
    @State private var showingAddClient = false
    @State private var showingContactsPicker = false
    @State private var selectedClient: Client?
    @State private var importStatus = ""

    var filteredClients: [Client] {
        if searchText.isEmpty {
            return appModel.clients
        }
        return appModel.clients.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.email.localizedCaseInsensitiveContains(searchText) ||
            $0.phone.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                ForceIQSectionHeader(title: "Client Management")
                Spacer()

                Text("\(appModel.clients.count) CLIENTS")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(ForceIQColors.textMuted)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(ForceIQColors.iceCharcoalDark)
                    .cornerRadius(4)

                Button(action: { showingContactsPicker = true }) {
                    Label("Import Contacts", systemImage: "person.crop.circle.badge.plus")
                }
                .buttonStyle(ForceIQButtonStyle(type: .secondary))

                Button(action: { showingAddClient = true }) {
                    Label("Add Client", systemImage: "plus")
                }
                .buttonStyle(ForceIQButtonStyle(type: .primary))
            }
            .padding(24)

            Divider()
                .background(ForceIQColors.forceRed.opacity(0.3))

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(ForceIQColors.textMuted)

                TextField("Search clients...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .foregroundColor(ForceIQColors.textPrimary)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(ForceIQColors.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(ForceIQColors.iceCharcoalDark)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(ForceIQColors.forceRed.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 24)
            .padding(.vertical, 12)

            // Client List
            if filteredClients.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: searchText.isEmpty ? "person.3.fill" : "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(ForceIQColors.textMuted)

                    Text(searchText.isEmpty ? "NO CLIENTS YET" : "NO RESULTS")
                        .font(.system(size: 14, weight: .bold, design: .default))
                        .tracking(1.5)
                        .foregroundColor(ForceIQColors.textMuted)

                    if searchText.isEmpty {
                        Button("Add Your First Client") {
                            showingAddClient = true
                        }
                        .buttonStyle(ForceIQButtonStyle(type: .secondary))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredClients) { client in
                            ClientCard(client: client) {
                                selectedClient = client
                            }
                        }
                    }
                    .padding(24)
                }
            }
        }
        .background(ForceIQColors.black)
        .sheet(isPresented: $showingAddClient) {
            ClientFormView(mode: .add)
        }
        .sheet(item: $selectedClient) { client in
            ClientFormView(mode: .edit(client))
        }
        .sheet(isPresented: $showingContactsPicker) {
            ContactsPickerView(onImport: importContacts)
        }
    }

    private func importContacts(_ contacts: [CNContact]) {
        for contact in contacts {
            // Get primary phone number
            let phoneNumber = contact.phoneNumbers.first?.value.stringValue ?? ""

            // Skip if already exists by phone or email
            let existsByPhone = appModel.clients.contains { $0.phone == phoneNumber }
            let existsByEmail = appModel.clients.contains { client in
                contact.emailAddresses.contains { $0.value as String == client.email }
            }

            if existsByPhone || existsByEmail {
                continue
            }

            let client = Client(
                name: "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces),
                email: contact.emailAddresses.first?.value as? String ?? "",
                phone: phoneNumber
            )

            appModel.addClient(client)
        }

        importStatus = "✅ Imported \(contacts.count) contacts"
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            importStatus = ""
        }
    }
}

// MARK: - Client Card

struct ClientCard: View {
    let client: Client
    let onTap: () -> Void

    @State private var isHovered = false
    @EnvironmentObject var appModel: AppModel

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Selection Checkbox
                Button(action: {
                    var updatedClient = client
                    updatedClient.selectedForSending.toggle()
                    appModel.updateClient(updatedClient)
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(client.selectedForSending ? ForceIQColors.electricGreen : ForceIQColors.forceRed.opacity(0.3), lineWidth: 2)
                            .frame(width: 24, height: 24)

                        if client.selectedForSending {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(ForceIQColors.electricGreen)
                        }
                    }
                }
                .buttonStyle(.plain)

                // Avatar
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [ForceIQColors.highlightYellow, ForceIQColors.electricGreen],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(String(client.name.prefix(1)).uppercased())
                            .font(.system(size: 20, weight: .black, design: .default))
                            .foregroundColor(ForceIQColors.black)
                    )

                // Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(client.name)
                        .font(.system(size: 15, weight: .bold, design: .default))
                        .foregroundColor(ForceIQColors.textPrimary)

                    HStack(spacing: 12) {
                        Label(client.email, systemImage: "envelope.fill")
                        Label(client.phone, systemImage: "message.fill")
                    }
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(ForceIQColors.textSecondary)
                }

                Spacer()

                // Stats
                VStack(alignment: .trailing, spacing: 6) {
                    if let lastSent = client.lastMessageSent {
                        Text("LAST MESSAGE")
                            .font(.system(size: 9, weight: .bold, design: .default))
                            .tracking(1)
                            .foregroundColor(ForceIQColors.textMuted)

                        Text(lastSent, style: .relative)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(ForceIQColors.electricGreen)
                    }

                    Text("\(client.totalBookings) BOOKINGS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(ForceIQColors.highlightYellow)
                }

                // Delete button
                Button(action: {
                    withAnimation {
                        appModel.deleteClient(client)
                    }
                }) {
                    Image(systemName: "trash.fill")
                        .foregroundColor(ForceIQColors.forceRed)
                        .font(.system(size: 14))
                        .padding(8)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
        .buttonStyle(.plain)
        .forceIQCard(level: 1)
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .shadow(color: ForceIQColors.highlightYellow.opacity(isHovered ? 0.2 : 0), radius: 8)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Client Form

struct ClientFormView: View {
    enum Mode {
        case add
        case edit(Client)

        var title: String {
            switch self {
            case .add: return "Add Client"
            case .edit: return "Edit Client"
            }
        }
    }

    @EnvironmentObject var appModel: AppModel
    @Environment(\.dismiss) var dismiss

    let mode: Mode

    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var notes = ""

    init(mode: Mode) {
        self.mode = mode
        if case .edit(let client) = mode {
            _name = State(initialValue: client.name)
            _email = State(initialValue: client.email)
            _phone = State(initialValue: client.phone)
            _notes = State(initialValue: client.notes)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                ForceIQSectionHeader(title: mode.title)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(ForceIQColors.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(24)

            Divider()
                .background(ForceIQColors.forceRed.opacity(0.3))

            // Form
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    FormField(label: "Name", text: $name, placeholder: "John Doe")
                    FormField(label: "Email", text: $email, placeholder: "john@example.com")
                    FormField(label: "Phone / iMessage", text: $phone, placeholder: "+1234567890")

                    VStack(alignment: .leading, spacing: 8) {
                        Text("NOTES")
                            .font(.system(size: 11, weight: .bold, design: .default))
                            .tracking(1.5)
                            .foregroundColor(ForceIQColors.highlightYellow)

                        TextEditor(text: $notes)
                            .font(.system(size: 14, weight: .regular, design: .monospaced))
                            .foregroundColor(ForceIQColors.textPrimary)
                            .frame(height: 100)
                            .padding(12)
                            .background(ForceIQColors.iceCharcoalDark)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(ForceIQColors.forceRed.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                .padding(24)
            }

            Divider()
                .background(ForceIQColors.forceRed.opacity(0.3))

            // Actions
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(ForceIQButtonStyle(type: .danger))

                Spacer()

                Button(mode.title == "Add Client" ? "Add Client" : "Save Changes") {
                    saveClient()
                }
                .buttonStyle(ForceIQButtonStyle(type: .primary))
                .disabled(name.isEmpty || email.isEmpty || phone.isEmpty)
            }
            .padding(24)
        }
        .frame(width: 500, height: 600)
        .background(ForceIQColors.iceCharcoal)
    }

    private func saveClient() {
        switch mode {
        case .add:
            let client = Client(
                name: name,
                email: email,
                phone: phone,
                notes: notes
            )
            appModel.addClient(client)

        case .edit(var client):
            client.name = name
            client.email = email
            client.phone = phone
            client.notes = notes
            appModel.updateClient(client)
        }

        dismiss()
    }
}

struct FormField: View {
    let label: String
    @Binding var text: String
    let placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .bold, design: .default))
                .tracking(1.5)
                .foregroundColor(ForceIQColors.highlightYellow)

            TextField(placeholder, text: $text)
                .textFieldStyle(ForceIQTextFieldStyle())
        }
    }
}

// MARK: - Contacts Picker

struct ContactsPickerView: View {
    @Environment(\.dismiss) var dismiss
    let onImport: ([CNContact]) -> Void

    @State private var groups: [CNGroup] = []
    @State private var selectedGroups: Set<String> = []
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var contactCounts: [String: Int] = [:]
    
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                ForceIQSectionHeader(title: "Import from Contacts")
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(ForceIQColors.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            
            Divider()
                .background(ForceIQColors.forceRed.opacity(0.3))
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(ForceIQColors.forceRed)
                    .padding()
            }
            
            Text("Select contact groups to import:")
                .font(.system(size: 12, weight: .medium, design: .default))
                .foregroundColor(ForceIQColors.textSecondary)
                .padding(.horizontal, 24)

            // Groups List
            if isLoading {
                Spacer()
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(ForceIQColors.electricGreen)
                Spacer()
            } else if groups.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "person.3.slash")
                        .font(.system(size: 48))
                        .foregroundColor(ForceIQColors.textMuted)

                    Text("NO CONTACT GROUPS")
                        .font(.system(size: 12, weight: .bold, design: .default))
                        .tracking(1.5)
                        .foregroundColor(ForceIQColors.textMuted)

                    Text("Create groups in Contacts app")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(ForceIQColors.textMuted.opacity(0.7))
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(groups, id: \.identifier) { group in
                            GroupRow(
                                group: group,
                                contactCount: contactCounts[group.identifier] ?? 0,
                                isSelected: selectedGroups.contains(group.identifier)
                            ) {
                                if selectedGroups.contains(group.identifier) {
                                    selectedGroups.remove(group.identifier)
                                } else {
                                    selectedGroups.insert(group.identifier)
                                }
                            }
                        }
                    }
                    .padding(24)
                }
            }

            // Footer
            HStack {
                let totalContacts = selectedGroups.compactMap { contactCounts[$0] }.reduce(0, +)
                Text("\(selectedGroups.count) GROUPS · \(totalContacts) CONTACTS")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(ForceIQColors.textMuted)

                Spacer()

                Button(action: { dismiss() }) {
                    Text("Cancel")
                }
                .buttonStyle(ForceIQButtonStyle(type: .secondary))

                Button(action: importSelectedGroups) {
                    Text("Import Groups")
                }
                .buttonStyle(ForceIQButtonStyle(type: .primary))
                .disabled(selectedGroups.isEmpty)
            }
            .padding(24)
            .background(ForceIQColors.iceCharcoal)
        }
        .frame(width: 600, height: 700)
        .background(ForceIQColors.iceCharcoal)
        .task {
            await loadGroups()
        }
    }
    
    private func loadGroups() async {
        let store = CNContactStore()

        do {
            // Request access
            let granted = try await store.requestAccess(for: .contacts)

            guard granted else {
                errorMessage = "❌ Contacts access denied. Please enable in System Settings."
                isLoading = false
                return
            }

            // Fetch all groups
            let fetchedGroups = try store.groups(matching: nil)

            // Count contacts in each group
            var counts: [String: Int] = [:]
            let keys = [CNContactGivenNameKey, CNContactFamilyNameKey] as [CNKeyDescriptor]

            for group in fetchedGroups {
                let predicate = CNContact.predicateForContactsInGroup(withIdentifier: group.identifier)
                let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keys)
                counts[group.identifier] = contacts.count
            }

            await MainActor.run {
                self.groups = fetchedGroups.sorted { $0.name < $1.name }
                self.contactCounts = counts
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "❌ Failed to load groups: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    private func importSelectedGroups() {
        let store = CNContactStore()
        var allContacts: [CNContact] = []

        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactEmailAddressesKey] as [CNKeyDescriptor]

        for groupId in selectedGroups {
            do {
                let predicate = CNContact.predicateForContactsInGroup(withIdentifier: groupId)
                let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keys)

                // Only include contacts with phone or email
                let validContacts = contacts.filter { !$0.phoneNumbers.isEmpty || !$0.emailAddresses.isEmpty }
                allContacts.append(contentsOf: validContacts)
            } catch {
                print("❌ Failed to fetch contacts for group \(groupId): \(error.localizedDescription)")
            }
        }

        // Remove duplicates by identifier
        var uniqueContacts: [CNContact] = []
        var seenIds = Set<String>()

        for contact in allContacts {
            if !seenIds.contains(contact.identifier) {
                uniqueContacts.append(contact)
                seenIds.insert(contact.identifier)
            }
        }

        onImport(uniqueContacts)
        dismiss()
    }
}

struct GroupRow: View {
    let group: CNGroup
    let contactCount: Int
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                // Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isSelected ? ForceIQColors.electricGreen : ForceIQColors.forceRed.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(ForceIQColors.electricGreen)
                    }
                }

                // Group Icon
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [ForceIQColors.highlightYellow, ForceIQColors.electricGreen],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(ForceIQColors.black)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.system(size: 14, weight: .bold, design: .default))
                        .foregroundColor(ForceIQColors.textPrimary)

                    Text("\(contactCount) CONTACTS")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(0.5)
                        .foregroundColor(ForceIQColors.highlightYellow)
                }

                Spacer()
            }
            .padding(16)
        }
        .buttonStyle(.plain)
        .background(isSelected ? ForceIQColors.iceCharcoalDark : ForceIQColors.iceCharcoal)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? ForceIQColors.electricGreen.opacity(0.5) : ForceIQColors.forceRed.opacity(0.3), lineWidth: 1)
        )
    }
}
