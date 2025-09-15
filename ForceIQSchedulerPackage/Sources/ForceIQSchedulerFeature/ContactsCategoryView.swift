import SwiftUI

// Simple client representation for drag/drop
public struct ContactItem: Identifiable, Hashable {
    public let id = UUID()
    public var name: String
    public var phone: String
    public var category: ContactGroup?

    public init(name: String, phone: String, category: ContactGroup? = nil) {
        self.name = name
        self.phone = phone
        self.category = category
    }
}

public struct ContactsCategoryView: View {
    @ObservedObject var appModel: AppModel
    @Environment(\.presentationMode) var presentationMode

    @State private var contactItems: [ContactItem] = []
    @State private var draggedContact: ContactItem?
    @State private var isLoading = false

    public init(appModel: AppModel) {
        self.appModel = appModel
    }

    public var body: some View {
        NavigationView {
            HStack(spacing: 0) {
                // Left Panel - Categories
                categoriesPanel
                    .frame(minWidth: 300)

                Divider()

                // Right Panel - All Contacts
                contactsPanel
                    .frame(minWidth: 400)
            }
            .navigationTitle("Organize Contacts")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save to Client List") {
                        saveToClientList()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(contactItems.isEmpty)
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .onAppear {
            loadContactsFromContacts()
        }
    }

    private var categoriesPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("CATEGORIES")
                    .font(.headline)
                    .foregroundColor(.forceYellow)
                Spacer()
                Text("\(contactItems.filter { $0.category != nil }.count) assigned")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(ContactGroup.allCases, id: \.self) { category in
                        CategoryDropZone(
                            category: category,
                            contacts: contactItems.filter { $0.category == category },
                            draggedContact: $draggedContact
                        ) { contact in
                            assignContactToCategory(contact, category: category)
                        } onRemove: { contact in
                            removeContactFromCategory(contact)
                        }
                    }

                    // Unassigned contacts
                    UnassignedDropZone(
                        contacts: contactItems.filter { $0.category == nil },
                        draggedContact: $draggedContact
                    ) { contact in
                        removeContactFromCategory(contact)
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(Color.forceCard.opacity(0.3))
    }

    private var contactsPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("ALL CONTACTS")
                    .font(.headline)
                    .foregroundColor(.forceGreen)
                Spacer()
                Button("Load from Contacts App") {
                    loadContactsFromContacts()
                }
                .buttonStyle(.bordered)
                .disabled(isLoading)
            }
            .padding(.horizontal)

