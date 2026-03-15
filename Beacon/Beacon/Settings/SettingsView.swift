import SwiftUI

struct SettingsView: View {
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
        .frame(width: 450)
    }
}
