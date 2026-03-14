import AppKit

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var overlayControllers: [OverlayWindowController] = []
    private var mouseTracker: MouseTracker?

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildOverlays()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        mouseTracker = MouseTracker { [weak self] position in
            self?.updateAllOverlays(cursorPosition: position)
        }
        mouseTracker?.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        mouseTracker?.stop()
    }

    @objc private func screenParametersDidChange(_ notification: Notification) {
        tearDownOverlays()
        buildOverlays()
        // Re-render at current cursor position so crosshair appears immediately
        updateAllOverlays(cursorPosition: NSEvent.mouseLocation)
    }

    private func buildOverlays() {
        for screen in NSScreen.screens {
            let controller = OverlayWindowController(screen: screen)
            controller.window?.orderFrontRegardless()
            overlayControllers.append(controller)
        }
    }

    private func tearDownOverlays() {
        for controller in overlayControllers {
            controller.window?.close()
        }
        overlayControllers.removeAll()
    }

    private func updateAllOverlays(cursorPosition: NSPoint) {
        for controller in overlayControllers {
            controller.updateCursorPosition(cursorPosition)
        }
    }
}
