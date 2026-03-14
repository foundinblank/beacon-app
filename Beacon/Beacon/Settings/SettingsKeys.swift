import Foundation

enum SettingsKeys {
    static let crosshairColor = "crosshairColor"
    static let crosshairThickness = "crosshairThickness"
    static let crosshairLineStyle = "crosshairLineStyle"
    static let crosshairDashLength = "crosshairDashLength"
    static let crosshairGapLength = "crosshairGapLength"
}

enum SettingsDefaults {
    static let crosshairColor = "#FF0000"
    static let crosshairThickness: Double = 2.0
    static let crosshairLineStyle = "solid"
    static let crosshairDashLength: Double = 8.0
    static let crosshairGapLength: Double = 6.0
}
