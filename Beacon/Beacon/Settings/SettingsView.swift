import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            CrosshairSettingsSection()
            GeneralSettingsSection()
        }
        .formStyle(.grouped)
        .frame(width: 450)
    }
}
