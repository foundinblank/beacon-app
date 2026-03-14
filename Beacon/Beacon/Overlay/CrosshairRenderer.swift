import AppKit
import QuartzCore

class CrosshairRenderer {
    private let topLine = CAShapeLayer()
    private let bottomLine = CAShapeLayer()
    private let leftLine = CAShapeLayer()
    private let rightLine = CAShapeLayer()

    private let defaults = UserDefaults.standard

    private var gap: CGFloat = 20.0
    private var edgeGap: CGFloat = 0.0

    private var allLines: [CAShapeLayer] {
        [topLine, bottomLine, leftLine, rightLine]
    }

    func setup(in layer: CALayer, bounds: NSRect) {
        for line in allLines {
            line.fillColor = nil
            line.actions = [
                "path": NSNull(), "position": NSNull(), "bounds": NSNull(),
                "strokeColor": NSNull(), "lineWidth": NSNull(), "lineDashPattern": NSNull(),
                "lineDashPhase": NSNull(),
            ]
            layer.addSublayer(line)
        }
        applySettings()

        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.applySettings()
        }
    }

    func updatePosition(_ position: NSPoint, bounds: NSRect) {
        let x = position.x
        let y = position.y

        // Left line: from left edge to cursor gap
        let leftPath = CGMutablePath()
        leftPath.move(to: CGPoint(x: edgeGap, y: y))
        leftPath.addLine(to: CGPoint(x: max(edgeGap, x - gap), y: y))
        leftLine.path = leftPath

        // Right line: from cursor gap to right edge
        let rightPath = CGMutablePath()
        rightPath.move(to: CGPoint(x: x + gap, y: y))
        rightPath.addLine(to: CGPoint(x: bounds.width - edgeGap, y: y))
        rightLine.path = rightPath

        // Bottom line: from bottom edge to cursor gap (y=0 is bottom in CALayer)
        let bottomPath = CGMutablePath()
        bottomPath.move(to: CGPoint(x: x, y: edgeGap))
        bottomPath.addLine(to: CGPoint(x: x, y: max(edgeGap, y - gap)))
        bottomLine.path = bottomPath

        // Top line: from cursor gap to top edge
        let topPath = CGMutablePath()
        topPath.move(to: CGPoint(x: x, y: y + gap))
        topPath.addLine(to: CGPoint(x: x, y: bounds.height - edgeGap))
        topLine.path = topPath
    }

    private func applySettings() {
        let colorHex = defaults.string(forKey: SettingsKeys.crosshairColor) ?? SettingsDefaults.crosshairColor
        let color = (NSColor(hex: colorHex) ?? .red).cgColor
        let thickness = CGFloat(defaults.object(forKey: SettingsKeys.crosshairThickness) as? Double ?? SettingsDefaults.crosshairThickness)
        let lineStyle = defaults.string(forKey: SettingsKeys.crosshairLineStyle) ?? SettingsDefaults.crosshairLineStyle
        let dashLength = CGFloat(defaults.object(forKey: SettingsKeys.crosshairDashLength) as? Double ?? SettingsDefaults.crosshairDashLength)
        let gapLength = CGFloat(defaults.object(forKey: SettingsKeys.crosshairGapLength) as? Double ?? SettingsDefaults.crosshairGapLength)

        let dashPattern: [NSNumber]?
        let lineCap: CAShapeLayerLineCap
        switch lineStyle {
        case "dashed":
            dashPattern = [NSNumber(value: Double(dashLength)), NSNumber(value: Double(gapLength))]
            lineCap = .butt
        case "dotted":
            dashPattern = [NSNumber(value: 0), NSNumber(value: Double(gapLength))]
            lineCap = .round
        default:
            dashPattern = nil
            lineCap = .butt
        }

        for line in allLines {
            line.strokeColor = color
            line.lineWidth = thickness
            line.lineDashPattern = dashPattern
            line.lineCap = lineCap
        }
    }
}
