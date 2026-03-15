import AppKit
import os

private let log = Logger(subsystem: "com.beacon.app", category: "ping")

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var overlayControllers: [OverlayWindowController] = []
    private var mouseTracker: MouseTracker?
    private var hotkeyManager: GlobalHotkeyManager?
    private var fadeTimer: Timer?
    private var isFadedOut = false
    private let defaults = UserDefaults.standard
    private var settingsObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        defaults.register(defaults: [
            SettingsKeys.crosshairColor: SettingsDefaults.crosshairColor,
            SettingsKeys.crosshairThickness: SettingsDefaults.crosshairThickness,
            SettingsKeys.crosshairLineStyle: SettingsDefaults.crosshairLineStyle,
            SettingsKeys.crosshairDashLength: SettingsDefaults.crosshairDashLength,
            SettingsKeys.crosshairGapLength: SettingsDefaults.crosshairGapLength,
            SettingsKeys.crosshairEnabled: SettingsDefaults.crosshairEnabled,
            SettingsKeys.fadeTimeout: SettingsDefaults.fadeTimeout,
            SettingsKeys.spotlightEnabled: SettingsDefaults.spotlightEnabled,
            SettingsKeys.spotlightRadius: SettingsDefaults.spotlightRadius,
            SettingsKeys.spotlightDimOpacity: SettingsDefaults.spotlightDimOpacity,
            SettingsKeys.spotlightBorderWidth: SettingsDefaults.spotlightBorderWidth,
            SettingsKeys.pingMode: SettingsDefaults.pingMode,
            SettingsKeys.rippleColor: SettingsDefaults.rippleColor,
            SettingsKeys.spotlightBorderColor: SettingsDefaults.spotlightBorderColor,
            SettingsKeys.syncColor: SettingsDefaults.syncColor,
        ])

        buildOverlays()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        settingsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: defaults,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.updateAllOverlays(cursorPosition: NSEvent.mouseLocation)
            }
        }

        mouseTracker = MouseTracker { [weak self] position in
            self?.handleMouseMove(position)
        }
        mouseTracker?.start()

        hotkeyManager = GlobalHotkeyManager { [weak self] in
            self?.performPing()
        }
        hotkeyManager?.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        mouseTracker?.stop()
        hotkeyManager?.stop()
        fadeTimer?.invalidate()
        if let token = settingsObserver {
            NotificationCenter.default.removeObserver(token)
        }
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

    func performPing() {
        log.debug("performPing() called")
        let modeRaw = defaults.string(forKey: SettingsKeys.pingMode) ?? SettingsDefaults.pingMode
        let mode = PingMode(rawValue: modeRaw) ?? .centerAndRipple
        log.debug("ping mode = \(mode.rawValue)")

        // Determine current screen
        let mouseLocation = NSEvent.mouseLocation
        guard let currentScreen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) })
            ?? NSScreen.main else {
            log.error("performPing: no screens available")
            return
        }

        // Restore visibility if faded out
        if isFadedOut {
            isFadedOut = false
            for controller in overlayControllers {
                controller.fadeIn()
            }
        }
        resetFadeTimer()

        // Determine target position
        var targetAppKitPosition: NSPoint

        if mode == .rippleOnly {
            targetAppKitPosition = mouseLocation
        } else {
            // Center cursor
            let cgCenter = ScreenUtilities.screenCenter(of: currentScreen)
            let result = CGWarpMouseCursorPosition(cgCenter)
            if result != .success {
                log.error("CGWarpMouseCursorPosition failed with error \(result.rawValue)")
            }
            targetAppKitPosition = NSPoint(x: currentScreen.frame.midX, y: currentScreen.frame.midY)

            // Update overlays at new position
            updateAllOverlays(cursorPosition: targetAppKitPosition)
        }

        // Play ripple if mode includes it
        if mode != .centerOnly {
            for controller in overlayControllers {
                controller.playRipple(at: targetAppKitPosition)
            }
        }

        // VoiceOver announcement
        let announcement = mode == .rippleOnly ? "Ping" : "Cursor centered"
        NSAccessibility.post(
            element: NSApp as Any,
            notification: .announcementRequested,
            userInfo: [
                .announcement: announcement,
                .priority: NSAccessibilityPriorityLevel.high.rawValue,
            ]
        )
    }
}
