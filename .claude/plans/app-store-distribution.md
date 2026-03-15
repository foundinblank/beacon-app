# Beacon App Store Distribution Readiness Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prepare Beacon for Mac App Store distribution with polished UX, code quality improvements, telemetry, and all Apple requirements met.

**Architecture:** Work progresses in phases — code quality cleanup first (low-risk, no new features), then new features (MetricKit, onboarding, help), then App Store mechanical requirements (sandbox, entitlements, screenshots). Each phase produces a working, shippable app.

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

## Chunk 3: MetricKit Integration

### Task 7: Add MetricKit crash and diagnostic reporting

**Files:**
- Create: `Beacon/Beacon/Utilities/DiagnosticsManager.swift`
- Modify: `Beacon/Beacon/App/AppDelegate.swift`

MetricKit is Apple's first-party diagnostics framework. It collects crash reports, hang diagnostics, and performance metrics from users who opt into "Share with App Developers." No third-party dependencies, no backend, fully privacy-respecting.

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

## Chunk 4: Help Menu & In-App Documentation

### Task 8: Add Help menu to the menu bar

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
- `Cmd+Shift+/` — Ping (center cursor)
- `Cmd+,` — Settings
- `Cmd+Q` — Quit

- [ ] **Step 3: Build, run, and test**

Verify the Help menu items work. Verify About panel shows correct app name and version.

- [ ] **Step 4: Commit**

```bash
git commit -m "feat: add Help menu with keyboard shortcuts and About"
```

---

## Chunk 5: First-Run Onboarding

### Task 9: Create a first-run welcome experience

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
- **Screen 3: Get Started** — Mention `Cmd+Shift+/` for ping, explain the menu bar icon, "Open Settings" button

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

## Chunk 6: App Sandbox & Entitlements

### Task 10: Re-enable App Sandbox

**Files:**
- Modify: `Beacon/Beacon/Resources/Beacon.entitlements`

This is critical for App Store. Currently `com.apple.security.app-sandbox` is set to `false`.

- [ ] **Step 1: Enable the sandbox**

Change `Beacon.entitlements`:
```xml
<key>com.apple.security.app-sandbox</key>
<true/>
```

- [ ] **Step 2: Add required entitlements**

Beacon uses:
- **Accessibility API** (NSEvent monitors, cursor warping) — this works in sandbox without extra entitlements since NSEvent monitors don't require Input Monitoring permission
- **UserDefaults** — works in sandbox by default

No additional entitlements should be needed. If the build or runtime fails, investigate what specific capability is blocked.

- [ ] **Step 3: Build, run, and thoroughly test everything**

Test checklist:
- Crosshair follows cursor across all screens
- Spotlight renders and follows cursor
- Ping (Cmd+Shift+/) centers cursor and shows ripple
- Settings open and save correctly
- Fade timeout works
- Launch at Login still works (may need `SMAppService` adjustment for sandbox)
- Menu bar icon and menu work
- Multi-monitor connect/disconnect

- [ ] **Step 4: Fix any sandbox issues**

Common sandbox issues:
- Launch at Login may need to use `SMAppService` (already available on macOS 13+)
- File access restrictions (shouldn't affect Beacon)

- [ ] **Step 5: Commit**

```bash
git add Beacon/Beacon/Resources/Beacon.entitlements
git commit -m "feat: re-enable App Sandbox for App Store distribution"
```

---

## Chunk 7: App Store Metadata & Submission Prep

### Task 11: Update bundle identifier

**Files:**
- Modify: `Beacon/Beacon.xcodeproj/project.pbxproj`

- [ ] **Step 1: Choose a proper bundle ID**

The current bundle ID is `com.beacon.app`. For App Store, use a domain you own, e.g.:
- `com.yourname.beacon`
- `com.foundinblank.beacon`

Update in Xcode → target → General → Bundle Identifier.

- [ ] **Step 2: Build and verify**

Run: `xcodebuild -project Beacon/Beacon.xcodeproj -scheme Beacon build`

- [ ] **Step 3: Commit**

```bash
git commit -m "chore: update bundle identifier for App Store"
```

---

### Task 12: Add copyright and version info to Info.plist

**Files:**
- Modify: `Beacon/Beacon/Resources/Info.plist`

- [ ] **Step 1: Add copyright notice**

```xml
<key>NSHumanReadableCopyright</key>
<string>Copyright © 2026 Adam Stone. All rights reserved.</string>
```

The marketing version and build number are already set via Xcode build settings and `GENERATE_INFOPLIST_FILE`.

- [ ] **Step 2: Commit**

```bash
git commit -m "chore: add copyright to Info.plist"
```

---

### Task 13: Prepare App Store Connect listing (manual — not code)

These are manual steps done in the browser at [appstoreconnect.apple.com](https://appstoreconnect.apple.com):

- [ ] **Step 1: Enroll in Apple Developer Program ($99/year)**
- [ ] **Step 2: Create App Store Connect record**
  - App name: Beacon
  - Primary language: English
  - Bundle ID: (from Task 11)
  - SKU: beacon-macos
  - Category: Utilities (or Accessibility if available)
  - Price: $0.99 (or Free)
- [ ] **Step 3: Write App Store description**
- [ ] **Step 4: Take screenshots at required resolutions**
  - macOS: 2880×1800 (Retina) or 1280×800
  - Show crosshair, spotlight, ping, and settings
- [ ] **Step 5: Record app preview video (optional, up to 30 seconds)**
- [ ] **Step 6: Write privacy policy** (can be simple — "Beacon collects no user data")
- [ ] **Step 7: Set age rating** (4+, no objectionable content)
- [ ] **Step 8: Add Accessibility permission usage description if prompted**

---

### Task 14: Archive and submit

- [ ] **Step 1: In Xcode, Product → Archive**
- [ ] **Step 2: In Organizer, click "Distribute App" → App Store Connect**
- [ ] **Step 3: Upload and wait for processing (~15 min)**
- [ ] **Step 4: In App Store Connect, select the build and submit for review**
- [ ] **Step 5: Wait for Apple review (typically 24-48 hours)**
- [ ] **Step 6: If rejected, address feedback and resubmit**

---

## Summary of execution order

| Phase | Tasks | Description |
|-------|-------|-------------|
| Code cleanup | 1-5 | Remove dead code, fix a11y, consistency |
| Light mode | 6 | Test and fix rendering in light appearance |
| Telemetry | 7 | MetricKit crash reporting |
| Help & docs | 8 | Help menu with shortcuts |
| Onboarding | 9 | First-run welcome experience |
| Sandbox | 10 | Re-enable App Sandbox, test everything |
| Metadata | 11-12 | Bundle ID, copyright |
| Submission | 13-14 | App Store Connect, archive, submit |

Tasks 1-5 can be parallelized. Tasks 6-9 can be parallelized. Tasks 10-14 are sequential.
