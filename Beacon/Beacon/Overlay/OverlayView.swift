import AppKit
import QuartzCore

@MainActor
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

    func setVisible(_ visible: Bool) {
        let newAlpha: Float = visible ? 1 : 0
        guard layer?.opacity != newAlpha else { return }
        layer?.opacity = newAlpha
    }

    func fadeOut(duration: CFTimeInterval) {
        guard let layer = layer, layer.opacity != 0 else { return }
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = layer.opacity
        animation.toValue = Float(0)
        animation.duration = duration
        layer.add(animation, forKey: "fadeOut")
        layer.opacity = 0
    }

    func fadeIn() {
        guard let layer = layer, layer.opacity != 1 else { return }
        layer.removeAnimation(forKey: "fadeOut")
        layer.opacity = 1
    }
}