            if isLoading {
                VStack {
                    ProgressView()
                    Text("Loading contacts...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if contactItems.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.3")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("No contacts loaded")
                        .font(.title3)
                    Text("Click 'Load from Contacts App' to import your contacts")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(contactItems) { contact in
                            DraggableContactRow(
                                contact: contact,
                                draggedContact: $draggedContact
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private func loadContactsFromContacts() {
        isLoading = true

        // Simulate loading from Contacts (you'd implement actual Contacts framework integration)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // For demo, create some sample contacts
            contactItems = [
                ContactItem(name: "Alex Thompson", phone: "+1 (555) 123-4567"),
                ContactItem(name: "Sarah Johnson", phone: "+1 (555) 234-5678"),
                ContactItem(name: "Mike Wilson", phone: "+1 (555) 345-6789"),
                ContactItem(name: "Emily Davis", phone: "+1 (555) 456-7890"),
                ContactItem(name: "Jake Miller", phone: "+1 (555) 567-8901"),
                ContactItem(name: "Lisa Brown", phone: "+1 (555) 678-9012"),
                ContactItem(name: "Ryan Taylor", phone: "+1 (555) 789-0123"),
                ContactItem(name: "Anna White", phone: "+1 (555) 890-1234"),
            ]

            // Also load existing clients and categorize them
            for client in appModel.clients {
                if let existingIndex = contactItems.firstIndex(where: { $0.name == client.name }) {
                    // Update existing contact with category info from notes
                    if client.notes.contains("YOUTH") {
                        contactItems[existingIndex].category = .youth
                    } else if client.notes.contains("JUNIOR") {
                        contactItems[existingIndex].category = .junior
                    } else if client.notes.contains("COLLEGE") {
                        contactItems[existingIndex].category = .college
                    } else if client.notes.contains("PRO") {
                        contactItems[existingIndex].category = .pro
                    }
                } else {
                    // Add client as new contact
                    var newContact = ContactItem(name: client.name, phone: client.handle)
                    if client.notes.contains("YOUTH") {
                        newContact.category = .youth
                    } else if client.notes.contains("JUNIOR") {
                        newContact.category = .junior
                    } else if client.notes.contains("COLLEGE") {
                        newContact.category = .college
                    } else if client.notes.contains("PRO") {
                        newContact.category = .pro
                    }
                    contactItems.append(newContact)
                }
            }

            isLoading = false
        }
    }

    private func assignContactToCategory(_ contact: ContactItem, category: ContactGroup) {
        if let index = contactItems.firstIndex(of: contact) {
            contactItems[index].category = category
        }
    }

    private func removeContactFromCategory(_ contact: ContactItem) {
        if let index = contactItems.firstIndex(of: contact) {
            contactItems[index].category = nil
        }
    }

    private func saveToClientList() {
        // Update existing clients and add new ones
        var updatedClients: [Client] = []

        for contactItem in contactItems {
            let categoryNote = contactItem.category?.displayName ?? "Unassigned"

            // Check if client already exists
            if let existingClient = appModel.clients.first(where: { $0.name == contactItem.name }) {
                var updatedClient = existingClient
                updatedClient.handle = contactItem.phone
                updatedClient.notes = "Category: \(categoryNote)"
                updatedClients.append(updatedClient)
            } else {
                // Create new client
                let newClient = Client(
                    name: contactItem.name,
                    handle: contactItem.phone,
                    email: "",
                    selected: false,
                    active: true,
                    doNotDisturb: false,
                    notes: "Category: \(categoryNote)"
                )
                updatedClients.append(newClient)
            }
        }

        appModel.clients = updatedClients
        appModel.save()
        appModel.status = "✅ Updated \(updatedClients.count) clients with categories"
    }
}

struct CategoryDropZone: View {
    let category: ContactGroup
    let contacts: [ContactItem]
    @Binding var draggedContact: ContactItem?
    let onDrop: (ContactItem) -> Void
    let onRemove: (ContactItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconForCategory(category))
                    .foregroundColor(.forceYellow)
                Text(category.displayName)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("\(contacts.count)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            VStack(spacing: 4) {
                ForEach(contacts, id: \.id) { contact in
                    ContactCard(contact: contact) {
                        onRemove(contact)
                    }
                }

                if contacts.isEmpty {
                    Text("Drop contacts here")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(minHeight: 40)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
                        )
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(draggedContact != nil ? Color.forceCard.opacity(0.8) : Color.forceCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(draggedContact != nil ? Color.forceYellow : Color.clear, lineWidth: 2)
                )
        )
        .onDrop(of: [.text], isTargeted: nil) { providers in
            handleDrop(providers)
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let draggedContact = draggedContact else { return false }
        onDrop(draggedContact)
        return true
    }

    private func iconForCategory(_ category: ContactGroup) -> String {
        switch category {
        case .youth: return "figure.skating"
        case .junior: return "figure.hockey"
        case .college: return "graduationcap"
        case .pro: return "trophy"
        }
    }
}

struct UnassignedDropZone: View {
    let contacts: [ContactItem]
    @Binding var draggedContact: ContactItem?
    let onDrop: (ContactItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.crop.circle")
                    .foregroundColor(.gray)
                Text("Unassigned")
                    .font(.headline)
                    .foregroundColor(.gray)
                Spacer()
                Text("\(contacts.count)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            VStack(spacing: 4) {
                ForEach(contacts, id: \.id) { contact in
                    ContactCard(contact: contact, showRemove: false) {}
                }

                if contacts.isEmpty {
                    Text("No unassigned contacts")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(minHeight: 20)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(draggedContact != nil ? Color.gray : Color.clear, lineWidth: 2)
                )
        )
        .onDrop(of: [.text], isTargeted: nil) { providers in
            handleDrop(providers)
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let draggedContact = draggedContact else { return false }
        onDrop(draggedContact)
        return true
    }
}

struct DraggableContactRow: View {
    let contact: ContactItem
    @Binding var draggedContact: ContactItem?

    var body: some View {
        ContactCard(contact: contact, showRemove: false) {}
            .draggable(contact.name) {
                ContactCard(contact: contact, showRemove: false) {}
                    .opacity(0.8)
            }
            .onDrag {
                draggedContact = contact
                return NSItemProvider(object: contact.name as NSString)
            }
    }
}

struct ContactCard: View {
    let contact: ContactItem
    var showRemove: Bool = true
    let onRemove: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                Text(contact.phone)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()

            if showRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.forceIceCharcoal)
        .cornerRadius(6)
    }
}