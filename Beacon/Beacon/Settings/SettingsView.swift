import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            CrosshairSettingsSection()
        }
        .formStyle(.grouped)
        .frame(width: 450)
    }
}
