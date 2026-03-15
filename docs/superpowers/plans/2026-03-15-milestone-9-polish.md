# Milestone 9: Polish + Edge Cases — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Final polish for Beacon v1 — menu bar icon, app icon, crosshair toggle, overlay redraw on settings change, and Launch at Login.

**Architecture:** All changes follow the existing patterns: `@AppStorage` in SwiftUI, `UserDefaults.standard` in AppKit renderers, `isHidden` for feature toggles, `UserDefaults.didChangeNotification` for reactivity.

**Tech Stack:** Swift 6, AppKit (overlay), SwiftUI (settings/menu), ServiceManagement (launch at login), Core Animation (CAShapeLayer)

**Spec:** `docs/superpowers/specs/2026-03-15-milestone-9-polish-design.md`

---

## Chunk 1: Menu Bar Icon + Crosshair Toggle + Overlay Redraw

### Task 1: Change menu bar icon from "target" to "scope"

**Files:**

- Modify: `Beacon/Beacon/App/BeaconApp.swift:50`

- [ ] **Step 1: Change the SF Symbol**

In `BeaconApp.swift` line 50, change `"target"` to `"scope"`:

```swift
        MenuBarExtra("Beacon", systemImage: "scope") {
```

- [ ] **Step 2: Build**

Run: `xcodebuild -project Beacon/Beacon.xcodeproj -scheme Beacon build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Beacon/Beacon/App/BeaconApp.swift
git commit -m "feat(menu-bar): change icon from target to scope"
```

---

### Task 2: Add crosshairEnabled to SettingsKeys and defaults registration

**Files:**

- Modify: `Beacon/Beacon/Settings/SettingsKeys.swift:9` (after crosshairGapLength)
- Modify: `Beacon/Beacon/App/AppDelegate.swift:16-31` (defaults.register block)

- [ ] **Step 1: Add key and default to SettingsKeys.swift**

In `SettingsKeys.swift`, add after line 8 (`crosshairGapLength`):

```swift
    static let crosshairEnabled = "crosshairEnabled"
```

In `SettingsDefaults`, add after line 26 (`crosshairGapLength`):

```swift
    static let crosshairEnabled = true
```

- [ ] **Step 2: Register the default in AppDelegate**

In `AppDelegate.swift`, add to the `defaults.register(defaults:)` dictionary (after the `crosshairGapLength` entry, around line 22):

```swift
            SettingsKeys.crosshairEnabled: SettingsDefaults.crosshairEnabled,
```

- [ ] **Step 3: Build**

Run: `xcodebuild -project Beacon/Beacon.xcodeproj -scheme Beacon build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add Beacon/Beacon/Settings/SettingsKeys.swift Beacon/Beacon/App/AppDelegate.swift
git commit -m "feat(settings): add crosshairEnabled key and default"
```

---

### Task 3: CrosshairRenderer respects crosshairEnabled

**Files:**

- Modify: `Beacon/Beacon/Overlay/CrosshairRenderer.swift`

The pattern to follow is `SpotlightRenderer.applySettings()` (lines 79-113 of SpotlightRenderer.swift) which uses `dimLayer.isHidden = !enabled` and `borderLayer.isHidden = !enabled`.

- [ ] **Step 1: Add enabled cache and isHidden logic**

In `CrosshairRenderer.swift`, add a cache field after line 24 (`lastGapLength`):

```swift
    private var lastEnabled: Bool = true
```

In `applySettings()`, at the top of the method (after line 96, before the existing settings reads), add:

```swift
        let enabled = defaults.object(forKey: SettingsKeys.crosshairEnabled) as? Bool
            ?? SettingsDefaults.crosshairEnabled
```

Add `enabled` to the existing cache comparison check (lines 103-110). The full block from the if-check through all cache assignments becomes:

```swift
        if enabled == lastEnabled && colorHex == lastColorHex && thicknessVal == lastThickness &&
            lineStyleRaw == lastLineStyle && dashLengthVal == lastDashLength &&
            gapLengthVal == lastGapLength { return }
        lastEnabled = enabled
        lastColorHex = colorHex
        lastThickness = thicknessVal
        lastLineStyle = lineStyleRaw
        lastDashLength = dashLengthVal
        lastGapLength = gapLengthVal
```

Immediately after the cache assignments, add:

```swift
        for line in allLines {
            line.isHidden = !enabled
        }
        guard enabled else { return }
```

- [ ] **Step 2: Guard updatePosition when disabled**

In `updatePosition(_:bounds:)`, add a guard as the first line of the function body (before the existing position/bounds guard):

```swift
        guard lastEnabled else { return }
```

This uses the cache variable set in `applySettings()` rather than checking layer state directly — cleaner and matches the intent.

- [ ] **Step 3: Build**

Run: `xcodebuild -project Beacon/Beacon.xcodeproj -scheme Beacon build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add Beacon/Beacon/Overlay/CrosshairRenderer.swift
git commit -m "feat(crosshair): respect crosshairEnabled toggle"
```

---

### Task 4: Add Crosshair toggle to menu bar

**Files:**

- Modify: `Beacon/Beacon/App/BeaconApp.swift:6-22` (MenuBarMenuContent)

- [ ] **Step 1: Add @AppStorage and Toggle**

In `MenuBarMenuContent`, add a new `@AppStorage` property after line 8:

```swift
    @AppStorage(SettingsKeys.crosshairEnabled) private var crosshairEnabled = SettingsDefaults.crosshairEnabled
```

In the `body`, add a Crosshair toggle before the Spotlight toggle (before line 12). The full body becomes:

```swift
    var body: some View {
        Toggle("Crosshair", isOn: $crosshairEnabled)
            .onChange(of: crosshairEnabled) { _, newValue in
                NSAccessibility.post(
                    element: NSApp as Any,
                    notification: .announcementRequested,
                    userInfo: [
                        .announcement: "Crosshair \(newValue ? "on" : "off")",
                        .priority: NSAccessibilityPriorityLevel.high.rawValue,
                    ]
                )
            }
        Toggle("Spotlight", isOn: $spotlightEnabled)
            .onChange(of: spotlightEnabled) { _, newValue in
                NSAccessibility.post(
                    element: NSApp as Any,
                    notification: .announcementRequested,
                    userInfo: [
                        .announcement: "Spotlight \(newValue ? "on" : "off")",
                        .priority: NSAccessibilityPriorityLevel.high.rawValue,
                    ]
                )
            }
        Button("Ping") {
            log.debug("Ping button tapped")
            appDelegate.performPing()
        }
        .keyboardShortcut("/", modifiers: [.command, .shift])
        Divider()
        Button("Settings...") {
            NSApp.activate()
            openSettings()
        }
        .keyboardShortcut(",")
        Divider()
        Button("Quit Beacon") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
```

- [ ] **Step 2: Build**

Run: `xcodebuild -project Beacon/Beacon.xcodeproj -scheme Beacon build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Beacon/Beacon/App/BeaconApp.swift
git commit -m "feat(menu-bar): add Crosshair toggle with VoiceOver announcement"
```

---

### Task 5: Overlay redraw on settings change

**Files:**

- Modify: `Beacon/Beacon/App/AppDelegate.swift`

- [ ] **Step 1: Add UserDefaults observer**

In `AppDelegate.swift`, add a property after line 13 (`defaults`):

```swift
    private var settingsObserver: NSObjectProtocol?
```

In `applicationDidFinishLaunching`, after the `didChangeScreenParametersNotification` observer (after line 40), add:

```swift
        settingsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: defaults,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.updateAllOverlays(cursorPosition: NSEvent.mouseLocation)
            }
        }
```

In `applicationWillTerminate`, add before line 57:

