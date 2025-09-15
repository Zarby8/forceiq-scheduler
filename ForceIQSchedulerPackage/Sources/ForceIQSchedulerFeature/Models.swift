import Foundation

public struct Client: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var handle: String // iMessage/SMS handle
    public var email: String
    public var selected: Bool
    public var active: Bool
    public var doNotDisturb: Bool
    public var notes: String

    public init(id: UUID = UUID(), name: String, handle: String, email: String = "", selected: Bool = false, active: Bool = true, doNotDisturb: Bool = false, notes: String = "") {
        self.id = id
        self.name = name
        self.handle = handle
        self.email = email
        self.selected = selected
        self.active = active
        self.doNotDisturb = doNotDisturb
        self.notes = notes
    }
}

public struct SendResult: Codable {
    public let handle: String
    public let success: Bool
    public let error: String?

    public init(handle: String, success: Bool, error: String? = nil) {
        self.handle = handle
        self.success = success
        self.error = error
    }
}

