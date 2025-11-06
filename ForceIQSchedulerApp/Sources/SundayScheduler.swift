import Foundation

class SundayScheduler {
    private var timer: Timer?
    private var sendAction: (() async -> Void)?

    func configure(enabled: Bool, sendTime: Date, action: @escaping () async -> Void) {
        self.sendAction = action

        timer?.invalidate()
        timer = nil

        guard enabled else { return }

        let calendar = Calendar.current
        let sendHour = calendar.component(.hour, from: sendTime)
        let sendMinute = calendar.component(.minute, from: sendTime)

        print("⏰ Sunday scheduler enabled: Every Sunday at \(sendHour):\(String(format: "%02d", sendMinute))")

        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkAndSend(targetHour: sendHour, targetMinute: sendMinute)
        }
    }

    private func checkAndSend(targetHour: Int, targetMinute: Int) {
        let now = Date()
        let calendar = Calendar.current

        let weekday = calendar.component(.weekday, from: now)
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)

        // Sunday = 1 in Calendar
        guard weekday == 1,
              hour == targetHour,
              minute == targetMinute else {
            return
        }

        print("📤 Sunday scheduler triggered!")

        Task {
            await sendAction?()
        }
    }

    deinit {
        timer?.invalidate()
    }
}
