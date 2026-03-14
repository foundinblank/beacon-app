import SwiftUI

struct SpotlightSettingsSection: View {
    @AppStorage(SettingsKeys.spotlightEnabled) private var enabled = SettingsDefaults.spotlightEnabled
    @AppStorage(SettingsKeys.spotlightRadius) private var radius = SettingsDefaults.spotlightRadius
    @AppStorage(SettingsKeys.spotlightDimOpacity) private var dimOpacity = SettingsDefaults.spotlightDimOpacity
    @AppStorage(SettingsKeys.spotlightBorderWidth) private var borderWidth = SettingsDefaults.spotlightBorderWidth

    var body: some View {
        Section("Spotlight") {
            Toggle("Enable Spotlight", isOn: $enabled)

            if enabled {
                sliderRow("Radius", value: $radius, range: 25...300, step: 5) {
                    "\(Int($0)) px"
                }

                sliderRow("Dim Opacity", value: $dimOpacity, range: 0.0...1.0, step: 0.05) {
                    String(format: "%.0f%%", $0 * 100)
                }

                sliderRow("Border Width", value: $borderWidth, range: 0...10, step: 0.5) {
                    $0 == 0 ? "Off" : String(format: "%.1f px", $0)
                }
            }
        }
    }

    private func sliderRow(
        _ label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        format: @escaping (Double) -> String
    ) -> some View {
        HStack {
            Text(label)
            Slider(value: value, in: range, step: step)
            Text(format(value.wrappedValue))
                .monospacedDigit()
                .frame(width: 50, alignment: .trailing)
        }
    }
}
