import AppKit
import QuartzCore

class OverlayView: NSView {
    private let crosshairRenderer = CrosshairRenderer()

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        guard let layer = self.layer else { return }
        layer.backgroundColor = NSColor.clear.cgColor
        crosshairRenderer.setup(in: layer, bounds: frame)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateCursorPosition(_ position: NSPoint) {
        crosshairRenderer.updatePosition(position, bounds: bounds)
    }
}