```swift
        if let token = settingsObserver {
            NotificationCenter.default.removeObserver(token)
        }
```

- [ ] **Step 2: Build**

Run: `xcodebuild -project Beacon/Beacon.xcodeproj -scheme Beacon build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Beacon/Beacon/App/AppDelegate.swift
git commit -m "fix(overlay): redraw on settings change when mouse is stationary"
```

---

## Chunk 2: App Icon

### Task 6: Generate app icon

**Files:**

- Create: `Beacon/Beacon/Resources/Assets.xcassets/AppIcon.appiconset/icon_*.png` (10 sizes)
- Modify: `Beacon/Beacon/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json`

- [ ] **Step 1: Create 1024x1024 SVG master**

Create `/tmp/beacon-icon.svg` with the dark amber scope design:

```svg
<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#1E293B"/>
      <stop offset="100%" stop-color="#0F172A"/>
    </linearGradient>
    <radialGradient id="glow" cx="50%" cy="50%" r="8%">
      <stop offset="0%" stop-color="#FBBF24" stop-opacity="0.3"/>
      <stop offset="100%" stop-color="#FBBF24" stop-opacity="0"/>
    </radialGradient>
  </defs>
  <!-- Background with macOS super-ellipse approximation -->
  <rect width="1024" height="1024" rx="228" fill="url(#bg)"/>
  <!-- Glow ring -->
  <circle cx="512" cy="512" r="64" fill="url(#glow)"/>
  <!-- Center dot -->
  <circle cx="512" cy="512" r="32" fill="#FBBF24"/>
  <!-- Scope circle -->
  <circle cx="512" cy="512" r="192" stroke="#FBBF24" stroke-width="32" fill="none"/>
  <!-- Crosshair lines -->
  <line x1="512" y1="180" x2="512" y2="352" stroke="#FBBF24" stroke-width="32" stroke-linecap="round"/>
  <line x1="512" y1="672" x2="512" y2="844" stroke="#FBBF24" stroke-width="32" stroke-linecap="round"/>
  <line x1="180" y1="512" x2="352" y2="512" stroke="#FBBF24" stroke-width="32" stroke-linecap="round"/>
  <line x1="672" y1="512" x2="844" y2="512" stroke="#FBBF24" stroke-width="32" stroke-linecap="round"/>
</svg>
```

- [ ] **Step 2: Convert SVG to PNG and generate all sizes**

Convert SVG to 1024px PNG using `rsvg-convert` (preferred) or fallback methods, then `sips` for resizing:

```bash
# Method 1 (preferred): rsvg-convert — install with `brew install librsvg` if needed
rsvg-convert -w 1024 -h 1024 /tmp/beacon-icon.svg -o /tmp/beacon-icon-1024.png

# Method 2 (fallback): qlmanage — built into macOS but unreliable for SVG
# qlmanage -t -s 1024 -o /tmp /tmp/beacon-icon.svg
# mv /tmp/beacon-icon.svg.png /tmp/beacon-icon-1024.png

# Method 3 (manual fallback): Open SVG in Safari, File > Export as PDF, then
# open in Preview and File > Export as PNG at 1024x1024

# Generate all sizes with sips
ICON_DIR="Beacon/Beacon/Resources/Assets.xcassets/AppIcon.appiconset"
for size in 16 32 64 128 256 512 1024; do
    sips -z $size $size /tmp/beacon-icon-1024.png --out "$ICON_DIR/icon_${size}x${size}.png"
done
```

The filename mapping to Contents.json entries:
- 16x16@1x → `icon_16x16.png`
- 16x16@2x → `icon_32x32.png` (same file as 32x32@1x)
- 32x32@1x → `icon_32x32.png`
- 32x32@2x → `icon_64x64.png`
- 128x128@1x → `icon_128x128.png`
- 128x128@2x → `icon_256x256.png` (same file as 256x256@1x)
- 256x256@1x → `icon_256x256.png`
- 256x256@2x → `icon_512x512.png` (same file as 512x512@1x)
- 512x512@1x → `icon_512x512.png`
- 512x512@2x → `icon_1024x1024.png`

