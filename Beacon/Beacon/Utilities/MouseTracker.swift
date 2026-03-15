import AppKit

@MainActor
class MouseTracker {
    typealias PositionCallback = @MainActor (NSPoint) -> Void

    private let callback: PositionCallback
    private nonisolated(unsafe) var globalMonitor: Any?
    private nonisolated(unsafe) var localMonitor: Any?
    private nonisolated(unsafe) var trackingTimer: Timer?
    private var lastPolledPosition: NSPoint = .zero

    init(callback: @escaping PositionCallback) {
        self.callback = callback
    }

    func start() {
        let events: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]

        // Fires when another app is active (main thread delivery per Apple docs)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: events) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.callback(NSEvent.mouseLocation)
            }
        }

        // Fires when Beacon itself is active (main thread delivery)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: events) { [weak self] event in
            MainActor.assumeIsolated {
                self?.callback(NSEvent.mouseLocation)
            }
            return event
        }

        // Fallback polling during modal event tracking (e.g., menu bar open)
        let timer = Timer(timeInterval: 1.0 / 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                let pos = NSEvent.mouseLocation
                guard pos != self?.lastPolledPosition else { return }
                self?.lastPolledPosition = pos
                self?.callback(pos)
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
