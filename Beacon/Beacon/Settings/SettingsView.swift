import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            CrosshairSettingsSection()
            SpotlightSettingsSection()
            GeneralSettingsSection()
        }
        .formStyle(.grouped)
        .frame(width: 450)
    }
}
