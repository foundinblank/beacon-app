import AppKit

class MouseTracker {
    typealias PositionCallback = (NSPoint) -> Void

    private let callback: PositionCallback
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var trackingTimer: Timer?

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
            self?.callback(NSEvent.mouseLocation)
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
        stop()
    }
}
