import SwiftUI
import ForceIQSchedulerFeature

@main
struct ForceIQSchedulerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        Settings {
            SettingsView()
        }
    }
}
