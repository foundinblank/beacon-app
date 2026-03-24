import os
import SwiftUI

private let log = Logger(subsystem: "com.foundinblank.beacon", category: "menu")

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
        .keyboardShortcut("0", modifiers: [.command])
        Divider()
        Button("Settings...") {
            openSettings()
            NSApp.activate()
            // Settings window may already exist but be behind other windows;
            // find it specifically and bring it forward.
            DispatchQueue.main.async {
                for window in NSApp.windows
                where window.canBecomeKey && !(window is NSPanel) {
                    window.makeKeyAndOrderFront(nil)
                }
                NSApp.activate()
            }
        }
        .keyboardShortcut(",")
        Divider()
        Button("Welcome Guide") {
            appDelegate.showOnboarding()
        }
        Button("Keyboard Shortcuts") {
            showKeyboardShortcuts()
        }
        Button("About Beacon") {
            NSApplication.shared.orderFrontStandardAboutPanel()
            NSApp.activate()
        }
        Divider()
        Button("Quit Beacon") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    private func showKeyboardShortcuts() {
        let alert = NSAlert()
        alert.messageText = "Keyboard Shortcuts"
        alert.informativeText = """
        ⌘0\tPing (center cursor)
        ⌘,\tSettings
        ⌘Q\tQuit
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        NSApp.activate()
        alert.runModal()
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
