import SwiftUI

struct CrosshairSettingsTab: View {
    @AppStorage(SettingsKeys.crosshairEnabled) private var enabled = SettingsDefaults.crosshairEnabled
    @AppStorage(SettingsKeys.crosshairColor) private var colorHex = SettingsDefaults.crosshairColor
    @AppStorage(SettingsKeys.syncColor) private var syncColor = SettingsDefaults.syncColor
    @AppStorage(SettingsKeys.crosshairThickness) private var thickness = SettingsDefaults.crosshairThickness
    @AppStorage(SettingsKeys.crosshairLineStyle) private var lineStyle = SettingsDefaults.crosshairLineStyle
    @AppStorage(SettingsKeys.crosshairDashLength) private var dashLength = SettingsDefaults.crosshairDashLength
    @AppStorage(SettingsKeys.crosshairGapLength) private var gapLength = SettingsDefaults.crosshairGapLength

    var body: some View {
        Form {
            Section("Crosshair") {
                Toggle("Enable Crosshair", isOn: $enabled)

                ColorPickerRow(label: "Line color", colorHex: $colorHex,
                               subtitle: syncColor ? "Color is synced from the General tab" : nil)
                    .disabled(syncColor)

                Picker("Line style", selection: $lineStyle) {
                    Text("Solid").tag(LineStyle.solid.rawValue)
                    Text("Dashed").tag(LineStyle.dashed.rawValue)
                    Text("Dotted").tag(LineStyle.dotted.rawValue)
                }

                SliderRow(label: "Line thickness", value: $thickness, range: 0.5...10, step: 0.5) {
                    String(format: "%.1f px", $0)
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
        .formStyle(.grouped)
        .scrollBounceBehavior(.basedOnSize)
    }
}
