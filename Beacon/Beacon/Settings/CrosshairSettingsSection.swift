import SwiftUI

struct CrosshairSettingsSection: View {
    @AppStorage(SettingsKeys.crosshairColor) private var colorHex = SettingsDefaults.crosshairColor
    @AppStorage(SettingsKeys.syncColor) private var syncColor = SettingsDefaults.syncColor
    @AppStorage(SettingsKeys.rippleColor) private var rippleColorHex = SettingsDefaults.rippleColor
    @AppStorage(SettingsKeys.spotlightBorderColor) private var spotlightBorderColorHex = SettingsDefaults.spotlightBorderColor
    @AppStorage(SettingsKeys.crosshairThickness) private var thickness = SettingsDefaults.crosshairThickness
    @AppStorage(SettingsKeys.crosshairLineStyle) private var lineStyle = SettingsDefaults.crosshairLineStyle
    @AppStorage(SettingsKeys.crosshairDashLength) private var dashLength = SettingsDefaults.crosshairDashLength
    @AppStorage(SettingsKeys.crosshairGapLength) private var gapLength = SettingsDefaults.crosshairGapLength

    var body: some View {
        Section("Crosshair") {
            ColorPickerRow(label: "Color", colorHex: $colorHex)

            Toggle("Sync color", isOn: $syncColor)
                .onChange(of: syncColor) { _, newValue in
                    if newValue {
                        rippleColorHex = colorHex
                        spotlightBorderColorHex = colorHex
                    }
                }
                .onChange(of: colorHex) { _, newValue in
                    if syncColor {
                        rippleColorHex = newValue
                        spotlightBorderColorHex = newValue
                    }
                }

            SliderRow(label: "Line thickness", value: $thickness, range: 0.5...10, step: 0.5) {
                String(format: "%.1f px", $0)
            }

            Picker("Line style", selection: $lineStyle) {
                Text("Solid").tag(LineStyle.solid.rawValue)
                Text("Dashed").tag(LineStyle.dashed.rawValue)
                Text("Dotted").tag(LineStyle.dotted.rawValue)
            }

            if lineStyle == LineStyle.dashed.rawValue {
                SliderRow(label: "Dash length", value: $dashLength, range: 1...20, step: 1) {
                    "\(Int($0)) px"
                }
            }

            if (LineStyle(rawValue: lineStyle) ?? .solid).hasDashParameters {
                SliderRow(label: "Spacing", value: $gapLength, range: 1...20, step: 1) {
                    "\(Int($0)) px"
                }
            }
        }
    }

}
