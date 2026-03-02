import AppKit

class MouseTracker {
    typealias PositionCallback = (NSPoint) -> Void

    private let callback: PositionCallback
    private var globalMonitor: Any?
    private var localMonitor: Any?

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
    }

    func stop() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
        }
        globalMonitor = nil
        localMonitor = nil
    }

    deinit {
        stop()
    }
}
