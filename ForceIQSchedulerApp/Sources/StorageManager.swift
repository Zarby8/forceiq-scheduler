import Foundation

class StorageManager: ObservableObject {
    static let shared = StorageManager()

    private let clientsKey = "forceiq.clients"
    private let configKey = "forceiq.config"

    private init() {}

    // MARK: - Client Storage

    func saveClients(_ clients: [Client]) {
        do {
            let data = try JSONEncoder().encode(clients)
            UserDefaults.standard.set(data, forKey: clientsKey)
        } catch {
            print("❌ Failed to save clients: \(error)")
        }
    }

    func loadClients() -> [Client] {
        guard let data = UserDefaults.standard.data(forKey: clientsKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([Client].self, from: data)
        } catch {
            print("❌ Failed to load clients: \(error)")
            return []
        }
    }

    // MARK: - Config Storage

    func saveConfig(_ config: AppConfig) {
        do {
            let data = try JSONEncoder().encode(config)
            UserDefaults.standard.set(data, forKey: configKey)
        } catch {
            print("❌ Failed to save config: \(error)")
        }
    }

    func loadConfig() -> AppConfig {
        guard let data = UserDefaults.standard.data(forKey: configKey) else {
            let defaultConfig = AppConfig.default
            saveConfig(defaultConfig)
            return defaultConfig
        }

        do {
            return try JSONDecoder().decode(AppConfig.self, from: data)
        } catch {
            print("❌ Failed to load config: \(error)")
            let defaultConfig = AppConfig.default
            saveConfig(defaultConfig)
            return defaultConfig
        }
    }

    // MARK: - Export/Import

    func exportClients(to url: URL) throws {
        let clients = loadClients()
        let data = try JSONEncoder().encode(clients)
        try data.write(to: url)
    }

    func importClients(from url: URL) throws -> [Client] {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([Client].self, from: data)
    }
}
