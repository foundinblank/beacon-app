import ApplicationServices

enum AccessibilityPermission {
    /// Returns true if the app is a trusted accessibility client.
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// Prompts the system Accessibility permission dialog if not already trusted.
    /// Returns current trust status.
    @discardableResult
    static func promptIfNeeded() -> Bool {
        // kAXTrustedCheckOptionPrompt is a C global var that Swift 6 considers
        // shared mutable state. Use the known string value directly to avoid the
        // strict-concurrency error while preserving correct runtime behaviour.
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}
