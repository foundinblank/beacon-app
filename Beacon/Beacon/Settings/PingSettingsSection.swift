import SwiftUI

struct PingSettingsSection: View {
    @AppStorage(SettingsKeys.pingMode) private var pingMode = SettingsDefaults.pingMode
    @AppStorage(SettingsKeys.rippleColor) private var rippleColorHex = SettingsDefaults.rippleColor
    @AppStorage(SettingsKeys.syncColor) private var syncColor = SettingsDefaults.syncColor

    private var selectedMode: Binding<PingMode> {
        Binding(
            get: { PingMode(rawValue: pingMode) ?? .centerAndRipple },
            set: { pingMode = $0.rawValue }
        )
    }

    var body: some View {
        Section("Ping") {
            Picker("Mode", selection: selectedMode) {
                ForEach(PingMode.allCases, id: \.self) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if selectedMode.wrappedValue != .centerOnly && !syncColor {
                ColorPickerRow(label: "Ripple color", colorHex: $rippleColorHex)
            }
        }
    }
}
