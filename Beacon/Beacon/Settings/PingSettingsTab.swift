import SwiftUI

struct PingSettingsTab: View {
    @AppStorage(SettingsKeys.pingEnabled) private var enabled = SettingsDefaults.pingEnabled
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
        Form {
            Section("Ping") {
                Toggle("Enable Ping", isOn: $enabled)

                Text("Shortcut: \u{2318}\u{21E7}/")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Picker("Mode", selection: selectedMode) {
                    ForEach(PingMode.allCases, id: \.self) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if syncColor {
                    ColorPickerRow(label: "Ripple color", colorHex: $rippleColorHex)
                        .disabled(syncColor)
                    Text("Color is set in the General tab")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if selectedMode.wrappedValue != .centerOnly {
                    ColorPickerRow(label: "Ripple color", colorHex: $rippleColorHex)
                }
            }
        }
        .formStyle(.grouped)
        .scrollBounceBehavior(.basedOnSize)
    }
}
