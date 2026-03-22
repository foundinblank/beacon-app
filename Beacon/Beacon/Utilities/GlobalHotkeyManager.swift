import AppKit
import Carbon
import os

private let log = Logger(subsystem: "com.foundinblank.beacon", category: "hotkey")

@MainActor
class GlobalHotkeyManager {
    typealias Handler = @MainActor () -> Void

    private var hotkeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private let handler: Handler
    private static var instance: GlobalHotkeyManager?

    init(handler: @escaping Handler) {
        self.handler = handler
    }

    func start() {
        GlobalHotkeyManager.instance = self

        // Cmd-0 (zero is keycode kVK_ANSI_0)
        let hotkeyID = EventHotKeyID(signature: OSType(0x4243_4E50), // "BCNP" (Beacon Ping)
                                      id: 1)
        let modifiers = UInt32(cmdKey)
        let keyCode = UInt32(kVK_ANSI_0)

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                       eventKind: UInt32(kEventHotKeyPressed))

        var handlerRef: EventHandlerRef?
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ -> OSStatus in
                Task { @MainActor in
                    log.debug("hotkey pressed: Cmd-0")
                    GlobalHotkeyManager.instance?.handler()
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            &handlerRef
        )
        eventHandlerRef = handlerRef

        let status = RegisterEventHotKey(keyCode, modifiers, hotkeyID,
                                          GetApplicationEventTarget(), 0, &hotkeyRef)
        if status != noErr {
            log.error("RegisterEventHotKey failed: \(status)")
        } else {
            log.debug("registered global hotkey Cmd-0")
        }
    }

    func stop() {
        if let ref = hotkeyRef {
            UnregisterEventHotKey(ref)
            hotkeyRef = nil
        }
        if let ref = eventHandlerRef {
            RemoveEventHandler(ref)
            eventHandlerRef = nil
        }
        GlobalHotkeyManager.instance = nil
    }
}
