import AppKit
import IOKit
import IOKit.hid
import os

private let log = Logger(subsystem: "com.beacon.app", category: "capslock")

@MainActor
class CapsLockDetector {
    typealias PingCallback = @MainActor () -> Void

    private let callback: PingCallback
    private let threshold: TimeInterval = 0.4
    private var lastTapTime: TimeInterval = 0
    private var lastCapsState: Bool = false
    private var resetting = false
    private nonisolated(unsafe) var globalMonitor: Any?
    private nonisolated(unsafe) var localMonitor: Any?

    init(callback: @escaping PingCallback) {
        self.callback = callback
        self.lastCapsState = NSEvent.modifierFlags.contains(.capsLock)
    }

    func start() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            MainActor.assumeIsolated {
                self?.handleFlagsChanged(event)
            }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            MainActor.assumeIsolated {
                self?.handleFlagsChanged(event)
            }
            return event
        }
    }

    func stop() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        let capsIsOn = event.modifierFlags.contains(.capsLock)

        // Ignore if caps lock state didn't actually change (some other modifier fired)
        guard capsIsOn != lastCapsState else { return }
        lastCapsState = capsIsOn

        // Ignore synthetic events from our own resetCapsLock()
        guard !resetting else { return }

        // Each physical press toggles state (on→off or off→on).
        // Count any toggle as a tap for double-tap detection.
        let now = ProcessInfo.processInfo.systemUptime
        let elapsed = now - lastTapTime
        log.debug("caps tap: capsIsOn=\(capsIsOn), elapsed=\(elapsed, format: .fixed(precision: 3))s")

        if elapsed < threshold && lastTapTime > 0 {
            log.debug("double-tap detected, firing callback")
            lastTapTime = 0 // Reset to prevent triple-tap re-trigger
            resetting = true
            resetCapsLock()
            resetting = false
            callback()
        } else {
            lastTapTime = now
        }
    }

    private func resetCapsLock() {
        // Try IOKit approach first (no permissions needed)
        if resetCapsLockViaIOKit() { return }
        // Fallback: synthetic CGEvent (may need Input Monitoring permission)
        resetCapsLockViaCGEvent()
    }

    private func resetCapsLockViaIOKit() -> Bool {
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching(kIOHIDSystemClass)
        )
        guard service != IO_OBJECT_NULL else { return false }
        defer { IOObjectRelease(service) }

        var connect: io_connect_t = IO_OBJECT_NULL
        let kr = IOServiceOpen(service, mach_task_self_, UInt32(kIOHIDParamConnectType), &connect)
        guard kr == KERN_SUCCESS, connect != IO_OBJECT_NULL else { return false }
        defer { IOServiceClose(connect) }

        // Selector 6 = kIOHIDSetModifierLockState, param 1 = capsLock(1), param 2 = state(0=off)
        let input: [UInt64] = [UInt64(kIOHIDCapsLockState), 0]
        let result = IOConnectCallScalarMethod(connect, 6, input, 2, nil, nil)
        return result == KERN_SUCCESS
    }

    private func resetCapsLockViaCGEvent() {
        guard let src = CGEventSource(stateID: .hidSystemState) else { return }
        let keyDown = CGEvent(keyboardEventSource: src, virtualKey: 0x39, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: src, virtualKey: 0x39, keyDown: false)
        keyDown?.flags = []
        keyUp?.flags = []
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}

private let kIOHIDCapsLockState: UInt64 = 1
