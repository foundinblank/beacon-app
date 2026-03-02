import AppKit

enum ScreenUtilities {
    /// Convert a CoreGraphics point (origin top-left, y down) to AppKit coordinates (origin bottom-left, y up).
    static func cgPointToAppKit(_ cgPoint: CGPoint) -> NSPoint {
        guard let primaryScreen = NSScreen.screens.first else {
            return NSPoint(x: cgPoint.x, y: cgPoint.y)
        }
        let screenHeight = primaryScreen.frame.height
        return NSPoint(x: cgPoint.x, y: screenHeight - cgPoint.y)
    }

    /// Convert an AppKit point (origin bottom-left, y up) to CoreGraphics coordinates (origin top-left, y down).
    static func appKitPointToCG(_ nsPoint: NSPoint) -> CGPoint {
        guard let primaryScreen = NSScreen.screens.first else {
            return CGPoint(x: nsPoint.x, y: nsPoint.y)
        }
        let screenHeight = primaryScreen.frame.height
        return CGPoint(x: nsPoint.x, y: screenHeight - nsPoint.y)
    }

    /// Convert a global AppKit point to local coordinates within a specific screen.
    static func globalToLocal(_ globalPoint: NSPoint, in screen: NSScreen) -> NSPoint {
        return NSPoint(
            x: globalPoint.x - screen.frame.origin.x,
            y: globalPoint.y - screen.frame.origin.y
        )
    }

    /// Return the center of the given screen in CoreGraphics coordinates.
    static func screenCenter(of screen: NSScreen) -> CGPoint {
        let appKitCenter = NSPoint(
            x: screen.frame.midX,
            y: screen.frame.midY
        )
        return appKitPointToCG(appKitCenter)
    }
}
