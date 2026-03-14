import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var overlayController: OverlayWindowController?
    private var mouseTracker: MouseTracker?
    private var menuBarManager: MenuBarManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBarManager = MenuBarManager()

        guard let screen = NSScreen.main else { return }

        overlayController = OverlayWindowController(screen: screen)
        overlayController?.window?.orderFrontRegardless()

        mouseTracker = MouseTracker { [weak self] position in
            self?.overlayController?.updateCursorPosition(position)
        }
        mouseTracker?.start()
    }
}
