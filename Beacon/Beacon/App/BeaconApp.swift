import os
import SwiftUI

private let log = Logger(subsystem: "com.beacon.app", category: "menu")

private struct MenuBarMenuContent: View {
    @Environment(\.openSettings) private var openSettings
    @AppStorage(SettingsKeys.crosshairEnabled) private var crosshairEnabled = SettingsDefaults.crosshairEnabled
    @AppStorage(SettingsKeys.spotlightEnabled) private var spotlightEnabled = SettingsDefaults.spotlightEnabled
    let appDelegate: AppDelegate

    var body: some View {
        Toggle("Crosshair", isOn: $crosshairEnabled)
            .onChange(of: crosshairEnabled) { _, newValue in
                NSAccessibility.post(
                    element: NSApp as Any,
                    notification: .announcementRequested,
                    userInfo: [
                        .announcement: "Crosshair \(newValue ? "on" : "off")",
                        .priority: NSAccessibilityPriorityLevel.high.rawValue,
                    ]
                )
            }
        Toggle("Spotlight", isOn: $spotlightEnabled)
            .onChange(of: spotlightEnabled) { _, newValue in
                NSAccessibility.post(
                    element: NSApp as Any,
                    notification: .announcementRequested,
                    userInfo: [
                        .announcement: "Spotlight \(newValue ? "on" : "off")",
                        .priority: NSAccessibilityPriorityLevel.high.rawValue,
                    ]
                )
            }
        Button("Ping") {
            log.debug("Ping button tapped")
            appDelegate.performPing()
        }
        .keyboardShortcut("/", modifiers: [.command, .shift])
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
        MenuBarExtra("Beacon", systemImage: "scope") {
            MenuBarMenuContent(appDelegate: appDelegate)
        }
    }
}
