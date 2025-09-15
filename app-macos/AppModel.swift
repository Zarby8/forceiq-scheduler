import Foundation
import Combine
import CryptoKit

final class AppModel: ObservableObject {
    @Published var clients: [Client] = []
    @Published var schedulingLink: String = "https://schedule.forcehockeyiq.com"
    @Published var messageTemplate: String = "Hi {name}! Here’s my ForceIQ scheduling link: {link}\n\nPlease pick a slot and answer the game questions."
    @Published var sending: Bool = false
    @Published var status: String = ""
    @Published var logs: [String] = []

    private let saveURL: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("ForceIQScheduler", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("clients.json")
    }()

    init() {
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
        let key = SymmetricKey(data: AppConfig.HMAC_SECRET.data(using: .utf8)!)
        let sig = HMAC<SHA256>.authenticationCode(for: dataToSign, using: key)
        let token = Data(sig).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")

        var comps = URLComponents(url: AppConfig.WEB_BASE, resolvingAgainstBaseURL: false)!
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
        let targets = clients.filter { $0.selected && $0.active && !$0.handle.isEmpty }
        guard !targets.isEmpty else {
            status = "Select at least one active client."
            return
        }
        sending = true
        status = "Sending to \(targets.count)..."
        logs.removeAll()

        DispatchQueue.global(qos: .userInitiated).async {
            var failures: [String] = []
            for c in targets {
                let link = self.buildSignedLink(for: c)
                let text = self.resolvedMessage(for: c, link: link)
                if !self.sendMessageAppleScript(handle: c.handle, text: text) {
                    failures.append(c.name)
                }
                usleep(400_000)
            }
            DispatchQueue.main.async {
                self.sending = false
                self.status = failures.isEmpty ? "Done. Sent to \(targets.count)." : "Issues: \(failures.joined(separator: ", "))"
            }
        }
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

