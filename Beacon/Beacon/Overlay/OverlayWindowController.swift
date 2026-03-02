import AppKit

class OverlayWindowController: NSWindowController {
    private let overlayView: OverlayView

    init(screen: NSScreen) {
        let window = NSWindow(
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
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        let view = OverlayView(frame: screen.frame)
        window.contentView = view
        self.overlayView = view

        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateCursorPosition(_ globalPosition: NSPoint) {
        guard let window = window, let screen = window.screen ?? NSScreen.main else { return }
        let localPosition = ScreenUtilities.globalToLocal(globalPosition, in: screen)
        overlayView.updateCursorPosition(localPosition)
    }
}
