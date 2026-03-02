import AppKit
import QuartzCore

class CrosshairRenderer {
    private let topLine = CAShapeLayer()
    private let bottomLine = CAShapeLayer()
    private let leftLine = CAShapeLayer()
    private let rightLine = CAShapeLayer()

    private var color: CGColor = NSColor.red.cgColor
    private var thickness: CGFloat = 2.0
    private var gap: CGFloat = 20.0
    private var edgeGap: CGFloat = 0.0

    private var allLines: [CAShapeLayer] {
        [topLine, bottomLine, leftLine, rightLine]
    }

    func setup(in layer: CALayer, bounds: NSRect) {
        for line in allLines {
            line.strokeColor = color
            line.lineWidth = thickness
            line.fillColor = nil
            line.actions = ["path": NSNull(), "position": NSNull(), "bounds": NSNull()]
            layer.addSublayer(line)
        }
    }

    func updatePosition(_ position: NSPoint, bounds: NSRect) {
        let x = position.x
        let y = bounds.height - position.y // flip to layer coords (origin top-left)

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

        // Top line: from top edge to cursor gap (in layer coords, top = 0)
        let topPath = CGMutablePath()
        topPath.move(to: CGPoint(x: x, y: edgeGap))
        topPath.addLine(to: CGPoint(x: x, y: max(edgeGap, y - gap)))
        topLine.path = topPath

        // Bottom line: from cursor gap to bottom edge
        let bottomPath = CGMutablePath()
        bottomPath.move(to: CGPoint(x: x, y: y + gap))
        bottomPath.addLine(to: CGPoint(x: x, y: bounds.height - edgeGap))
        bottomLine.path = bottomPath
    }
}
