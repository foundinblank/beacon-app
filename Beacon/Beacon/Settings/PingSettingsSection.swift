import SwiftUI

struct PingSettingsSection: View {
    @AppStorage(SettingsKeys.pingMode) private var pingMode = SettingsDefaults.pingMode
    @AppStorage(SettingsKeys.rippleColor) private var rippleColorHex = SettingsDefaults.rippleColor

    private var selectedMode: Binding<PingMode> {
        Binding(
            get: { PingMode(rawValue: pingMode) ?? .centerAndRipple },
            set: { pingMode = $0.rawValue }
        )
    }

    private var rippleColorBinding: Binding<Color> {
        Binding(
            get: {
                Color(nsColor: NSColor(hex: rippleColorHex) ?? SettingsDefaults.rippleNSColor)
            },
            set: { newColor in
                rippleColorHex = NSColor(newColor).hexString
            }
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

            if selectedMode.wrappedValue != .centerOnly {
                ColorPicker(
                    "Ripple Color",
                    selection: rippleColorBinding,
                    supportsOpacity: false
                )
            }
        }
    }
}
