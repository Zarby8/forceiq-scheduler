import Foundation
@preconcurrency import Contacts

public enum ContactGroup: String, CaseIterable {
    case youth = "YOUTH"
    case junior = "JUNIOR"
    case college = "COLLEGE"
    case pro = "PRO"

    public var displayName: String { rawValue }
}

@MainActor
public class ContactsManager: ObservableObject {
    private let contactStore = CNContactStore()
    @Published public var hasAccess = false
    @Published public var isLoading = false
    @Published public var statusMessage = ""

    public init() {
        checkAccess()
    }

    public func requestAccess() async {
        isLoading = true
        statusMessage = "Requesting Contacts access..."

        do {
            let granted = try await contactStore.requestAccess(for: .contacts)
            hasAccess = granted
            isLoading = false
            statusMessage = granted ? "✅ Contacts access granted" : "❌ Contacts access denied"
        } catch {
            hasAccess = false
            isLoading = false
            statusMessage = "❌ Error requesting access: \(error.localizedDescription)"
        }
    }

    private func checkAccess() {
        hasAccess = CNContactStore.authorizationStatus(for: .contacts) == .authorized
    }

    public func createForceIQGroups() async {
        guard hasAccess else { return }

        isLoading = true
        statusMessage = "Creating ForceIQ contact groups..."

        let saveRequest = CNSaveRequest()
        var createdCount = 0

        for group in ContactGroup.allCases {
            let groupName = "ForceIQ - \(group.displayName)"

            // Check if group already exists
            if !groupExists(groupName) {
                let newGroup = CNMutableGroup()
                newGroup.name = groupName
                saveRequest.add(newGroup, toContainerWithIdentifier: nil)
                createdCount += 1
            }
        }

        do {
            if createdCount > 0 {
                try contactStore.execute(saveRequest)
                statusMessage = "✅ Created \(createdCount) ForceIQ groups in Contacts"
            } else {
                statusMessage = "✅ All ForceIQ groups already exist"
            }
        } catch {
            statusMessage = "❌ Error creating groups: \(error.localizedDescription)"
        }

        isLoading = false
    }

    public func importClientsFromContacts() async -> [Client] {
        guard hasAccess else { return [] }

        isLoading = true
        statusMessage = "Importing clients from Contacts..."

        var allClients: [Client] = []

        for group in ContactGroup.allCases {
            let groupName = "ForceIQ - \(group.displayName)"
            let clients = await fetchClientsFromGroup(groupName: groupName, category: group)
            allClients.append(contentsOf: clients)
        }

        isLoading = false
        statusMessage = "✅ Imported \(allClients.count) clients from Contacts"

        return allClients
    }

    private func groupExists(_ groupName: String) -> Bool {
        do {
            let groups = try contactStore.groups(matching: nil)
            return groups.contains { $0.name == groupName }
        } catch {
            return false
        }
    }

    private func fetchClientsFromGroup(groupName: String, category: ContactGroup) async -> [Client] {
        do {
            // Find the group
            let groups = try contactStore.groups(matching: nil)
            guard let group = groups.first(where: { $0.name == groupName }) else {
                return []
            }

            // Fetch contacts in the group
            let keysToFetch: [CNKeyDescriptor] = [
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor,
                CNContactEmailAddressesKey as CNKeyDescriptor,
                CNContactNoteKey as CNKeyDescriptor
            ]

            let contacts = try contactStore.unifiedContacts(
                matching: CNContact.predicateForContactsInGroup(withIdentifier: group.identifier),
                keysToFetch: keysToFetch
            )

            return contacts.compactMap { contact in
                let fullName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
                guard !fullName.isEmpty else { return nil }

                // Get primary phone number
                let phoneNumber = contact.phoneNumbers.first?.value.stringValue ?? ""

                // Get primary email
                let email = contact.emailAddresses.first?.value as String? ?? ""

                // Skip if no phone or email
                guard !phoneNumber.isEmpty || !email.isEmpty else { return nil }

                // Use phone as handle if available, otherwise email
                let handle = !phoneNumber.isEmpty ? phoneNumber : email

                return Client(
                    name: fullName,
                    handle: handle,
                    email: email,
                    selected: false,
                    active: true,
                    doNotDisturb: false,
                    notes: "Imported from \(groupName) • \(contact.note)"
                )
            }
        } catch {
            statusMessage = "❌ Error fetching from \(groupName): \(error.localizedDescription)"
            return []
        }
    }

    public func syncClientToContacts(_ client: Client, to group: ContactGroup) async {
        guard hasAccess else { return }

        let groupName = "ForceIQ - \(group.displayName)"

        do {
            // Find the group
            let groups = try contactStore.groups(matching: nil)
            guard let targetGroup = groups.first(where: { $0.name == groupName }) else {
                statusMessage = "❌ Group \(groupName) not found"
                return
            }

            // Create new contact
            let contact = CNMutableContact()
            let nameParts = client.name.components(separatedBy: " ")
            contact.givenName = nameParts.first ?? ""
            if nameParts.count > 1 {
                contact.familyName = nameParts.dropFirst().joined(separator: " ")
            }

            // Add phone number
            if client.handle.hasPrefix("+") || client.handle.contains("-") {
                let phoneNumber = CNPhoneNumber(stringValue: client.handle)
                let phone = CNLabeledValue(label: CNLabelPhoneNumberMain, value: phoneNumber)
                contact.phoneNumbers = [phone]
            }

            // Add email
            if !client.email.isEmpty {
                let email = CNLabeledValue(label: CNLabelHome, value: client.email as NSString)
                contact.emailAddresses = [email]
            }

            // Add notes
            contact.note = "ForceIQ Client\n\(client.notes)"

            // Save contact and add to group
            let saveRequest = CNSaveRequest()
            saveRequest.add(contact, toContainerWithIdentifier: nil)
            saveRequest.addMember(contact, to: targetGroup)

            try contactStore.execute(saveRequest)

            statusMessage = "✅ Added \(client.name) to \(groupName)"

        } catch {
            statusMessage = "❌ Error syncing \(client.name): \(error.localizedDescription)"
        }
    }
}