import Foundation
import Combine
import CryptoKit

public final class AppModel: ObservableObject {
    @Published var clients: [Client] = []
    @Published var messageTemplate: String = "Hi {name}! Here's my ForceIQ scheduling link: {link}\n\nPlease pick a slot and answer the game questions."
    @Published var sending: Bool = false
    @Published var status: String = ""
    @Published var logs: [String] = []
    @Published var sendResults: [String: SendResult] = [:]

    public let config = AppConfig()

    private let saveURL: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("ForceIQScheduler", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("clients.json")
    }()

    public init() {
        load()
        if clients.isEmpty {
            clients = [
                Client(name: "Jane Appleseed", handle: "+15551234567", email: "jane@example.com"),
                Client(name: "Client B", handle: "clientb@example.com", email: "clientb@example.com"),
                Client(name: "Client C", handle: "+15557654321", email: "c@example.com")
            ]
        }
    }

    func load() {
        guard let data = try? Data(contentsOf: saveURL) else { return }
        if let decoded = try? JSONDecoder().decode([Client].self, from: data) {
            clients = decoded
        }
    }
    func save() {
        if let data = try? JSONEncoder().encode(clients) {
            try? data.write(to: saveURL)
        }
    }

    public func exportClients() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(clients)
    }

    public func importClients(from data: Data) -> Bool {
        do {
            let decoder = JSONDecoder()
            let importedClients = try decoder.decode([Client].self, from: data)
            clients = importedClients
            save()
            status = "Imported \(importedClients.count) clients successfully."
            return true
        } catch {
            status = "Import failed: \(error.localizedDescription)"
            return false
        }
    }

    public func exportClientsAsCSV() -> String {
        var csv = "Name,Handle,Email,Active,DoNotDisturb,Notes\n"
        for client in clients {
            let name = client.name.replacingOccurrences(of: ",", with: ";")
            let handle = client.handle.replacingOccurrences(of: ",", with: ";")
            let email = client.email.replacingOccurrences(of: ",", with: ";")
            let notes = client.notes.replacingOccurrences(of: ",", with: ";")
            csv += "\(name),\(handle),\(email),\(client.active),\(client.doNotDisturb),\(notes)\n"
        }
        return csv
    }

    func resolvedMessage(for client: Client, link: String) -> String {
        messageTemplate
            .replacingOccurrences(of: "{name}", with: client.name)
            .replacingOccurrences(of: "{link}", with: link)
    }

    func buildSignedLink(for client: Client) -> String {
        // token = base64url(HMAC_SHA256(secret, cid|ts)) &ts=...&cid=...
        let cid = client.id.uuidString
        let ts = String(Int(Date().timeIntervalSince1970))
        let dataToSign = (cid + "|" + ts).data(using: .utf8)!
        let key = SymmetricKey(data: config.hmacSecret.data(using: .utf8)!)
        let sig = HMAC<SHA256>.authenticationCode(for: dataToSign, using: key)
        let token = Data(sig).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")

        var comps = URLComponents(url: config.webBaseURL, resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            .init(name: "cid", value: cid),
            .init(name: "name", value: client.name),
            .init(name: "email", value: client.email),
            .init(name: "ts", value: ts),
            .init(name: "sig", value: token)
        ]
        return comps.url!.absoluteString
    }

    func sendSelected() {
        let targets = clients.filter { $0.selected && $0.active && !$0.handle.isEmpty && !$0.doNotDisturb }
        guard !targets.isEmpty else {
            status = "Select at least one active, non-DND client with a handle."
            return
        }
        sending = true
        status = "Sending to \(targets.count)..."
        logs.removeAll()
        sendResults.removeAll()

        // Simple synchronous approach to avoid concurrency issues
        var successCount = 0
        var failedNames: [String] = []

        for (index, client) in targets.enumerated() {
            status = "Sending to \(client.name)... (\(index + 1)/\(targets.count))"

            let link = buildSignedLink(for: client)
            let text = resolvedMessage(for: client, link: link)

            // Try up to 3 times
            var success = false
            var lastError: String?

            for attempt in 1...3 {
                if attempt > 1 {
                    Thread.sleep(forTimeInterval: Double(attempt) * 0.5) // 0.5, 1.0, 1.5 second delays
                }

                success = sendMessageAppleScript(handle: client.handle, text: text)
                if success {
                    break
                } else {
                    lastError = "Send failed (attempt \(attempt))"
                }
            }

            let result = SendResult(handle: client.handle, success: success, error: lastError)
            sendResults[client.id.uuidString] = result

            if success {
                successCount += 1
            } else {
                failedNames.append(client.name)
            }

            // Delay between clients
            if index < targets.count - 1 {
                Thread.sleep(forTimeInterval: 0.4)
            }
        }

        sending = false
        let totalCount = targets.count
        if failedNames.isEmpty {
            status = "✅ Successfully sent to all \(totalCount) clients."
        } else {
            status = "⚠️ Sent to \(successCount)/\(totalCount). Failed: \(failedNames.joined(separator: ", "))"
        }
        addLog("Send completed: \(successCount) successful, \(failedNames.count) failed")
    }

    private func addLog(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        logs.append("[\(timestamp)] \(message)")
    }

    private func sendMessageAppleScript(handle: String, text: String) -> Bool {
        let script = """
        on run argv
            set theHandle to item 1 of argv
            set theText to item 2 of argv
            tell application "Messages"
                activate
                set iMsg to missing value
                set smsSvc to missing value
                try
                    set iMsg to first service whose service type = iMessage
                end try
                try
                    set smsSvc to first service whose service type = SMS
                end try
                set theService to iMsg
                if theService is missing value then set theService to smsSvc
                if theService is missing value then error "No Messages service available."
                set theChat to make new text chat with properties {service:theService, participants:{theHandle}}
                send theText to theChat
            end tell
        end run
        """

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = ["-l", "AppleScript", "-e", script, "--", handle, text]
        let pipe = Pipe()
        task.standardError = pipe
        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            return false
        }
        return task.terminationStatus == 0
    }
}

