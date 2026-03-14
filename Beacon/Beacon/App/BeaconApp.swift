import SwiftUI

private struct MenuBarMenuContent: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
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
