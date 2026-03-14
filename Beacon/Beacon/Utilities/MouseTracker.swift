import AppKit

@MainActor
class MouseTracker {
    typealias PositionCallback = @MainActor (NSPoint) -> Void

    private let callback: PositionCallback
    private nonisolated(unsafe) var globalMonitor: Any?
    private nonisolated(unsafe) var localMonitor: Any?
    private nonisolated(unsafe) var trackingTimer: Timer?

    init(callback: @escaping PositionCallback) {
        self.callback = callback
    }

    func start() {
        let events: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]

        // Fires when another app is active
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: events) { [weak self] event in
            self?.callback(NSEvent.mouseLocation)
        }

        // Fires when Beacon itself is active
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: events) { [weak self] event in
            self?.callback(NSEvent.mouseLocation)
            return event
        }

        // Fallback polling during modal event tracking (e.g., menu bar open)
        let timer = Timer(timeInterval: 1.0 / 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.callback(NSEvent.mouseLocation)
            }
        }
        RunLoop.main.add(timer, forMode: .eventTracking)
        trackingTimer = timer
    }

    func stop() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
        }
        trackingTimer?.invalidate()
        trackingTimer = nil
        globalMonitor = nil
        localMonitor = nil
    }

    deinit {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
        }
        trackingTimer?.invalidate()
    }
}
