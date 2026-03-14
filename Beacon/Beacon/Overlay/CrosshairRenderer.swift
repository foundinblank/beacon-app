import AppKit
import QuartzCore

@MainActor
class CrosshairRenderer {
    private let topLine = CAShapeLayer()
    private let bottomLine = CAShapeLayer()
    private let leftLine = CAShapeLayer()
    private let rightLine = CAShapeLayer()

    private let defaults = UserDefaults.standard
    private nonisolated(unsafe) var settingsObserver: NSObjectProtocol?

    private var gap: CGFloat = 20.0
    private var edgeGap: CGFloat = 0.0

    private var lastDrawnPosition: NSPoint = .zero
    private var lastDrawnBounds: NSRect = .zero
    private var lastColorHex: String = ""
    private var lastThickness: CGFloat = -1
    private var lastLineStyle: String = ""
    private var lastDashLength: CGFloat = -1
    private var lastGapLength: CGFloat = -1

    private lazy var allLines: [CAShapeLayer] = [topLine, bottomLine, leftLine, rightLine]

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
        guard position != lastDrawnPosition || bounds != lastDrawnBounds else { return }
        lastDrawnPosition = position
        lastDrawnBounds = bounds

        let x = position.x
        let y = position.y

        // All lines draw outward from cursor so dash patterns anchor at the cursor

        // Left line: from cursor gap to left edge
        let leftPath = CGMutablePath()
        leftPath.move(to: CGPoint(x: max(edgeGap, x - gap), y: y))
        leftPath.addLine(to: CGPoint(x: edgeGap, y: y))
        leftLine.path = leftPath

        // Right line: from cursor gap to right edge
        let rightPath = CGMutablePath()
        rightPath.move(to: CGPoint(x: x + gap, y: y))
        rightPath.addLine(to: CGPoint(x: bounds.width - edgeGap, y: y))
        rightLine.path = rightPath

        // Bottom line: from cursor gap to bottom edge (y=0 is bottom in CALayer)
        let bottomPath = CGMutablePath()
        bottomPath.move(to: CGPoint(x: x, y: max(edgeGap, y - gap)))
        bottomPath.addLine(to: CGPoint(x: x, y: edgeGap))
        bottomLine.path = bottomPath

        // Top line: from cursor gap to top edge
        let topPath = CGMutablePath()
        topPath.move(to: CGPoint(x: x, y: y + gap))
        topPath.addLine(to: CGPoint(x: x, y: bounds.height - edgeGap))
        topLine.path = topPath
    }

    private func defaultedDouble(forKey key: String, default fallback: Double) -> CGFloat {
        CGFloat(defaults.object(forKey: key) as? Double ?? fallback)
    }

    private func applySettings() {
        let colorHex = defaults.string(forKey: SettingsKeys.crosshairColor) ?? SettingsDefaults.crosshairColor
        let thicknessVal = defaultedDouble(forKey: SettingsKeys.crosshairThickness, default: SettingsDefaults.crosshairThickness)
        let lineStyleRaw = defaults.string(forKey: SettingsKeys.crosshairLineStyle) ?? SettingsDefaults.crosshairLineStyle
        let dashLengthVal = defaultedDouble(forKey: SettingsKeys.crosshairDashLength, default: SettingsDefaults.crosshairDashLength)
        let gapLengthVal = defaultedDouble(forKey: SettingsKeys.crosshairGapLength, default: SettingsDefaults.crosshairGapLength)

        if colorHex == lastColorHex && thicknessVal == lastThickness &&
            lineStyleRaw == lastLineStyle && dashLengthVal == lastDashLength &&
            gapLengthVal == lastGapLength { return }
        lastColorHex = colorHex
        lastThickness = thicknessVal
        lastLineStyle = lineStyleRaw
        lastDashLength = dashLengthVal
        lastGapLength = gapLengthVal

        let color = (NSColor(hex: colorHex) ?? SettingsDefaults.crosshairNSColor).cgColor
        let thickness = thicknessVal
        let lineStyle = LineStyle(rawValue: lineStyleRaw) ?? .solid
        let dashLength = dashLengthVal
        let gapLength = gapLengthVal

        let dashPattern: [NSNumber]?
        let lineCap: CAShapeLayerLineCap
        switch lineStyle {
        case .dashed:
            dashPattern = [NSNumber(value: Double(dashLength)), NSNumber(value: Double(gapLength))]
            lineCap = .butt
        case .dotted:
            dashPattern = [NSNumber(value: 0), NSNumber(value: Double(gapLength))]
            lineCap = .round
        case .solid:
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
