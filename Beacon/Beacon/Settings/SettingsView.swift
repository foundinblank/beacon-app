import SwiftUI

struct SettingsView: View {
    @ScaledMetric(relativeTo: .body) private var settingsWidth: CGFloat = 450
    @AppStorage(SettingsKeys.selectedSettingsTab) private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            CrosshairSettingsTab()
                .tabItem { Text("Crosshair") }
                .tag(0)
            SpotlightSettingsTab()
                .tabItem { Text("Spotlight") }
                .tag(1)
            PingSettingsTab()
                .tabItem { Text("Ping") }
                .tag(2)
            GeneralSettingsTab()
                .tabItem { Text("General") }
                .tag(3)
        }
        .frame(minWidth: 400, idealWidth: settingsWidth, minHeight: 300, idealHeight: 400)
    }
}
