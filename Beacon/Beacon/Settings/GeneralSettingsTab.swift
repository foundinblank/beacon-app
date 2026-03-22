import os
import ServiceManagement
import SwiftUI

struct GeneralSettingsTab: View {
    @AppStorage(SettingsKeys.syncColor) private var syncColor = SettingsDefaults.syncColor
    @AppStorage(SettingsKeys.masterColor) private var masterColorHex = SettingsDefaults.masterColor
    @AppStorage(SettingsKeys.fadeTimeout) private var fadeTimeout = SettingsDefaults.fadeTimeout
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var requiresApproval = SMAppService.mainApp.status == .requiresApproval

    var body: some View {
        Form {
            Section("General") {
                Toggle("Sync color", isOn: $syncColor)

                ColorPickerRow(label: "Color", colorHex: $masterColorHex,
                               subtitle: syncColor ? nil : "Enable Sync color to set a global color")
                    .disabled(!syncColor)

                SliderRow(label: "Fade after idle", value: $fadeTimeout, range: 0...10, step: 0.5) {
                    $0 == 0 ? "Off" : String(format: "%.1fs", $0)
                }

                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                            requiresApproval = SMAppService.mainApp.status == .requiresApproval
                        } catch {
                            Logger(subsystem: "com.beacon.app", category: "settings")
                                .error("SMAppService registration failed: \(error)")
                            launchAtLogin = !newValue
                        }
                    }
                if requiresApproval {
                    Text("Open System Settings > General > Login Items to approve.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .scrollBounceBehavior(.basedOnSize)
    }
}
