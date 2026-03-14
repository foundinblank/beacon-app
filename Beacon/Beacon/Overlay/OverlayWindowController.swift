import AppKit

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

        let view = OverlayView(frame: NSRect(origin: .zero, size: screen.frame.size))
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
        guard let screen = window?.screen else { return }
        guard screen.frame.contains(globalPosition) else { return }
        let localPosition = ScreenUtilities.globalToLocal(globalPosition, in: screen)
        overlayView.playRipple(at: localPosition)
    }
}
