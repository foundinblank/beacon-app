# Beacon App Store Distribution Readiness Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prepare Beacon for Mac App Store distribution with polished UX, code quality improvements, telemetry, and all Apple requirements met.

**Architecture:** Work progresses in phases — code quality cleanup first (low-risk, no new features), then permissions and sandbox (highest-risk, must validate early assumptions), then new features (MetricKit, onboarding, help), then App Store mechanical requirements (metadata, screenshots). Each phase produces a working, shippable app.

**Tech Stack:** Swift 6, AppKit, SwiftUI, MetricKit, Core Animation, Xcode

---

## Chunk 1: Code Quality Cleanup

These tasks address the post-v1 code quality items from the original spec. Low risk, no user-facing changes (except the tap target fix).

### Task 1: Remove dead `edgeGap` property from CrosshairRenderer

**Files:**
- Modify: `Beacon/Beacon/Overlay/CrosshairRenderer.swift:14-16, 71-90`

- [ ] **Step 1: Remove the `edgeGap` declaration**

In `CrosshairRenderer.swift`, remove line 16:
```swift
private var edgeGap: CGFloat = 0.0
```

- [ ] **Step 2: Simplify path math that references `edgeGap`**

Since `edgeGap` is always 0, replace all references:
- Line 71: `max(edgeGap, x - gap)` → `max(0, x - gap)`
- Line 78: `bounds.width - edgeGap` → `bounds.width`
- Line 84: `max(edgeGap, y - gap)` → `max(0, y - gap)`
- Line 90: `bounds.height - edgeGap` → `bounds.height`

The `max(0, ...)` calls on lines 71/84 can stay — they protect against negative coordinates near screen edges.

- [ ] **Step 3: Build and verify**

Run: `xcodebuild -project Beacon/Beacon.xcodeproj -scheme Beacon build`

- [ ] **Step 4: Commit**

```bash
git add Beacon/Beacon/Overlay/CrosshairRenderer.swift
git commit -m "refactor: remove dead edgeGap property from CrosshairRenderer"
```

---

### Task 2: Fix line style conditional inconsistency in CrosshairSettingsTab

**Files:**
- Modify: `Beacon/Beacon/Settings/CrosshairSettingsTab.swift:35-45`

The dash length slider only shows for `dashed` style, but spacing shows for both `dashed` and `dotted`. For dotted mode, the dash length is irrelevant (dots are zero-width), so the current behavior is actually correct — but the code uses two different conditional patterns which is confusing. Normalize to use `hasDashParameters` consistently and rename the dash length slider to clarify it only applies to dashes.

- [ ] **Step 1: Update the conditional for dash length**

Change line 35 from:
```swift
if lineStyle == LineStyle.dashed.rawValue {
```
to:
```swift
if lineStyle == LineStyle.dashed.rawValue {
```

