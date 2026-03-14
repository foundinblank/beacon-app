import AppKit
import SwiftUI

class MenuBarManager: NSObject {
    private var statusItem: NSStatusItem
    private var settingsWindow: NSWindow?

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "target", accessibilityDescription: "Beacon")
        }

        let menu = NSMenu()
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Beacon", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc private func openSettings() {
        // Embed a SwiftUI view that uses @Environment(\.openSettings) to trigger the Settings scene
        let trigger = NSHostingController(rootView: SettingsOpener())
        trigger.view.frame = .zero
        // Adding to a window and triggering onAppear causes the environment action to fire
        let window = NSWindow()
        window.contentViewController = trigger
        settingsWindow = window
        NSApp.activate(ignoringOtherApps: true)
    }
}

private struct SettingsOpener: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Color.clear
            .onAppear {
                openSettings()
            }
    }
}
