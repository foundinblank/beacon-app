import SwiftUI

struct SpotlightSettingsSection: View {
    @AppStorage(SettingsKeys.spotlightEnabled) private var enabled = SettingsDefaults.spotlightEnabled
    @AppStorage(SettingsKeys.spotlightRadius) private var radius = SettingsDefaults.spotlightRadius
    @AppStorage(SettingsKeys.spotlightDimOpacity) private var dimOpacity = SettingsDefaults.spotlightDimOpacity
    @AppStorage(SettingsKeys.spotlightBorderWidth) private var borderWidth = SettingsDefaults.spotlightBorderWidth
    @AppStorage(SettingsKeys.spotlightBorderColor) private var borderColorHex = SettingsDefaults.spotlightBorderColor
    @AppStorage(SettingsKeys.syncColor) private var syncColor = SettingsDefaults.syncColor

    var body: some View {
        Section("Spotlight") {
            Toggle("Enable spotlight", isOn: $enabled)

            if enabled {
                SliderRow(label: "Radius", value: $radius, range: 25...300, step: 5) {
                    "\(Int($0)) px"
                }

                SliderRow(label: "Dim opacity", value: $dimOpacity, range: 0.0...1.0, step: 0.05) {
                    String(format: "%.0f%%", $0 * 100)
                }

                SliderRow(label: "Border width", value: $borderWidth, range: 0...10, step: 0.5) {
                    $0 == 0 ? "Off" : String(format: "%.1f px", $0)
                }

                if !syncColor && borderWidth > 0 {
                    ColorPickerRow(label: "Border color", colorHex: $borderColorHex)
                }
            }
        }
    }

}