Actually, this behavior is correct as-is (dotted mode doesn't need a dash length control). Just add a comment explaining why:

```swift
// Dash length only applies to dashed style (dotted uses zero-width points)
if lineStyle == LineStyle.dashed.rawValue {
```

- [ ] **Step 2: Build and verify**

Run: `xcodebuild -project Beacon/Beacon.xcodeproj -scheme Beacon build`

- [ ] **Step 3: Commit**

```bash
git add Beacon/Beacon/Settings/CrosshairSettingsTab.swift
git commit -m "docs: clarify line style conditional in CrosshairSettingsTab"
```

---

### Task 3: Remove unnecessary NSObject inheritance from RippleAnimationManager

**Files:**
- Modify: `Beacon/Beacon/Overlay/RippleAnimationManager.swift:8`

**Pre-check:** Verify the class has no `@objc` methods, is not used as a delegate, and has no `super.init()` calls before proceeding. If any of these exist, skip this task.

- [ ] **Step 1: Remove NSObject superclass**

Change line 8 from:
```swift
class RippleAnimationManager: NSObject {
```
to:
```swift
class RippleAnimationManager {
```

- [ ] **Step 2: Remove any `super.init()` or `override` calls if present**

Check for and remove any `super.init()` calls in initializers.

- [ ] **Step 3: Build and verify**

Run: `xcodebuild -project Beacon/Beacon.xcodeproj -scheme Beacon build`

- [ ] **Step 4: Commit**

```bash
git add Beacon/Beacon/Overlay/RippleAnimationManager.swift
git commit -m "refactor: remove unnecessary NSObject inheritance from RippleAnimationManager"
```

---

### Task 4: Increase color preset tap targets

**Files:**
- Modify: `Beacon/Beacon/Settings/ColorPickerRow.swift:38`

- [ ] **Step 1: Increase circle size from 18 to 24**

Change line 38:
```swift
.frame(width: 18, height: 18)
```
to:
```swift
.frame(width: 24, height: 24)
```

This is an accessibility app — tap targets should exceed Apple's minimum recommendation, especially for users with motor impairments.

- [ ] **Step 2: Build, run, and visually verify the presets look right**

Run: `xcodebuild -project Beacon/Beacon.xcodeproj -scheme Beacon build`

Launch the app and check each settings tab to confirm color presets render correctly at the new size.

- [ ] **Step 3: Commit**

```bash
git add Beacon/Beacon/Settings/ColorPickerRow.swift
git commit -m "fix(a11y): increase color preset tap targets to 24px"
```

---

### Task 5: Add Reduce Transparency support to SpotlightRenderer

**Files:**
- Modify: `Beacon/Beacon/Overlay/SpotlightRenderer.swift`

- [ ] **Step 1: Check `accessibilityDisplayShouldReduceTransparency` when setting dim opacity**

In the method that applies `dimOpacity`, add a check:

```swift
let effectiveOpacity = NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
    ? max(dimOpacity, 0.85) : dimOpacity
```

When Reduce Transparency is on, use a near-opaque dim layer (minimum 85%) so the overlay is clearly visible without relying on transparency effects.

- [ ] **Step 2: Build and verify**

Run: `xcodebuild -project Beacon/Beacon.xcodeproj -scheme Beacon build`

Test with System Settings → Accessibility → Display → Reduce Transparency toggled on/off.

- [ ] **Step 3: Commit**

```bash
git add Beacon/Beacon/Overlay/SpotlightRenderer.swift
git commit -m "feat(a11y): respect Reduce Transparency for spotlight dimming"
```

---

### Task 5b: Fix deprecated `NSApp.activate(ignoringOtherApps:)` call

**Files:**
- Modify: `Beacon/Beacon/App/BeaconApp.swift`

`NSApp.activate(ignoringOtherApps: true)` is deprecated in macOS 14 (Sonoma), which is our minimum target. Replace with `NSApp.activate()`.

- [ ] **Step 1: Replace deprecated calls**

In `BeaconApp.swift`, replace all instances of:
```swift
NSApp.activate(ignoringOtherApps: true)
```
with:
```swift
NSApp.activate()
```

- [ ] **Step 2: Build and verify**

Run: `xcodebuild -project Beacon/Beacon.xcodeproj -scheme Beacon build`

- [ ] **Step 3: Commit**

```bash
git add Beacon/Beacon/App/BeaconApp.swift
git commit -m "fix: replace deprecated NSApp.activate(ignoringOtherApps:)"
```

---

## Chunk 2: Light Mode Testing & Fixes

### Task 6: Test and fix light mode rendering

**Files:**
- Potentially modify: overlay renderers, settings views

This is an exploratory task. The settings UI uses standard SwiftUI semantics that should adapt automatically, but the overlay itself (crosshair lines, spotlight dim, ripple colors) may need contrast adjustments against light backgrounds.

- [ ] **Step 1: Switch to light mode and test all features**

System Settings → Appearance → Light. Test:
- Crosshair visibility against white/light backgrounds (Finder, Safari, Notes)
- Spotlight dim layer contrast
- Ripple animation visibility
- Settings window appearance
- Color picker contrast
- Menu bar icon visibility

- [ ] **Step 2: Document issues found**

Note any contrast or visibility problems.

- [ ] **Step 3: Fix issues (if any)**

Common fixes might include:
- Default crosshair color that works in both modes
- Adjusting spotlight dim opacity defaults
- Ensuring ripple rings have sufficient contrast

- [ ] **Step 4: Build, test again, and commit**

```bash
git commit -m "fix: light mode rendering improvements"
```

---

## Chunk 3: Accessibility Permission & Sandbox Validation

> **Why this is early:** The sandbox and permission model is the highest-risk area. If `CGWarpMouseCursorPosition` or `RegisterEventHotKey` don't work in a sandboxed app, we need to know before investing in onboarding flows and help menus that reference these features.

### Task 7: Add Accessibility permission detection and user guidance

**Files:**
- Create: `Beacon/Beacon/Utilities/AccessibilityPermission.swift`
- Modify: `Beacon/Beacon/App/AppDelegate.swift`
- Modify: `Beacon/Beacon/Resources/Info.plist`

`CGWarpMouseCursorPosition` (used by the ping feature to center the cursor) requires the app to be a trusted accessibility client. Without this permission, cursor warping silently fails. The app must detect this and guide users to grant permission.

- [ ] **Step 1: Add `NSAccessibilityUsageDescription` to Info.plist**

```xml
<key>NSAccessibilityUsageDescription</key>
<string>Beacon needs Accessibility access to move the cursor to the center of the screen when you use the Ping feature.</string>
```

This string is shown in the system permission dialog.

- [ ] **Step 2: Create AccessibilityPermission utility**

Create `Beacon/Beacon/Utilities/AccessibilityPermission.swift`:

```swift
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
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}
```

- [ ] **Step 3: Check permission at launch and on ping**

In `AppDelegate.applicationDidFinishLaunching`, call `AccessibilityPermission.promptIfNeeded()` so users see the system dialog on first launch.

In `performPing()`, before calling `CGWarpMouseCursorPosition`, check `AccessibilityPermission.isTrusted`. If not trusted:
- Log a warning
- Skip the cursor warp (still play the ripple animation so the feature partially works)
- Optionally show a notification or status bar alert directing the user to System Settings

- [ ] **Step 4: Build, run, and test**

Test with Accessibility permission both granted and revoked (System Settings → Privacy & Security → Accessibility). Verify:
- Permission dialog appears on first launch
- Ping works when granted
- Ping degrades gracefully (ripple only, no warp) when not granted

- [ ] **Step 5: Commit**

```bash
git commit -m "feat: add Accessibility permission detection and user guidance"
```

---

### Task 8: Re-enable App Sandbox and validate all features

**Files:**
- Modify: `Beacon/Beacon/Resources/Beacon.entitlements`

This is the highest-risk task. Multiple APIs must be validated under sandbox.

- [ ] **Step 1: Enable the sandbox**

Change `Beacon.entitlements`:
```xml
<key>com.apple.security.app-sandbox</key>
<true/>
```

- [ ] **Step 2: Build and run**

Run: `xcodebuild -project Beacon/Beacon.xcodeproj -scheme Beacon build`

- [ ] **Step 3: Test Carbon `RegisterEventHotKey` under sandbox**

This is the highest-uncertainty item. Carbon's `RegisterEventHotKey` predates App Sandbox and its behavior under sandbox is undocumented.

Test: Press Cmd+0 when Beacon is in the background (another app is focused). Does the ping trigger?

**If it works:** Great, proceed.

**If it fails:** The fallback options are:
1. Use `NSEvent.addGlobalMonitorForEvents(matching: .keyDown)` — but this requires Accessibility permission for keyboard events
2. Drop the global hotkey entirely and rely on the menu bar shortcut (Cmd+0 via MenuBarExtra, which only works when the menu is open)
3. Investigate `CGEventTap` as an alternative — also requires Accessibility permission

Document the outcome regardless.

- [ ] **Step 4: Test `CGWarpMouseCursorPosition` under sandbox**

With Accessibility permission granted, trigger a ping. Does the cursor actually move?

- [ ] **Step 5: Test all other features under sandbox**

Full test checklist:
- Crosshair follows cursor across all screens
- Spotlight renders and follows cursor
- Ping (Cmd+0) centers cursor and shows ripple
- Settings open and save correctly (UserDefaults works in sandbox)
- Fade timeout works
- Launch at Login still works (`SMAppService` is sandbox-compatible)
- Menu bar icon and menu work
- Multi-monitor connect/disconnect
- `NSEvent` global monitor delivers mouse events reliably

- [ ] **Step 6: Fix any sandbox issues**

If `RegisterEventHotKey` fails, implement the chosen fallback and update Task 12 (Help menu) and Task 13 (onboarding) to reflect the correct hotkey behavior.

- [ ] **Step 7: Commit**

```bash
git add Beacon/Beacon/Resources/Beacon.entitlements
git commit -m "feat: re-enable App Sandbox for App Store distribution"
```

---

### Task 9: Add Privacy Manifest (PrivacyInfo.xcprivacy)

**Files:**
- Create: `Beacon/Beacon/Resources/PrivacyInfo.xcprivacy`

Since Spring 2024, Apple requires a privacy manifest for all new App Store submissions. Apps using `UserDefaults` must declare it as a "required reason API." Without this file, the upload is **automatically rejected** before reaching a human reviewer.

- [ ] **Step 1: Create PrivacyInfo.xcprivacy**

Create `Beacon/Beacon/Resources/PrivacyInfo.xcprivacy`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

Note: `CA92.1` is the reason code for "access info from same app group" (the app's own UserDefaults).

- [ ] **Step 2: Add to Xcode project**

Add the file to the Xcode project under Resources. Ensure it's included in the target's "Copy Bundle Resources" build phase.

- [ ] **Step 3: Build and verify**

Run: `xcodebuild -project Beacon/Beacon.xcodeproj -scheme Beacon build`

Verify the file appears in the built app bundle: `find DerivedData -name PrivacyInfo.xcprivacy`

- [ ] **Step 4: Commit**

```bash
git add Beacon/Beacon/Resources/PrivacyInfo.xcprivacy Beacon/Beacon.xcodeproj/project.pbxproj
git commit -m "feat: add privacy manifest for App Store requirement"
```

---

## Chunk 4: MetricKit Integration

### Task 10: Add MetricKit crash and diagnostic reporting

**Files:**
- Create: `Beacon/Beacon/Utilities/DiagnosticsManager.swift`
- Modify: `Beacon/Beacon/App/AppDelegate.swift`

MetricKit is Apple's first-party diagnostics framework. It collects crash reports, hang diagnostics, and performance metrics from users who opt into "Share with App Developers." No third-party dependencies, no backend, fully privacy-respecting.

Note: `DiagnosticsManager` must inherit from `NSObject` because `MXMetricManagerSubscriber` is an Objective-C protocol.

- [ ] **Step 1: Create DiagnosticsManager**

Create `Beacon/Beacon/Utilities/DiagnosticsManager.swift`:

```swift
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

    nonisolated func didReceive(_ payloads: [MXMetricPayload]) {
        // MetricKit delivers daily metric summaries
        // These are automatically available in Xcode Organizer
        // No custom handling needed for basic crash reporting
    }

    nonisolated func didReceive(_ payloads: [MXDiagnosticPayload]) {
        // Crash reports, hang diagnostics, disk write diagnostics
        // Automatically appear in Xcode Organizer when uploaded
        // Log locally for debug builds
        #if DEBUG
        for payload in payloads {
            print("[DiagnosticsManager] Received diagnostic payload: \(payload)")
        }
        #endif
    }
}
```

- [ ] **Step 2: Wire up in AppDelegate**

In `AppDelegate.swift`, in `applicationDidFinishLaunching`:

```swift
DiagnosticsManager.shared.start()
```

Add a property to retain it:
```swift
private let diagnosticsManager = DiagnosticsManager.shared
```

- [ ] **Step 3: Add DiagnosticsManager.swift to the Xcode project**

The new file must be added to the Xcode project's build sources. Either:
- Open Xcode and drag the file into the project navigator under Utilities, or
- Add it via the project.pbxproj (complex, prefer Xcode)

- [ ] **Step 4: Build and verify**

Run: `xcodebuild -project Beacon/Beacon.xcodeproj -scheme Beacon build`

- [ ] **Step 5: Commit**

```bash
git add Beacon/Beacon/Utilities/DiagnosticsManager.swift Beacon/Beacon.xcodeproj/project.pbxproj
git commit -m "feat: add MetricKit crash and diagnostic reporting"
```

---

## Chunk 5: Help Menu & In-App Documentation

### Task 11: Add Help menu to the menu bar

**Files:**
- Modify: `Beacon/Beacon/App/BeaconApp.swift`

- [ ] **Step 1: Add a help section to MenuBarMenuContent**

Add a help section to the menu bar menu above the Quit button:

```swift
Divider()

Button("Keyboard Shortcuts") {
    // Show a small window or popover with shortcuts
}

Button("About Beacon") {
    NSApplication.shared.orderFrontStandardAboutPanel()
}
```

- [ ] **Step 2: Create a keyboard shortcuts reference view**

Create a simple SwiftUI view or alert listing:
- `⌘0` — Ping (center cursor)
- `⌘,` — Settings
- `⌘Q` — Quit

**Important:** The ping hotkey is `⌘0` (Cmd+0), NOT `Cmd+Shift+/`. Verify against `GlobalHotkeyManager.swift` before finalizing.

- [ ] **Step 3: Build, run, and test**

Verify the Help menu items work. Verify About panel shows correct app name and version.

- [ ] **Step 4: Commit**

```bash
git commit -m "feat: add Help menu with keyboard shortcuts and About"
```

---

## Chunk 6: First-Run Onboarding

### Task 12: Create a first-run welcome experience

**Files:**
- Create: `Beacon/Beacon/Settings/OnboardingView.swift`
- Modify: `Beacon/Beacon/App/AppDelegate.swift`
- Modify: `Beacon/Beacon/Settings/SettingsKeys.swift`

For an accessibility app, a first-run walkthrough is important. Users need to understand what features exist and how to activate them. Keep it simple — 2-3 screens max.

- [ ] **Step 1: Add a `hasCompletedOnboarding` key**

In `SettingsKeys.swift`, add:
```swift
static let hasCompletedOnboarding = "hasCompletedOnboarding"
```

Register it as `false` in AppDelegate's defaults registration.

- [ ] **Step 2: Create OnboardingView**

A simple multi-step SwiftUI view:
- **Screen 1: Welcome** — "Beacon helps you find your cursor" + app icon + brief description
- **Screen 2: Features** — Crosshair, Spotlight, Ping with visual examples
- **Screen 3: Accessibility Permission** — Explain why the app needs Accessibility access, with a button to trigger the permission prompt via `AccessibilityPermission.promptIfNeeded()`
- **Screen 4: Get Started** — Mention `⌘0` for ping, explain the menu bar icon, "Open Settings" button

**Important:** The ping hotkey is `⌘0` (Cmd+0). Verify against `GlobalHotkeyManager.swift` before finalizing. If the sandbox testing (Task 8) revealed that the global hotkey doesn't work, adjust the onboarding text to explain that Ping is available from the menu bar.

- [ ] **Step 3: Show onboarding on first launch**

In `AppDelegate.applicationDidFinishLaunching`, check `hasCompletedOnboarding`. If false, open the onboarding window. On completion, set the key to `true`.

- [ ] **Step 4: Build, run, and test**

Reset the key to test: `defaults delete com.beacon.app hasCompletedOnboarding`

Verify the onboarding shows once on first launch, then never again.

- [ ] **Step 5: Commit**

```bash
git commit -m "feat: add first-run onboarding walkthrough"
```

---

## Chunk 7: App Store Metadata & Submission Prep

### Task 13: Update bundle identifier and logger subsystem

**Files:**
- Modify: `Beacon/Beacon.xcodeproj/project.pbxproj`
- Modify: All files with `Logger(subsystem: "com.beacon.app", ...)`

- [ ] **Step 1: Choose a proper bundle ID**

The current bundle ID is `com.beacon.app`. For App Store, use a domain you own, e.g.:
- `com.foundinblank.beacon`

Update in Xcode → target → General → Bundle Identifier.

**Important:** This must be done before creating the App Store Connect record (Task 16).

- [ ] **Step 2: Update logger subsystem strings**

All `Logger` instances use `"com.beacon.app"` as the subsystem. Update these to match the new bundle ID so Console.app filtering works correctly.

- [ ] **Step 3: Build and verify**

Run: `xcodebuild -project Beacon/Beacon.xcodeproj -scheme Beacon build`

- [ ] **Step 4: Commit**

```bash
git commit -m "chore: update bundle identifier and logger subsystem for App Store"
```

---

### Task 14: Add copyright and version info to Info.plist

**Files:**
- Modify: `Beacon/Beacon/Resources/Info.plist`

- [ ] **Step 1: Add copyright notice**

```xml
<key>NSHumanReadableCopyright</key>
<string>Copyright © 2026 Adam Stone. All rights reserved.</string>
```

- [ ] **Step 2: Verify version numbers**

Confirm that `GENERATE_INFOPLIST_FILE = YES` is set in build settings, and that `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` are properly configured. App Store Connect requires proper versioning.

- [ ] **Step 3: Commit**

```bash
git commit -m "chore: add copyright to Info.plist"
```

---

### Task 15: Configure code signing for App Store

**Files:**
- Modify: `Beacon/Beacon.xcodeproj/project.pbxproj`

The project currently has `DEVELOPMENT_TEAM = ""`. You cannot archive for App Store without a valid development team and signing configuration.

- [ ] **Step 1: Set the Development Team**

In Xcode → target → Signing & Capabilities:
- Set Team to your Apple Developer account
- Set Signing Certificate to "Apple Distribution" (for App Store)
- Ensure Provisioning Profile is set to "Automatic"

- [ ] **Step 2: Verify Hardened Runtime is enabled**

Confirm `ENABLE_HARDENED_RUNTIME = YES` in both Debug and Release configurations. This is required for notarization and App Store. (It should already be enabled.)

- [ ] **Step 3: Verify app icon**

Confirm the 1024×1024 icon in `AppIcon.appiconset`:
- Has no transparency (App Store requirement)
- Has no alpha channel issues
- All required sizes are present (16 through 1024)

- [ ] **Step 4: Build archive and verify**

Run: Xcode → Product → Archive. Verify it succeeds without signing errors.

- [ ] **Step 5: Commit**

```bash
git commit -m "chore: configure code signing for App Store distribution"
```

---

### Task 16: Prepare App Store Connect listing (manual — not code)

These are manual steps done in the browser at [appstoreconnect.apple.com](https://appstoreconnect.apple.com):

- [ ] **Step 1: Enroll in Apple Developer Program ($99/year)**
- [ ] **Step 2: Create App Store Connect record**
  - App name: Beacon
  - Primary language: English
  - Bundle ID: (from Task 13)
  - SKU: beacon-macos
  - Category: **Utilities** (there is no "Accessibility" primary category on the Mac App Store)
  - Price: $0.99 (or Free)
- [ ] **Step 3: Write App Store description**
  - Emphasize the accessibility use case
  - Mention key features: crosshair overlay, spotlight mode, ping/center cursor
  - Include relevant accessibility keywords for discoverability
- [ ] **Step 4: Take screenshots at required resolutions**
  - macOS: 2880×1800 (Retina) or 1280×800
  - Show crosshair, spotlight, ping, and settings
- [ ] **Step 5: Record app preview video (optional, up to 30 seconds)**
- [ ] **Step 6: Write privacy policy** (can be simple — "Beacon collects no user data")
- [ ] **Step 7: Set age rating** (4+, no objectionable content)
- [ ] **Step 8: Prepare App Review note**

Write an explanation for the App Review team addressing potentially flagged behaviors:

> "Beacon is an accessibility tool that helps visually impaired users locate their mouse cursor. The app creates transparent overlay windows to render a crosshair, spotlight, and ripple animation at the cursor position. These overlays use ignoresMouseEvents=true so all clicks pass through to underlying apps. The app uses CGWarpMouseCursorPosition to center the cursor on the current screen when the user triggers Ping (⌘0), which requires Accessibility permission — the app prompts for this on first launch and degrades gracefully without it. Similar approved apps include Crosshair Pro on the Mac App Store."

---

### Task 17: Archive and submit

- [ ] **Step 1: Final pre-submission checklist**
  - All features work with App Sandbox enabled
  - Accessibility permission flow works (prompt, grant, deny/degrade)
  - Privacy manifest is present in the app bundle
  - Hardened Runtime is enabled
  - Code signing uses a valid Apple Distribution certificate
  - Bundle ID matches App Store Connect record
  - Version number is correct
  - App icon has no transparency issues
  - Test on a clean macOS install if possible (fresh user account works too)
- [ ] **Step 2: In Xcode, Product → Archive**
- [ ] **Step 3: In Organizer, click "Distribute App" → App Store Connect**
- [ ] **Step 4: Upload and wait for processing (~15 min)**
  - If upload fails due to missing Privacy Manifest or signing issues, fix and re-archive
- [ ] **Step 5: In App Store Connect, select the build and submit for review**
  - Include the App Review note from Task 16
- [ ] **Step 6: Wait for Apple review (typically 24-48 hours)**
- [ ] **Step 7: If rejected, address feedback and resubmit**

Common rejection reasons for this type of app:
- Missing or insufficient Accessibility usage description
- Privacy manifest issues
- Overlay behavior not explained in review notes
- Functionality requires permission not mentioned in description

---

## Summary of execution order

| Phase | Tasks | Description |
|-------|-------|-------------|
| Code cleanup | 1-5b | Remove dead code, fix a11y, fix deprecations |
| Light mode | 6 | Test and fix rendering in light appearance |
| Permissions & sandbox | 7-9 | Accessibility permission flow, sandbox validation, privacy manifest |
| Telemetry | 10 | MetricKit crash reporting |
| Help & docs | 11 | Help menu with shortcuts |
| Onboarding | 12 | First-run welcome experience (depends on sandbox results) |
| Metadata & signing | 13-15 | Bundle ID, copyright, code signing |
| Submission | 16-17 | App Store Connect, archive, submit |

Tasks 1-5b can be parallelized. Task 6 is independent. Tasks 7-9 are the critical path and should be done early — results from Task 8 (sandbox validation) may require changes to Tasks 11 and 12. Tasks 10-12 can be parallelized after sandbox is validated. Tasks 13-17 are sequential.

---

## Red-Team Review Notes

This plan was red-teamed on 2026-03-22. Key risks identified and addressed:

- **CRITICAL:** `CGWarpMouseCursorPosition` requires Accessibility permission — added Task 7 for permission detection and graceful degradation
- **CRITICAL:** Missing Privacy Manifest (`PrivacyInfo.xcprivacy`) — added Task 9; without it, upload is automatically rejected
- **CRITICAL:** Carbon `RegisterEventHotKey` behavior under sandbox is undocumented — Task 8 now includes explicit sandbox testing with fallback plan
- **CRITICAL:** `DEVELOPMENT_TEAM` not configured — added Task 15 for code signing setup
- **HIGH:** Plan referenced wrong hotkey (`Cmd+Shift+/` instead of `⌘0`) in multiple places — corrected throughout
- **HIGH:** "Accessibility" is not a Mac App Store category — corrected to "Utilities" in Task 16
- **HIGH:** Fullscreen overlay windows may trigger App Review scrutiny — added App Review note in Task 16
- **MEDIUM:** `NSApp.activate(ignoringOtherApps:)` deprecated in macOS 14 — added Task 5b
- **MEDIUM:** Logger subsystem should match bundle ID — added to Task 13
- **MEDIUM:** App icon must have no transparency — added verification to Task 15
