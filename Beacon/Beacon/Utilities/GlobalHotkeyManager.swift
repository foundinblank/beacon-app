import AppKit
import Carbon
import os

private let log = Logger(subsystem: "com.beacon.app", category: "hotkey")

@MainActor
class GlobalHotkeyManager {
    typealias Handler = @MainActor () -> Void

    private var hotkeyRef: EventHotKeyRef?
    private let handler: Handler
    private static var instance: GlobalHotkeyManager?

    init(handler: @escaping Handler) {
        self.handler = handler
    }

    func start() {
        GlobalHotkeyManager.instance = self

        // Cmd-Shift-/ (slash is keycode 0x2C)
        let hotkeyID = EventHotKeyID(signature: OSType(0x4243_4E50), // "BCNP" (Beacon Ping)
                                      id: 1)
        let modifiers = UInt32(cmdKey | shiftKey)
        let keyCode = UInt32(kVK_ANSI_Slash)

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                       eventKind: UInt32(kEventHotKeyPressed))

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ -> OSStatus in
                MainActor.assumeIsolated {
                    log.debug("hotkey pressed: Cmd-Shift-/")
                    GlobalHotkeyManager.instance?.handler()
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            nil
        )

        let status = RegisterEventHotKey(keyCode, modifiers, hotkeyID,
                                          GetApplicationEventTarget(), 0, &hotkeyRef)
        if status != noErr {
            log.error("RegisterEventHotKey failed: \(status)")
        } else {
            log.debug("registered global hotkey Cmd-Shift-/")
        }
    }

    func stop() {
        if let ref = hotkeyRef {
            UnregisterEventHotKey(ref)
            hotkeyRef = nil
        }
        GlobalHotkeyManager.instance = nil
    }
}
