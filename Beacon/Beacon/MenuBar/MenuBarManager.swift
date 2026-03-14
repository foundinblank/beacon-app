import AppKit

class MenuBarManager {
    private var statusItem: NSStatusItem

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "target", accessibilityDescription: "Beacon")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit Beacon", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }
}
