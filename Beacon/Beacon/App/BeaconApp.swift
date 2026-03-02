import SwiftUI

@main
struct BeaconApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            Text("Beacon Settings")
                .frame(width: 300, height: 200)
        }
    }
}
