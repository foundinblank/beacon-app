import AppKit

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var overlayControllers: [OverlayWindowController] = []
    private var mouseTracker: MouseTracker?
    private var capsLockDetector: CapsLockDetector?
    private var fadeTimer: Timer?
    private var isFadedOut = false
    private let defaults = UserDefaults.standard

    func applicationDidFinishLaunching(_ notification: Notification) {
        defaults.register(defaults: [
            SettingsKeys.crosshairColor: SettingsDefaults.crosshairColor,
            SettingsKeys.crosshairThickness: SettingsDefaults.crosshairThickness,
            SettingsKeys.crosshairLineStyle: SettingsDefaults.crosshairLineStyle,
            SettingsKeys.crosshairDashLength: SettingsDefaults.crosshairDashLength,
            SettingsKeys.crosshairGapLength: SettingsDefaults.crosshairGapLength,
            SettingsKeys.fadeTimeout: SettingsDefaults.fadeTimeout,
        ])

        buildOverlays()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        mouseTracker = MouseTracker { [weak self] position in
            self?.handleMouseMove(position)
        }
        mouseTracker?.start()

        capsLockDetector = CapsLockDetector { [weak self] in
            NSLog("Beacon: Caps Lock double-tap detected!")
        }
        capsLockDetector?.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        mouseTracker?.stop()
        capsLockDetector?.stop()
        fadeTimer?.invalidate()
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

    private func handleMouseMove(_ position: NSPoint) {
        if isFadedOut {
            isFadedOut = false
            for controller in overlayControllers {
                controller.fadeIn()
            }
        }
        updateAllOverlays(cursorPosition: position)
        resetFadeTimer()
    }

    private func resetFadeTimer() {
        fadeTimer?.invalidate()
        let timeout = defaults.object(forKey: SettingsKeys.fadeTimeout) as? Double ?? SettingsDefaults.fadeTimeout
        guard timeout > 0 else { return }
        fadeTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.fadeOutOverlays()
            }
        }
    }

    private func fadeOutOverlays() {
        guard !isFadedOut else { return }
        isFadedOut = true
        for controller in overlayControllers {
            controller.fadeOut(duration: 0.5)
        }
    }

    private func updateAllOverlays(cursorPosition: NSPoint) {
        for controller in overlayControllers {
            controller.updateCursorPosition(cursorPosition)
        }
    }
}
