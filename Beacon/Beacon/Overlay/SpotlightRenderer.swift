import AppKit
import QuartzCore

@MainActor
class SpotlightRenderer {
    private let dimLayer = CAShapeLayer()
    private let borderLayer = CAShapeLayer()
    private let defaults = UserDefaults.standard
    private nonisolated(unsafe) var settingsObserver: NSObjectProtocol?

    private var lastDrawnPosition: NSPoint = .zero
    private var lastDrawnBounds: NSRect = .zero
    private var lastEnabled: Bool = false
    private var lastRadius: CGFloat = -1
    private var lastDimOpacity: CGFloat = -1
    private var lastBorderWidth: CGFloat = -1
    private var lastColorHex: String = ""

    func setup(in layer: CALayer, bounds: NSRect) {
        dimLayer.fillRule = .evenOdd
        dimLayer.strokeColor = nil
        dimLayer.actions = [
            "path": NSNull(), "opacity": NSNull(), "hidden": NSNull(),
            "fillColor": NSNull(),
        ]
        layer.addSublayer(dimLayer)

        borderLayer.fillColor = nil
        borderLayer.actions = [
            "path": NSNull(), "hidden": NSNull(), "lineWidth": NSNull(),
            "strokeColor": NSNull(),
        ]
        layer.addSublayer(borderLayer)

        applySettings()

        settingsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: defaults,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.applySettings()
            }
        }
    }

    deinit {
        if let token = settingsObserver {
            NotificationCenter.default.removeObserver(token)
        }
    }

    func updatePosition(_ position: NSPoint, bounds: NSRect) {
        guard !dimLayer.isHidden else { return }
        guard position != lastDrawnPosition || bounds != lastDrawnBounds else { return }
        lastDrawnPosition = position
        lastDrawnBounds = bounds

        let radius = lastRadius

        let ellipseRect = CGRect(
            x: position.x - radius,
            y: position.y - radius,
            width: radius * 2,
            height: radius * 2
        )

        let path = CGMutablePath()
        path.addRect(CGRect(origin: .zero, size: bounds.size))
        path.addEllipse(in: ellipseRect)
        dimLayer.path = path

        let borderPath = CGMutablePath()
        borderPath.addEllipse(in: ellipseRect)
        borderLayer.path = borderPath
    }

    private func applySettings() {
        let enabled = defaults.object(forKey: SettingsKeys.spotlightEnabled) as? Bool
            ?? SettingsDefaults.spotlightEnabled
        let radius = CGFloat(defaults.object(forKey: SettingsKeys.spotlightRadius) as? Double
            ?? SettingsDefaults.spotlightRadius)
        let dimOpacity = CGFloat(defaults.object(forKey: SettingsKeys.spotlightDimOpacity) as? Double
            ?? SettingsDefaults.spotlightDimOpacity)
        let borderWidth = CGFloat(defaults.object(forKey: SettingsKeys.spotlightBorderWidth) as? Double
            ?? SettingsDefaults.spotlightBorderWidth)
        let colorHex = SettingsDefaults.resolvedColorHex(
            featureKey: SettingsKeys.spotlightBorderColor, featureDefault: SettingsDefaults.spotlightBorderColor)

        if enabled == lastEnabled && radius == lastRadius &&
            dimOpacity == lastDimOpacity && borderWidth == lastBorderWidth &&
            colorHex == lastColorHex { return }
        lastEnabled = enabled
        lastRadius = radius
        lastDimOpacity = dimOpacity
        lastBorderWidth = borderWidth
        lastColorHex = colorHex

        dimLayer.isHidden = !enabled
        dimLayer.fillColor = NSColor.black.withAlphaComponent(dimOpacity).cgColor

        // When Increase Contrast is enabled, ensure a visible border even if user set it to 0
        let effectiveBorderWidth = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
            ? max(borderWidth, 2.0) : borderWidth

        borderLayer.isHidden = !enabled || effectiveBorderWidth <= 0
        borderLayer.lineWidth = effectiveBorderWidth
        borderLayer.strokeColor = (NSColor(hex: colorHex) ?? SettingsDefaults.spotlightBorderNSColor).cgColor

        if enabled {
            lastDrawnPosition = .zero
            lastDrawnBounds = .zero
        }
    }
}
