import SwiftUI

private struct MenuBarMenuContent: View {
    @Environment(\.openSettings) private var openSettings
    @AppStorage(SettingsKeys.spotlightEnabled) private var spotlightEnabled = SettingsDefaults.spotlightEnabled

    var body: some View {
        Toggle("Spotlight", isOn: $spotlightEnabled)
        Divider()
        Button("Settings...") {
            NSApp.activate()
            openSettings()
        }
        .keyboardShortcut(",")
        Divider()
        Button("Quit Beacon") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}

@main
struct BeaconApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
        MenuBarExtra("Beacon", systemImage: "target") {
            MenuBarMenuContent()
        }
    }
}
