import AppKit

enum SettingsKeys {
    static let crosshairColor = "crosshairColor"
    static let crosshairThickness = "crosshairThickness"
    static let crosshairLineStyle = "crosshairLineStyle"
    static let crosshairDashLength = "crosshairDashLength"
    static let crosshairGapLength = "crosshairGapLength"
    static let crosshairEnabled = "crosshairEnabled"
    static let fadeTimeout = "fadeTimeout"
    static let spotlightEnabled = "spotlightEnabled"
    static let spotlightRadius = "spotlightRadius"
    static let spotlightDimOpacity = "spotlightDimOpacity"
    static let spotlightBorderWidth = "spotlightBorderWidth"
    static let pingEnabled = "pingEnabled"
    static let pingMode = "pingMode"
    static let rippleColor = "rippleColor"
    static let rippleLineWidth = "rippleLineWidth"
    static let rippleRadius = "rippleRadius"
    static let spotlightBorderColor = "spotlightBorderColor"
    static let syncColor = "syncColor"
    static let masterColor = "masterColor"
    static let selectedSettingsTab = "selectedSettingsTab"
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
}

enum SettingsDefaults {
    static let crosshairColor = "#FF0000"
    static let crosshairNSColor: NSColor = NSColor(hex: crosshairColor) ?? .red
    static let crosshairThickness: Double = 2.0
    static let crosshairLineStyle = LineStyle.solid.rawValue
    static let crosshairDashLength: Double = 8.0
    static let crosshairGapLength: Double = 6.0
    static let crosshairEnabled = true
    static let fadeTimeout: Double = 1.0  // seconds; 0 = disabled
    static let spotlightEnabled = false
    static let spotlightRadius: Double = 100.0
    static let spotlightDimOpacity: Double = 0.5
    static let spotlightBorderWidth: Double = 2.0
    static let pingEnabled = true
    static let pingMode = PingMode.centerAndRipple.rawValue
    static let rippleColor = "#FF0000"
    static let rippleNSColor: NSColor = NSColor(hex: rippleColor) ?? .red
    static let rippleLineWidth: Double = 2.0
    static let rippleRadius: Double = 150.0
    static let spotlightBorderColor = "#FF0000"
    static let spotlightBorderNSColor: NSColor = NSColor(hex: spotlightBorderColor) ?? .red
    static let syncColor = true
    static let masterColor = "#FF0000"
    static let masterNSColor: NSColor = NSColor(hex: masterColor) ?? .red

    /// Resolves the effective color hex for a feature, respecting the sync-color setting.
    static func resolvedColorHex(featureKey: String, featureDefault: String) -> String {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: SettingsKeys.syncColor) as? Bool ?? syncColor {
            return defaults.string(forKey: SettingsKeys.masterColor) ?? masterColor
        } else {
            return defaults.string(forKey: featureKey) ?? featureDefault
        }
    }
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
