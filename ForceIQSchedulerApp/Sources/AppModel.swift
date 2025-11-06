import Foundation
import SwiftUI

@MainActor
class AppModel: ObservableObject {
    // MARK: - Published State

    @Published var clients: [Client] = []
    @Published var config: AppConfig = .default
    @Published var upcomingBookings: [Booking] = []

    @Published var selectedTab: Tab = .dashboard
    @Published var isLoadingBookings = false

    // MARK: - Services

    private let storage = StorageManager.shared
    let googleAuth = GoogleAuthService()
    let iMessageService = IMessageService()
    let sundayScheduler = SundayScheduler()

    // MARK: - Tabs

    enum Tab: String, CaseIterable {
        case dashboard = "Dashboard"
        case clients = "Clients"
        case availability = "Availability"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .dashboard: return "chart.bar.fill"
            case .clients: return "person.3.fill"
            case .availability: return "calendar.badge.clock"
            case .settings: return "gearshape.fill"
            }
        }
    }

    // MARK: - Initialization

    init() {
        loadData()
        setupSundayScheduler()
    }

    private func loadData() {
        self.clients = storage.loadClients()
        self.config = storage.loadConfig()
    }

    // MARK: - Client Management

    func addClient(_ client: Client) {
        clients.append(client)
        storage.saveClients(clients)
    }

    func updateClient(_ client: Client) {
        if let index = clients.firstIndex(where: { $0.id == client.id }) {
            clients[index] = client
            storage.saveClients(clients)
        }
    }

    func deleteClient(_ client: Client) {
        clients.removeAll { $0.id == client.id }
        storage.saveClients(clients)
    }

    func deleteClients(at offsets: IndexSet) {
        clients.remove(atOffsets: offsets)
        storage.saveClients(clients)
    }

    // MARK: - Config Management

    func updateConfig(_ newConfig: AppConfig) {
        self.config = newConfig
        storage.saveConfig(newConfig)
    }

    func updateCoach(_ coach: Coach) {
        if let index = config.coaches.firstIndex(where: { $0.id == coach.id }) {
            config.coaches[index] = coach
            storage.saveConfig(config)

            // Sync availability to Vercel
            Task {
                await syncCoachAvailability(coach)
            }
        }
    }

    // MARK: - Vercel Sync

    private func syncCoachAvailability(_ coach: Coach) async {
        let apiUrl = "\(config.apiBaseUrl)/update-availability"

        // Convert WeeklySchedule to API format (0-6 integer keys)
        let apiSchedule: [Int: [[String: String]]] = [
            0: coach.weeklyHours.sunday.map { ["start": $0.start, "end": $0.end] },
            1: coach.weeklyHours.monday.map { ["start": $0.start, "end": $0.end] },
            2: coach.weeklyHours.tuesday.map { ["start": $0.start, "end": $0.end] },
            3: coach.weeklyHours.wednesday.map { ["start": $0.start, "end": $0.end] },
            4: coach.weeklyHours.thursday.map { ["start": $0.start, "end": $0.end] },
            5: coach.weeklyHours.friday.map { ["start": $0.start, "end": $0.end] },
            6: coach.weeklyHours.saturday.map { ["start": $0.start, "end": $0.end] }
        ]

        let payload: [String: Any] = [
            "coachId": coach.id,
            "weeklyHours": apiSchedule,
            "adminToken": "XXMiwoyrVpkuCg4EX5oa0Bw2QYDMMSpR"
        ]

        guard let url = URL(string: apiUrl),
              let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            print("❌ Failed to create sync request")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("✅ Synced availability for \(coach.name) to Vercel")
            } else {
                print("❌ Failed to sync availability: HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                if let responseText = String(data: data, encoding: .utf8) {
                    print("Response: \(responseText)")
                }
            }
        } catch {
            print("❌ Error syncing availability: \(error.localizedDescription)")
        }
    }

    func updateSundayConfig(_ sundayConfig: SundaySendConfig) {
        config.sundayConfig = sundayConfig
        storage.saveConfig(config)
    }

    // MARK: - Sunday Scheduler

    private func setupSundayScheduler() {
        sundayScheduler.configure(
            enabled: config.sundayConfig.enabled,
            sendTime: config.sundayConfig.sendTime
        ) { [weak self] in
            await self?.sendSundayMessages()
        }
    }

    func toggleSundayScheduler(_ enabled: Bool) {
        var newConfig = config.sundayConfig
        newConfig.enabled = enabled
        updateSundayConfig(newConfig)
        setupSundayScheduler()
    }

    func sendSundayMessages() async {
        print("📤 Starting Sunday message send...")

        let bookingUrl = config.bookingPageUrl

        for client in clients {
            let link = "\(bookingUrl)?cid=\(client.id.uuidString)&name=\(client.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&email=\(client.email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"

            let message = config.sundayConfig.messageTemplate
                .replacingOccurrences(of: "{name}", with: client.name)
                .replacingOccurrences(of: "{link}", with: link)

            let success = iMessageService.sendMessage(message, to: client.phone)

            if success {
                print("✅ Sent to \(client.name)")
                var updatedClient = client
                updatedClient.lastMessageSent = Date()
                updateClient(updatedClient)
            } else {
                print("❌ Failed to send to \(client.name)")
            }

            // Small delay between messages
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        }

        // Update last sent date
        var newConfig = config.sundayConfig
        newConfig.lastSentDate = Date()
        updateSundayConfig(newConfig)

        print("✅ Sunday message send complete")
    }

    // MARK: - Bookings

    func fetchUpcomingBookings() async {
        isLoadingBookings = true
        defer { isLoadingBookings = false }

        // TODO: Implement Google Calendar API calls to fetch events
        // For now, this is a placeholder
        // In production: fetch from both coaches' calendars via Google Calendar API

        print("📅 Fetching bookings...")
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s delay simulation
        print("✅ Bookings fetched")
    }

    // MARK: - Import/Export

    func exportClients() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "forceiq-clients-\(Date().timeIntervalSince1970).json"
        let url = tempDir.appendingPathComponent(filename)

        try storage.exportClients(to: url)
        return url
    }

    func importClients(from url: URL) throws {
        let importedClients = try storage.importClients(from: url)

        for client in importedClients {
            if !clients.contains(where: { $0.id == client.id }) {
                clients.append(client)
            }
        }

        storage.saveClients(clients)
    }
}