- [ ] **Step 3: Update Contents.json**

Replace `Beacon/Beacon/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json` with:

```json
{
  "images" : [
    {
      "filename" : "icon_16x16.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_64x64.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_128x128.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "icon_1024x1024.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

- [ ] **Step 4: Build**

Run: `xcodebuild -project Beacon/Beacon.xcodeproj -scheme Beacon build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add Beacon/Beacon/Resources/Assets.xcassets/AppIcon.appiconset/
git commit -m "feat(icon): add dark amber scope app icon"
```

---

## Chunk 3: Launch at Login

### Task 7: Add Launch at Login toggle to GeneralSettingsSection

**Files:**

- Modify: `Beacon/Beacon/Settings/GeneralSettingsSection.swift`

- [ ] **Step 1: Add import and Launch at Login toggle**

Add `import ServiceManagement` at the top of the file (after `import SwiftUI`).

Add a `@State` property and the toggle to `GeneralSettingsSection`. The full file becomes:

```swift
import os
import ServiceManagement
import SwiftUI

struct GeneralSettingsSection: View {
    @AppStorage(SettingsKeys.fadeTimeout) private var fadeTimeout = SettingsDefaults.fadeTimeout
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var requiresApproval = SMAppService.mainApp.status == .requiresApproval

    var body: some View {
        Section("General") {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Fade after idle")
                    Spacer()
                    Text(fadeTimeout == 0 ? "Off" : String(format: "%.1fs", fadeTimeout))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $fadeTimeout, in: 0...10, step: 0.5)
                    .accessibilityLabel("Fade after idle")
                    .accessibilityValue(fadeTimeout == 0 ? "Off" : String(format: "%.1f seconds", fadeTimeout))
                    .accessibilityHint("Set to zero to disable auto-fade")
            }
            Toggle("Launch at Login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, newValue in
                    do {
                        if newValue {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                        requiresApproval = SMAppService.mainApp.status == .requiresApproval
                    } catch {
                        Logger(subsystem: "com.beacon.app", category: "settings")
                            .error("SMAppService registration failed: \(error)")
                        launchAtLogin = !newValue
                    }
                }
            if requiresApproval {
                Text("Open System Settings > General > Login Items to approve.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
```

- [ ] **Step 2: Build**

Run: `xcodebuild -project Beacon/Beacon.xcodeproj -scheme Beacon build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Beacon/Beacon/Settings/GeneralSettingsSection.swift
git commit -m "feat(settings): add Launch at Login toggle via SMAppService"
```

---

### Task 8: Final build and manual verification

- [ ] **Step 1: Clean build**

Run: `xcodebuild -project Beacon/Beacon.xcodeproj -scheme Beacon clean build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 2: Manual verification checklist**

Run the app (Cmd+R in Xcode) and verify:

1. Menu bar shows the `scope` icon (thinner than before)
2. Menu bar dropdown shows "Crosshair" toggle (checked by default) and "Spotlight" toggle
3. Unchecking "Crosshair" hides the crosshair lines, VoiceOver announces "Crosshair off"
4. Unchecking both "Crosshair" and "Spotlight" — overlay draws nothing, no artifacts
5. Re-checking toggles — features reappear immediately (even without moving mouse)
6. Change a setting (e.g., crosshair color) while mouse is stationary — overlay updates
7. App icon shows dark amber scope in Finder/dock/About
8. Settings > General shows "Launch at Login" toggle
9. All previous features still work (crosshair follows cursor, spotlight, ping, fade timeout)
10. Click-through still works (can interact with apps beneath overlay)

- [ ] **Step 3: Squash commit (milestone)**

```bash
git add -A
git commit -m "Milestone 9: Polish + edge cases"
```
