import AppKit

enum SettingsKeys {
    static let crosshairColor = "crosshairColor"
    static let crosshairThickness = "crosshairThickness"
    static let crosshairLineStyle = "crosshairLineStyle"
    static let crosshairDashLength = "crosshairDashLength"
    static let crosshairGapLength = "crosshairGapLength"
    static let fadeTimeout = "fadeTimeout"
}

enum SettingsDefaults {
    static let crosshairColor = "#FF0000"
    static let crosshairNSColor: NSColor = NSColor(hex: crosshairColor) ?? .red
    static let crosshairThickness: Double = 2.0
    static let crosshairLineStyle = LineStyle.solid.rawValue
    static let crosshairDashLength: Double = 8.0
    static let crosshairGapLength: Double = 6.0
    static let fadeTimeout: Double = 1.0  // seconds; 0 = disabled
}

enum LineStyle: String {
    case solid, dashed, dotted

    var hasDashParameters: Bool {
        self != .solid
    }
}
