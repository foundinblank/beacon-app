import SwiftUI

struct GeneralSettingsSection: View {
    @AppStorage(SettingsKeys.fadeTimeout) private var fadeTimeout = SettingsDefaults.fadeTimeout

    var body: some View {
        Section("General") {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Fade after idle")
                    Spacer()
                    Text(fadeTimeout == 0 ? "Off" : String(format: "%.1fs", fadeTimeout))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $fadeTimeout, in: 0...10, step: 0.5)
            }
        }
    }
}
