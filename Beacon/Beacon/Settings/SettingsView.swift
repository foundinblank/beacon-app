import SwiftUI

struct SettingsView: View {
    @ScaledMetric(relativeTo: .body) private var settingsWidth: CGFloat = 450

    var body: some View {
        Form {
            CrosshairSettingsSection()
            SpotlightSettingsSection()
            PingSettingsSection()
            GeneralSettingsSection()
        }
        .formStyle(.grouped)
        .scrollBounceBehavior(.basedOnSize)
        .fixedSize(horizontal: false, vertical: true)
        .frame(minWidth: 400, idealWidth: settingsWidth)
    }
}
