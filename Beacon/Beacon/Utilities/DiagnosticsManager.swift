import MetricKit

@MainActor
final class DiagnosticsManager: NSObject, MXMetricManagerSubscriber {
    static let shared = DiagnosticsManager()

    private override init() {
        super.init()
    }

    func start() {
        MXMetricManager.shared.add(self)
    }

    nonisolated func didReceive(_ payloads: [MXDiagnosticPayload]) {
        // Crash reports, hang diagnostics
        // Automatically appear in Xcode Organizer
        #if DEBUG
        for payload in payloads {
            print("[DiagnosticsManager] Received diagnostic payload: \(payload)")
        }
        #endif
    }
}
