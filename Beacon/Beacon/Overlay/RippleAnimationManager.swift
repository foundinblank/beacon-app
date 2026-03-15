import AppKit
import os
import QuartzCore

private let log = Logger(subsystem: "com.beacon.app", category: "ripple")

@MainActor
class RippleAnimationManager: NSObject {
    private let ringCount = 3
    private let startRadius: CGFloat = 150
    private let ringDuration: CFTimeInterval = 0.4
    private let stagger: CFTimeInterval = 0.1
    private let lineWidth: CGFloat = 2

    private var rings: [CAShapeLayer] = []
    private let defaults = UserDefaults.standard

    func play(at point: NSPoint, in layer: CALayer) {
        log.debug("play at \(point.debugDescription), layer opacity=\(layer.opacity), bounds=\(layer.bounds.debugDescription)")
        // Remove any in-progress rings
        cleanup()

        let colorHex = defaults.string(forKey: SettingsKeys.rippleColor)
            ?? SettingsDefaults.rippleColor
        let color = (NSColor(hex: colorHex) ?? SettingsDefaults.rippleNSColor).cgColor

        // Respect Reduce Motion: show a static ring briefly instead of animated ripples
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            let ring = CAShapeLayer()
            let radius: CGFloat = 40
            let rect = CGRect(x: point.x - radius, y: point.y - radius,
                              width: radius * 2, height: radius * 2)
            ring.path = CGPath(ellipseIn: rect, transform: nil)
            ring.fillColor = nil
            ring.strokeColor = color
            ring.lineWidth = lineWidth * 2
            ring.opacity = 1
            ring.actions = ["opacity": NSNull()]
            layer.addSublayer(ring)
            rings.append(ring)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.cleanup()
            }
            return
        }

        let now = CACurrentMediaTime()

        for i in 0..<ringCount {
            let ring = CAShapeLayer()
            ring.fillColor = nil
            ring.strokeColor = color
            ring.lineWidth = lineWidth
            ring.opacity = 0 // Final state after animation
            ring.actions = [
                "path": NSNull(),
                "opacity": NSNull(),
            ]
            layer.addSublayer(ring)
            rings.append(ring)

            // Start path (large circle)
            let startRect = CGRect(
                x: point.x - startRadius,
                y: point.y - startRadius,
                width: startRadius * 2,
                height: startRadius * 2
            )
            let startPath = CGPath(ellipseIn: startRect, transform: nil)

            // End path (tiny circle at cursor)
            let endRadius: CGFloat = 2
            let endRect = CGRect(
                x: point.x - endRadius,
                y: point.y - endRadius,
                width: endRadius * 2,
                height: endRadius * 2
            )
            let endPath = CGPath(ellipseIn: endRect, transform: nil)

            // Set final state (post-animation)
            ring.path = endPath
            ring.opacity = 0

            let ringBeginTime = now + CFTimeInterval(i) * stagger

            // Path animation (contract inward)
            let pathAnim = CABasicAnimation(keyPath: "path")
            pathAnim.fromValue = startPath
            pathAnim.toValue = endPath
            pathAnim.duration = ringDuration
            pathAnim.beginTime = ringBeginTime
            pathAnim.fillMode = .backwards
            pathAnim.timingFunction = CAMediaTimingFunction(name: .easeIn)
            pathAnim.isRemovedOnCompletion = true
            ring.add(pathAnim, forKey: "ripple_path")

            // Opacity animation (fade out)
            let opacityAnim = CABasicAnimation(keyPath: "opacity")
            opacityAnim.fromValue = Float(1.0)
            opacityAnim.toValue = Float(0.0)
            opacityAnim.duration = ringDuration
            opacityAnim.beginTime = ringBeginTime
            opacityAnim.fillMode = .backwards
            opacityAnim.isRemovedOnCompletion = true
            ring.add(opacityAnim, forKey: "ripple_opacity")
        }

        // Schedule cleanup after all animations complete
        let totalDuration = CFTimeInterval(ringCount - 1) * stagger + ringDuration + 0.05
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) { [weak self] in
            self?.cleanup()
        }
    }

    func cleanup() {
        for ring in rings {
            ring.removeAllAnimations()
            ring.removeFromSuperlayer()
        }
        rings.removeAll()
    }
}
