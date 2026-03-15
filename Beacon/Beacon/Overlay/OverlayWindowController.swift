import AppKit
import os

private let log = Logger(subsystem: "com.beacon.app", category: "overlay")

@MainActor
private class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

@MainActor
class OverlayWindowController: NSWindowController {
    private let overlayView: OverlayView
    private let ownedScreen: NSScreen

    init(screen: NSScreen) {
        let window = OverlayPanel(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        window.level = .statusBar
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = true
        window.hasShadow = false
        window.hidesOnDeactivate = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        // Hide overlay from VoiceOver — it's visual-only and should not appear as an unlabeled window
        window.setAccessibilityElement(false)
        window.setAccessibilityRole(.unknown)

        let view = OverlayView(frame: NSRect(origin: .zero, size: screen.frame.size))
        view.setAccessibilityElement(false)
        window.contentView = view
        self.overlayView = view
        self.ownedScreen = screen

        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateCursorPosition(_ globalPosition: NSPoint) {
        let screen = ownedScreen
        let cursorOnThisScreen = screen.frame.contains(globalPosition)

        if cursorOnThisScreen {
            overlayView.setVisible(true)
            let localPosition = ScreenUtilities.globalToLocal(globalPosition, in: screen)
            overlayView.updateCursorPosition(localPosition)
        } else {
            overlayView.setVisible(false)
        }
    }

    func fadeOut(duration: CFTimeInterval) {
        overlayView.fadeOut(duration: duration)
    }

    func fadeIn() {
        overlayView.fadeIn()
    }

    func playRipple(at globalPosition: NSPoint) {
        log.debug("playRipple global=\(globalPosition.debugDescription), screen=\(self.ownedScreen.frame.debugDescription), contains=\(self.ownedScreen.frame.contains(globalPosition))")
        guard ownedScreen.frame.contains(globalPosition) else { return }
        let localPosition = ScreenUtilities.globalToLocal(globalPosition, in: ownedScreen)
        log.debug("playing ripple at local=\(localPosition.debugDescription)")
        overlayView.playRipple(at: localPosition)
    }
}
