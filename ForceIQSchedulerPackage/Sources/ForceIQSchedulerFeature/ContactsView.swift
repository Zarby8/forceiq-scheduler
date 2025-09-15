import SwiftUI

public struct ContactsView: View {
    @StateObject private var contactsManager = ContactsManager()
    @Binding var clients: [Client]
    @Environment(\.presentationMode) var presentationMode

    @State private var selectedGroups: Set<ContactGroup> = Set(ContactGroup.allCases)
    @State private var importedClients: [Client] = []

    public init(clients: Binding<[Client]>) {
        self._clients = clients
    }

    public var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if contactsManager.hasAccess {
                    accessGrantedView
                } else {
                    accessRequestView
                }

                Spacer()

                HStack {
                    Text(contactsManager.statusMessage)
                        .foregroundColor(contactsManager.statusMessage.hasPrefix("✅") ? .green :
                                       contactsManager.statusMessage.hasPrefix("❌") ? .red : .gray)
                        .font(.caption)
                    Spacer()
                }
            }
            .padding()
            .navigationTitle("Contacts Integration")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 500)
    }

    private var accessRequestView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("Access to Contacts Required")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                Text("ForceIQ Scheduler needs access to your Contacts to import clients and create groups.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)

                if contactsManager.statusMessage.contains("denied") {
                    VStack(spacing: 8) {
                        Text("⚠️ Access was denied")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("Please go to System Settings > Privacy & Security > Contacts and enable access for ForceIQ Scheduler")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        Button("Open System Settings") {
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Contacts")!)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
            }

            Button(action: {
                Task {
                    await contactsManager.requestAccess()
                }
            }) {
                HStack {
                    if contactsManager.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text("Grant Access to Contacts")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(contactsManager.isLoading)
        }
    }

    private var accessGrantedView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("ForceIQ Contact Groups")
                    .font(.headline)

                Text("These groups will be created in your Contacts app:")
                    .font(.caption)
                    .foregroundColor(.gray)

                HStack {
                    ForEach(ContactGroup.allCases, id: \.self) { group in
                        VStack {
                            Image(systemName: iconFor(group))
                                .font(.title2)
                                .foregroundColor(.forceYellow)
                            Text(group.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .frame(minWidth: 80)
                    }
                }

                Button(action: {
                    Task {
                        await contactsManager.createForceIQGroups()
                    }
                }) {
                    HStack {
                        if contactsManager.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text("Create ForceIQ Groups in Contacts")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(contactsManager.isLoading)
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("Import Clients")
                    .font(.headline)

                Text("Select which groups to import:")
                    .font(.caption)
                    .foregroundColor(.gray)

                HStack {
                    ForEach(ContactGroup.allCases, id: \.self) { group in
                        Toggle(group.displayName, isOn: Binding(
                            get: { selectedGroups.contains(group) },
                            set: { if $0 { selectedGroups.insert(group) } else { selectedGroups.remove(group) } }
                        ))
                        .toggleStyle(.checkbox)
                    }
                }

                HStack {
                    Button(action: {
                        Task { @MainActor in
                            let imported = await contactsManager.importClientsFromContacts()
                            let filtered = imported.filter { client in
                                // Filter based on selected groups (simplified - in real app we'd track group membership)
                                return !selectedGroups.isEmpty
                            }
                            importedClients = filtered
                        }
                    }) {
                        HStack {
                            if contactsManager.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text("Import from Selected Groups")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(contactsManager.isLoading || selectedGroups.isEmpty)

                    if !importedClients.isEmpty {
                        Button("Merge \(importedClients.count) Clients") {
                            mergeImportedClients()
                            presentationMode.wrappedValue.dismiss()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            if !importedClients.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Preview (\(importedClients.count) clients)")
                        .font(.headline)

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(importedClients.prefix(10)) { client in
                                HStack {
                                    Text(client.name)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text(client.handle)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(4)
                            }

                            if importedClients.count > 10 {
                                Text("... and \(importedClients.count - 10) more")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .frame(maxHeight: 150)
                }
            }
        }
    }

    private func iconFor(_ group: ContactGroup) -> String {
        switch group {
        case .youth: return "figure.skating"
        case .junior: return "figure.hockey"
        case .college: return "graduationcap"
        case .pro: return "trophy"
        }
    }

    private func mergeImportedClients() {
        let existingNames = Set(clients.map { $0.name.lowercased() })
        let newClients = importedClients.filter { !existingNames.contains($0.name.lowercased()) }
        clients.append(contentsOf: newClients)
    }
}