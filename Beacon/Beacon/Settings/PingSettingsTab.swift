import SwiftUI

struct PingSettingsTab: View {
    @AppStorage(SettingsKeys.pingEnabled) private var enabled = SettingsDefaults.pingEnabled
    @AppStorage(SettingsKeys.pingMode) private var pingMode = SettingsDefaults.pingMode
    @AppStorage(SettingsKeys.rippleColor) private var rippleColorHex = SettingsDefaults.rippleColor
    @AppStorage(SettingsKeys.rippleLineWidth) private var rippleLineWidth = SettingsDefaults.rippleLineWidth
    @AppStorage(SettingsKeys.rippleRadius) private var rippleRadius = SettingsDefaults.rippleRadius
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

                if syncColor || selectedMode.wrappedValue != .centerOnly {
                    ColorPickerRow(label: "Ripple color", colorHex: $rippleColorHex,
                                   subtitle: syncColor ? "Color is synced from the General tab" : nil)
                        .disabled(syncColor)
                }

                Picker("Mode", selection: selectedMode) {
                    ForEach(PingMode.allCases, id: \.self) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if selectedMode.wrappedValue != .centerOnly {
                    SliderRow(label: "Line thickness", value: $rippleLineWidth, range: 0.5...10, step: 0.5) {
                        String(format: "%.1f px", $0)
                    }
                    .onChange(of: rippleLineWidth) {
                        NotificationCenter.default.post(name: .previewRipple, object: nil)
                    }

                    SliderRow(label: "Radius", value: $rippleRadius, range: 25...300, step: 5) {
                        "\(Int($0)) px"
                    }
                    .onChange(of: rippleRadius) {
                        NotificationCenter.default.post(name: .previewRipple, object: nil)
                    }
                }

                Text("Shortcut: \u{2318}0")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .scrollBounceBehavior(.basedOnSize)
    }
}

extension Notification.Name {
    static let previewRipple = Notification.Name("previewRipple")
}
