import SwiftUI

struct SettingsView: View {
    @ScaledMetric(relativeTo: .body) private var settingsWidth: CGFloat = 450
    @AppStorage(SettingsKeys.selectedSettingsTab) private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsTab()
                .tabItem { Label("General", systemImage: "gearshape") }
                .tag(0)
            CrosshairSettingsTab()
                .tabItem { Label("Crosshair", systemImage: "scope") }
                .tag(1)
            SpotlightSettingsTab()
                .tabItem { Label("Spotlight", systemImage: "circle.circle") }
                .tag(2)
            PingSettingsTab()
                .tabItem { Label("Ping", systemImage: "dot.radiowaves.left.and.right") }
                .tag(3)
        }
        .frame(minWidth: 400, idealWidth: settingsWidth, minHeight: 300, idealHeight: 400)
    }
}
