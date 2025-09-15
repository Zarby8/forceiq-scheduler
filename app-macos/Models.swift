import Foundation

struct Client: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var handle: String // iMessage/SMS handle
    var email: String
    var selected: Bool
    var active: Bool
    var notes: String

    init(id: UUID = UUID(), name: String, handle: String, email: String = "", selected: Bool = false, active: Bool = true, notes: String = "") {
        self.id = id
        self.name = name
        self.handle = handle
        self.email = email
        self.selected = selected
        self.active = active
        self.notes = notes
    }
}

struct SendResult: Codable {
    let handle: String
    let success: Bool
    let error: String?
}

