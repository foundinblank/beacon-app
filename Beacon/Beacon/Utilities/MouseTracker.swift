import AppKit

@MainActor
class MouseTracker {
    typealias PositionCallback = @MainActor (NSPoint) -> Void

    private let callback: PositionCallback
    private nonisolated(unsafe) var globalMonitor: Any?
    private nonisolated(unsafe) var localMonitor: Any?
    private nonisolated(unsafe) var trackingTimer: Timer?
    private nonisolated(unsafe) var renderTimer: Timer?
    private var lastPolledPosition: NSPoint = .zero
    private var latestPosition: NSPoint = .zero
    private var lastDeliveredPosition: NSPoint = .zero
    private var hasNewPosition = false

    init(callback: @escaping PositionCallback) {
        self.callback = callback
    }

    func start() {
        let events: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]

        // Fires when another app is active (main thread delivery per Apple docs)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: events) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.storePosition(NSEvent.mouseLocation)
            }
        }

        // Fires when Beacon itself is active (main thread delivery)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: events) { [weak self] event in
            MainActor.assumeIsolated {
                self?.storePosition(NSEvent.mouseLocation)
            }
            return event
        }

        // Fallback polling during modal event tracking (e.g., menu bar open)
        let pollTimer = Timer(timeInterval: 1.0 / 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                let pos = NSEvent.mouseLocation
                guard pos != self?.lastPolledPosition else { return }
                self?.lastPolledPosition = pos
                self?.storePosition(pos)
            }
        }
        RunLoop.main.add(pollTimer, forMode: .eventTracking)
        trackingTimer = pollTimer

        // Render timer coalesces mouse events into one callback per frame (~120 Hz).
        // Multiple mouse events between frames are merged — only the latest position
        // is delivered, eliminating redundant layer updates and keeping rendering smooth.
        let frameTimer = Timer(timeInterval: 1.0 / 120, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.deliverPositionIfNeeded()
            }
        }
        RunLoop.main.add(frameTimer, forMode: .common)
        RunLoop.main.add(frameTimer, forMode: .eventTracking)
        renderTimer = frameTimer
    }

    private func storePosition(_ position: NSPoint) {
        latestPosition = position
        hasNewPosition = true
    }

    private func deliverPositionIfNeeded() {
        guard hasNewPosition, latestPosition != lastDeliveredPosition else { return }
        hasNewPosition = false
        lastDeliveredPosition = latestPosition
        callback(latestPosition)
    }

    func stop() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
        }
        trackingTimer?.invalidate()
        renderTimer?.invalidate()
        trackingTimer = nil
        renderTimer = nil
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
        renderTimer?.invalidate()
    }
}
