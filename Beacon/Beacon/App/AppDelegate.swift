import AppKit
import os

private let log = Logger(subsystem: "com.foundinblank.beacon", category: "ping")

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var overlayControllers: [OverlayWindowController] = []
    private var mouseTracker: MouseTracker?
    private var hotkeyManager: GlobalHotkeyManager?
    private var fadeTimer: Timer?
    private var ripplePreviewTimer: Timer?
    private var isFadedOut = false
    private let defaults = UserDefaults.standard
    private var settingsObserver: NSObjectProtocol?
    private let diagnosticsManager = DiagnosticsManager.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        // One-time migration: copy crosshairColor → masterColor for existing users
        if defaults.object(forKey: SettingsKeys.masterColor) == nil,
           let existingColor = defaults.string(forKey: SettingsKeys.crosshairColor) {
            defaults.set(existingColor, forKey: SettingsKeys.masterColor)
        }

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
            SettingsKeys.pingEnabled: SettingsDefaults.pingEnabled,
            SettingsKeys.pingMode: SettingsDefaults.pingMode,
            SettingsKeys.rippleColor: SettingsDefaults.rippleColor,
            SettingsKeys.spotlightBorderColor: SettingsDefaults.spotlightBorderColor,
            SettingsKeys.syncColor: SettingsDefaults.syncColor,
            SettingsKeys.masterColor: SettingsDefaults.masterColor,
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

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePreviewRipple),
            name: .previewRipple,
            object: nil
        )

        mouseTracker = MouseTracker { [weak self] position in
            self?.handleMouseMove(position)
        }
        mouseTracker?.start()

        hotkeyManager = GlobalHotkeyManager { [weak self] in
            self?.performPing()
        }
        hotkeyManager?.start()

        DiagnosticsManager.shared.start()
        AccessibilityPermission.promptIfNeeded()
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

    func playRipplePreview() {
        let mouseLocation = NSEvent.mouseLocation
        for controller in overlayControllers {
            controller.playRipple(at: mouseLocation)
        }
    }

    @objc private func handlePreviewRipple() {
        ripplePreviewTimer?.invalidate()
        ripplePreviewTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.playRipplePreview()
            }
        }
    }

    func performPing() {
        log.debug("performPing() called")
        let pingEnabled = defaults.object(forKey: SettingsKeys.pingEnabled) as? Bool ?? SettingsDefaults.pingEnabled
        guard pingEnabled else {
            log.debug("ping disabled, ignoring")
            return
        }
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
            if AccessibilityPermission.isTrusted {
                // Center cursor
                let cgCenter = ScreenUtilities.screenCenter(of: currentScreen)
                let result = CGWarpMouseCursorPosition(cgCenter)
                if result != .success {
                    log.error("CGWarpMouseCursorPosition failed with error \(result.rawValue)")
                }
                targetAppKitPosition = NSPoint(x: currentScreen.frame.midX, y: currentScreen.frame.midY)

                // Update overlays at new position
                updateAllOverlays(cursorPosition: targetAppKitPosition)
            } else {
                log.warning("Accessibility permission not granted — skipping cursor warp, ripple only")
                targetAppKitPosition = mouseLocation
            }
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
