import Foundation
import AppKit

class IMessageService {
    func sendMessage(_ message: String, to phoneNumber: String) -> Bool {
        let script = """
        tell application "Messages"
            set targetService to 1st account whose service type = iMessage
            set targetBuddy to participant "\(phoneNumber)" of targetService
            send "\(message.replacingOccurrences(of: "\"", with: "\\\""))" to targetBuddy
        end tell
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)

            if let error = error {
                print("❌ AppleScript error: \(error)")
                return false
            }

            return true
        }

        return false
    }

    func testConnection() -> Bool {
        let script = """
        tell application "Messages"
            return "OK"
        end tell
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            let result = scriptObject.executeAndReturnError(&error)

            if let error = error {
                print("❌ Messages app not accessible: \(error)")
                return false
            }

            return result.stringValue == "OK"
        }

        return false
    }
}
