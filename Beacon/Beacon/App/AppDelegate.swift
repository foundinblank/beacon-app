import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var overlayController: OverlayWindowController?
    private var mouseTracker: MouseTracker?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let screen = NSScreen.main else { return }

        overlayController = OverlayWindowController(screen: screen)
        overlayController?.showWindow(nil)

        mouseTracker = MouseTracker { [weak self] position in
            self?.overlayController?.updateCursorPosition(position)
        }
        mouseTracker?.start()
    }
}
