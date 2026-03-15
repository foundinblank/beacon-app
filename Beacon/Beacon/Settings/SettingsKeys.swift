import AppKit

enum SettingsKeys {
    static let crosshairColor = "crosshairColor"
    static let crosshairThickness = "crosshairThickness"
    static let crosshairLineStyle = "crosshairLineStyle"
    static let crosshairDashLength = "crosshairDashLength"
    static let crosshairGapLength = "crosshairGapLength"
    static let fadeTimeout = "fadeTimeout"
    static let spotlightEnabled = "spotlightEnabled"
    static let spotlightRadius = "spotlightRadius"
    static let spotlightDimOpacity = "spotlightDimOpacity"
    static let spotlightBorderWidth = "spotlightBorderWidth"
    static let pingMode = "pingMode"
    static let rippleColor = "rippleColor"
    static let spotlightBorderColor = "spotlightBorderColor"
    static let syncColor = "syncColor"
}

enum SettingsDefaults {
    static let crosshairColor = "#FF0000"
    static let crosshairNSColor: NSColor = NSColor(hex: crosshairColor) ?? .red
    static let crosshairThickness: Double = 2.0
    static let crosshairLineStyle = LineStyle.solid.rawValue
    static let crosshairDashLength: Double = 8.0
    static let crosshairGapLength: Double = 6.0
    static let fadeTimeout: Double = 1.0  // seconds; 0 = disabled
    static let spotlightEnabled = false
    static let spotlightRadius: Double = 100.0
    static let spotlightDimOpacity: Double = 0.5
    static let spotlightBorderWidth: Double = 2.0
    static let pingMode = PingMode.centerAndRipple.rawValue
    static let rippleColor = "#FF0000"
    static let rippleNSColor: NSColor = NSColor(hex: rippleColor) ?? .red
    static let spotlightBorderColor = "#FF0000"
    static let spotlightBorderNSColor: NSColor = NSColor(hex: spotlightBorderColor) ?? .red
    static let syncColor = true
}

enum PingMode: String, CaseIterable, Sendable {
    case centerAndRipple
    case centerOnly
    case rippleOnly

    var label: String {
        switch self {
        case .centerAndRipple: return "Center + Ripple"
        case .centerOnly: return "Center Only"
        case .rippleOnly: return "Ripple Only"
        }
    }
}

enum LineStyle: String {
    case solid, dashed, dotted

    var hasDashParameters: Bool {
        self != .solid
    }
}
