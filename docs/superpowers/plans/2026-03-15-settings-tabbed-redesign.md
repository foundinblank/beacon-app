# Settings Tabbed Redesign — Implementation Plan

> **Status: COMPLETE** (2026-03-15)

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the Beacon settings panel from a single scrolling form into a 4-tab TabView with a new master color model, fixing window overflow and adding crosshair toggle consistency.

**Architecture:** Replace `SettingsView`'s single `Form` with a `TabView` (text-only tabs). Each tab wraps its content in its own `Form { Section { ... } }.formStyle(.grouped)`. A new `masterColor` key replaces the old crosshair-as-source sync model. Renderers read `masterColor` when sync is on, or their per-feature key when sync is off.

**Tech Stack:** Swift 6, SwiftUI (settings), AppKit (renderers), UserDefaults, ServiceManagement

**Spec:** `docs/superpowers/specs/2026-03-15-settings-tabbed-redesign.md`

---

## Chunk 1: Settings Keys + Migration + Renderers

### Task 1: Add masterColor to SettingsKeys and SettingsDefaults

**Files:**
- Modify: `Beacon/Beacon/Settings/SettingsKeys.swift`

- [ ] **Step 1: Add masterColor key and defaults**

In `SettingsKeys`, add after `syncColor` (line 18):

```swift
    static let masterColor = "masterColor"
    static let selectedSettingsTab = "selectedSettingsTab"
```

In `SettingsDefaults`, add after `syncColor = true` (line 37):

```swift
    static let masterColor = "#FF0000"
    static let masterNSColor: NSColor = NSColor(hex: masterColor) ?? .red
```

- [ ] **Step 2: Build**

Run: `xcodebuild -project Beacon/Beacon.xcodeproj -scheme Beacon build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Beacon/Beacon/Settings/SettingsKeys.swift
git commit -m "feat(settings): add masterColor and selectedSettingsTab keys"
```

---

### Task 2: Add migration and register masterColor default in AppDelegate

**Files:**
- Modify: `Beacon/Beacon/App/AppDelegate.swift`

- [ ] **Step 1: Add migration before register(defaults:)**

In `applicationDidFinishLaunching`, add before the `defaults.register(defaults:)` call:

```swift
        // One-time migration: copy crosshairColor → masterColor for existing users
        if defaults.object(forKey: SettingsKeys.masterColor) == nil,
           let existingColor = defaults.string(forKey: SettingsKeys.crosshairColor) {
            defaults.set(existingColor, forKey: SettingsKeys.masterColor)
        }
```

- [ ] **Step 2: Add masterColor to the register(defaults:) dictionary**

Add after the `syncColor` entry in the `defaults.register(defaults:)` dictionary:

```swift
            SettingsKeys.masterColor: SettingsDefaults.masterColor,
```

- [ ] **Step 3: Build**

Run: `xcodebuild -project Beacon/Beacon.xcodeproj -scheme Beacon build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add Beacon/Beacon/App/AppDelegate.swift
git commit -m "feat(settings): add masterColor migration and default registration"
```

---

### Task 3: Update CrosshairRenderer to use masterColor when sync is on

**Files:**
- Modify: `Beacon/Beacon/Overlay/CrosshairRenderer.swift`

- [ ] **Step 1: Change color resolution in applySettings()**

In `applySettings()`, replace the `colorHex` read:

```swift
        let colorHex = defaults.string(forKey: SettingsKeys.crosshairColor) ?? SettingsDefaults.crosshairColor
```

With:

```swift
        let colorHex: String
        if defaults.object(forKey: SettingsKeys.syncColor) as? Bool ?? SettingsDefaults.syncColor {
            colorHex = defaults.string(forKey: SettingsKeys.masterColor) ?? SettingsDefaults.masterColor
        } else {
            colorHex = defaults.string(forKey: SettingsKeys.crosshairColor) ?? SettingsDefaults.crosshairColor
        }
```

No other changes needed — `lastColorHex` already caches the resolved value since it's set from `colorHex` after the sync branch.

- [ ] **Step 2: Build**

Run: `xcodebuild -project Beacon/Beacon.xcodeproj -scheme Beacon build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Beacon/Beacon/Overlay/CrosshairRenderer.swift
git commit -m "feat(renderer): CrosshairRenderer reads masterColor when sync is on"
```

---

### Task 4: Update SpotlightRenderer to use masterColor when sync is on

**Files:**
- Modify: `Beacon/Beacon/Overlay/SpotlightRenderer.swift`

- [ ] **Step 1: Change color resolution in applySettings()**

In `applySettings()`, replace the `colorHex` read:

```swift
        let colorHex = defaults.string(forKey: SettingsKeys.spotlightBorderColor) ?? SettingsDefaults.spotlightBorderColor
```

With:

```swift
        let colorHex: String
        if defaults.object(forKey: SettingsKeys.syncColor) as? Bool ?? SettingsDefaults.syncColor {
            colorHex = defaults.string(forKey: SettingsKeys.masterColor) ?? SettingsDefaults.masterColor
        } else {
            colorHex = defaults.string(forKey: SettingsKeys.spotlightBorderColor) ?? SettingsDefaults.spotlightBorderColor
        }
```

- [ ] **Step 2: Build**

Run: `xcodebuild -project Beacon/Beacon.xcodeproj -scheme Beacon build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Beacon/Beacon/Overlay/SpotlightRenderer.swift
git commit -m "feat(renderer): SpotlightRenderer reads masterColor when sync is on"
```

---

### Task 5: Update RippleAnimationManager to use masterColor when sync is on

**Files:**
- Modify: `Beacon/Beacon/Overlay/RippleAnimationManager.swift`

- [ ] **Step 1: Change color resolution in play()**

In `play(at:in:)`, replace the `colorHex` read:

```swift
        let colorHex = defaults.string(forKey: SettingsKeys.rippleColor)
            ?? SettingsDefaults.rippleColor
```

With:

```swift
        let colorHex: String
        if defaults.object(forKey: SettingsKeys.syncColor) as? Bool ?? SettingsDefaults.syncColor {
            colorHex = defaults.string(forKey: SettingsKeys.masterColor) ?? SettingsDefaults.masterColor
        } else {
            colorHex = defaults.string(forKey: SettingsKeys.rippleColor) ?? SettingsDefaults.rippleColor
        }
```

- [ ] **Step 2: Build**

Run: `xcodebuild -project Beacon/Beacon.xcodeproj -scheme Beacon build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Beacon/Beacon/Overlay/RippleAnimationManager.swift
git commit -m "feat(renderer): RippleAnimationManager reads masterColor when sync is on"
```

---

## Chunk 2: Settings UI — Tab Views

### Task 6: Rename files and update Xcode project references

All four settings section files are renamed to tab files, and the Xcode project.pbxproj is updated to match. This must happen before any file rewrites to keep the build valid.

**Files:**
- Rename: `Beacon/Beacon/Settings/CrosshairSettingsSection.swift` → `CrosshairSettingsTab.swift`
- Rename: `Beacon/Beacon/Settings/SpotlightSettingsSection.swift` → `SpotlightSettingsTab.swift`
- Rename: `Beacon/Beacon/Settings/PingSettingsSection.swift` → `PingSettingsTab.swift`
- Rename: `Beacon/Beacon/Settings/GeneralSettingsSection.swift` → `GeneralSettingsTab.swift`
- Modify: `Beacon/Beacon.xcodeproj/project.pbxproj`

- [ ] **Step 1: Rename all four files**

```bash
git mv Beacon/Beacon/Settings/CrosshairSettingsSection.swift Beacon/Beacon/Settings/CrosshairSettingsTab.swift
git mv Beacon/Beacon/Settings/SpotlightSettingsSection.swift Beacon/Beacon/Settings/SpotlightSettingsTab.swift
git mv Beacon/Beacon/Settings/PingSettingsSection.swift Beacon/Beacon/Settings/PingSettingsTab.swift
git mv Beacon/Beacon/Settings/GeneralSettingsSection.swift Beacon/Beacon/Settings/GeneralSettingsTab.swift
```

- [ ] **Step 2: Update project.pbxproj references**

```bash
sed -i '' 's/CrosshairSettingsSection/CrosshairSettingsTab/g' Beacon/Beacon.xcodeproj/project.pbxproj
sed -i '' 's/SpotlightSettingsSection/SpotlightSettingsTab/g' Beacon/Beacon.xcodeproj/project.pbxproj
sed -i '' 's/PingSettingsSection/PingSettingsTab/g' Beacon/Beacon.xcodeproj/project.pbxproj
sed -i '' 's/GeneralSettingsSection/GeneralSettingsTab/g' Beacon/Beacon.xcodeproj/project.pbxproj
```

---

### Task 7: Rewrite CrosshairSettingsTab

**Files:**
- Modify: `Beacon/Beacon/Settings/CrosshairSettingsTab.swift` (renamed in Task 6)

- [ ] **Step 1: Rewrite the file**

Replace the entire file contents with:

```swift
import SwiftUI

struct CrosshairSettingsTab: View {
    @AppStorage(SettingsKeys.crosshairEnabled) private var enabled = SettingsDefaults.crosshairEnabled
    @AppStorage(SettingsKeys.crosshairColor) private var colorHex = SettingsDefaults.crosshairColor
    @AppStorage(SettingsKeys.syncColor) private var syncColor = SettingsDefaults.syncColor
    @AppStorage(SettingsKeys.crosshairThickness) private var thickness = SettingsDefaults.crosshairThickness
    @AppStorage(SettingsKeys.crosshairLineStyle) private var lineStyle = SettingsDefaults.crosshairLineStyle
    @AppStorage(SettingsKeys.crosshairDashLength) private var dashLength = SettingsDefaults.crosshairDashLength
    @AppStorage(SettingsKeys.crosshairGapLength) private var gapLength = SettingsDefaults.crosshairGapLength

    var body: some View {
        Form {
            Section("Crosshair") {
                Toggle("Enable Crosshair", isOn: $enabled)

                ColorPickerRow(label: "Color", colorHex: $colorHex)
                    .disabled(syncColor)
                if syncColor {
                    Text("Color is set in the General tab")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                SliderRow(label: "Line thickness", value: $thickness, range: 0.5...10, step: 0.5) {
                    String(format: "%.1f px", $0)
                }

                Picker("Line style", selection: $lineStyle) {
                    Text("Solid").tag(LineStyle.solid.rawValue)
                    Text("Dashed").tag(LineStyle.dashed.rawValue)
                    Text("Dotted").tag(LineStyle.dotted.rawValue)
                }

                if lineStyle == LineStyle.dashed.rawValue {
                    SliderRow(label: "Dash length", value: $dashLength, range: 1...20, step: 1) {
                        "\(Int($0)) px"
                    }
                }

                if (LineStyle(rawValue: lineStyle) ?? .solid).hasDashParameters {
                    SliderRow(label: "Spacing", value: $gapLength, range: 1...20, step: 1) {
                        "\(Int($0)) px"
                    }
                }
            }
        }
        .formStyle(.grouped)
        .scrollBounceBehavior(.basedOnSize)
    }
}
```

Note: The old `syncColor` toggle and `onChange` handlers that propagated color to `rippleColor`/`spotlightBorderColor` are intentionally removed — the new master color model handles sync at render time.

---

### Task 8: Rewrite SpotlightSettingsTab

**Files:**
- Modify: `Beacon/Beacon/Settings/SpotlightSettingsTab.swift` (renamed in Task 6)

- [ ] **Step 1: Rewrite the file**

Replace the entire file contents with:

```swift
import SwiftUI

struct SpotlightSettingsTab: View {
    @AppStorage(SettingsKeys.spotlightEnabled) private var enabled = SettingsDefaults.spotlightEnabled
    @AppStorage(SettingsKeys.spotlightRadius) private var radius = SettingsDefaults.spotlightRadius
    @AppStorage(SettingsKeys.spotlightDimOpacity) private var dimOpacity = SettingsDefaults.spotlightDimOpacity
    @AppStorage(SettingsKeys.spotlightBorderWidth) private var borderWidth = SettingsDefaults.spotlightBorderWidth
    @AppStorage(SettingsKeys.spotlightBorderColor) private var borderColorHex = SettingsDefaults.spotlightBorderColor
    @AppStorage(SettingsKeys.syncColor) private var syncColor = SettingsDefaults.syncColor

    var body: some View {
        Form {
            Section("Spotlight") {
                Toggle("Enable Spotlight", isOn: $enabled)

                SliderRow(label: "Radius", value: $radius, range: 25...300, step: 5) {
                    "\(Int($0)) px"
                }

                SliderRow(label: "Dim opacity", value: $dimOpacity, range: 0.0...1.0, step: 0.05) {
                    String(format: "%.0f%%", $0 * 100)
                }

                SliderRow(label: "Border width", value: $borderWidth, range: 0...10, step: 0.5) {
                    $0 == 0 ? "Off" : String(format: "%.1f px", $0)
                }

                if syncColor {
                    ColorPickerRow(label: "Border color", colorHex: $borderColorHex)
                        .disabled(true)
                    Text("Color is set in the General tab")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if borderWidth > 0 {
                    ColorPickerRow(label: "Border color", colorHex: $borderColorHex)
                }
            }
        }
        .formStyle(.grouped)
        .scrollBounceBehavior(.basedOnSize)
    }
}
```

---

### Task 9: Rewrite PingSettingsTab

**Files:**
- Modify: `Beacon/Beacon/Settings/PingSettingsTab.swift` (renamed in Task 6)

- [ ] **Step 1: Rewrite the file**

Replace the entire file contents with:

```swift
import SwiftUI

struct PingSettingsTab: View {
    @AppStorage(SettingsKeys.pingMode) private var pingMode = SettingsDefaults.pingMode
    @AppStorage(SettingsKeys.rippleColor) private var rippleColorHex = SettingsDefaults.rippleColor
    @AppStorage(SettingsKeys.syncColor) private var syncColor = SettingsDefaults.syncColor

    private var selectedMode: Binding<PingMode> {
        Binding(
            get: { PingMode(rawValue: pingMode) ?? .centerAndRipple },
            set: { pingMode = $0.rawValue }
        )
    }

    var body: some View {
        Form {
            Section("Ping") {
                Text("Shortcut: \u{2318}\u{21E7}/")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Picker("Mode", selection: selectedMode) {
                    ForEach(PingMode.allCases, id: \.self) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if syncColor {
                    ColorPickerRow(label: "Ripple color", colorHex: $rippleColorHex)
                        .disabled(true)
                    Text("Color is set in the General tab")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if selectedMode.wrappedValue != .centerOnly {
                    ColorPickerRow(label: "Ripple color", colorHex: $rippleColorHex)
                }
            }
        }
        .formStyle(.grouped)
        .scrollBounceBehavior(.basedOnSize)
    }
}
```

---

### Task 10: Rewrite GeneralSettingsTab

**Files:**
- Modify: `Beacon/Beacon/Settings/GeneralSettingsTab.swift` (renamed in Task 6)

- [ ] **Step 1: Rewrite the file**

Replace the entire file contents with:

```swift
import os
import ServiceManagement
import SwiftUI

struct GeneralSettingsTab: View {
    @AppStorage(SettingsKeys.syncColor) private var syncColor = SettingsDefaults.syncColor
    @AppStorage(SettingsKeys.masterColor) private var masterColorHex = SettingsDefaults.masterColor
    @AppStorage(SettingsKeys.fadeTimeout) private var fadeTimeout = SettingsDefaults.fadeTimeout
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var requiresApproval = SMAppService.mainApp.status == .requiresApproval

    var body: some View {
        Form {
            Section("General") {
                Toggle("Sync color", isOn: $syncColor)

                ColorPickerRow(label: "Color", colorHex: $masterColorHex)
                    .disabled(!syncColor)
                if !syncColor {
                    Text("Enable Sync color to set a global color")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

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
        .formStyle(.grouped)
        .scrollBounceBehavior(.basedOnSize)
    }
}
```

---

### Task 11: Rewrite SettingsView as TabView

**Files:**
- Modify: `Beacon/Beacon/Settings/SettingsView.swift`

- [ ] **Step 1: Replace Form with TabView**

Replace the entire file contents with:

```swift
import SwiftUI

struct SettingsView: View {
    @ScaledMetric(relativeTo: .body) private var settingsWidth: CGFloat = 450
    @AppStorage(SettingsKeys.selectedSettingsTab) private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            CrosshairSettingsTab()
                .tabItem { Text("Crosshair") }
                .tag(0)
            SpotlightSettingsTab()
                .tabItem { Text("Spotlight") }
                .tag(1)
            PingSettingsTab()
                .tabItem { Text("Ping") }
                .tag(2)
            GeneralSettingsTab()
                .tabItem { Text("General") }
                .tag(3)
        }
        .frame(minWidth: 400, idealWidth: settingsWidth, minHeight: 300, idealHeight: 400)
    }
}
```

- [ ] **Step 2: Build**

Run: `xcodebuild -project Beacon/Beacon.xcodeproj -scheme Beacon clean build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit all tab changes together**

```bash
git add Beacon/Beacon/Settings/ Beacon/Beacon.xcodeproj/project.pbxproj
git commit -m "feat(settings): convert to tabbed layout with master color model"
```

---

### Task 12: Manual verification

- [ ] **Step 1: Run the app** (Cmd+R in Xcode) and verify:

1. Settings window shows 4 text tabs: Crosshair, Spotlight, Ping, General
2. Crosshair tab shows Enable toggle, color picker, thickness, line style, dash/gap
3. Spotlight tab shows Enable toggle, radius, dim opacity, border width, border color
4. Ping tab shows shortcut, mode picker, ripple color
5. General tab shows sync color toggle, master color picker, fade timeout, launch at login
6. With sync ON: color pickers on Crosshair/Spotlight/Ping are grayed out with hint text
7. With sync OFF: General color picker is grayed out, per-feature pickers are active
8. Changing master color with sync on updates crosshair/spotlight/ripple colors live
9. Settings window does not spill off screen
10. Tab selection persists across close/reopen
11. All previous features still work (crosshair, spotlight, ping, fade)
12. Click-through still works

- [ ] **Step 2: Final commit**

```bash
git add -A
git commit -m "Milestone 9.5: Settings tabbed redesign with master color model"
```
