# Spotlight Mode Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an inverted spotlight overlay — screen dimmed except a clear circle around the cursor — togglable from menu bar and settings.

**Architecture:** Single `CAShapeLayer` per overlay with even-odd fill rule (full-screen rect + circular cutout). Follows existing renderer pattern (`CrosshairRenderer`). Settings via `@AppStorage`/`UserDefaults`.

**Tech Stack:** Swift 6, AppKit, Core Animation (`CAShapeLayer`), SwiftUI (settings)

**Spec:** `docs/superpowers/specs/2026-03-14-spotlight-mode-design.md`

---

## File Map

| Action | File | Responsibility |
|--------|------|---------------|
| Modify | `Beacon/Beacon/Settings/SettingsKeys.swift` | Add spotlight keys + defaults |
| Create | `Beacon/Beacon/Overlay/SpotlightRenderer.swift` | Even-odd spotlight layer |
| Modify | `Beacon/Beacon/Overlay/OverlayView.swift` | Integrate SpotlightRenderer |
| Create | `Beacon/Beacon/Settings/SpotlightSettingsSection.swift` | Settings UI for spotlight |
| Modify | `Beacon/Beacon/Settings/SettingsView.swift` | Add spotlight section |
| Modify | `Beacon/Beacon/App/BeaconApp.swift` | Menu bar toggle |

---

## Chunk 1: Renderer + Integration

### Task 1: Add spotlight settings keys and defaults

**Files:**
- Modify: `Beacon/Beacon/Settings/SettingsKeys.swift`

- [ ] **Step 1: Add spotlight keys to SettingsKeys enum**

Add after the `fadeTimeout` key:

```swift
static let spotlightEnabled = "spotlightEnabled"
static let spotlightRadius = "spotlightRadius"
static let spotlightDimOpacity = "spotlightDimOpacity"
```

- [ ] **Step 2: Add spotlight defaults to SettingsDefaults enum**

Add after the `fadeTimeout` default:

```swift
static let spotlightEnabled = false
static let spotlightRadius: Double = 100.0
static let spotlightDimOpacity: Double = 0.5
```

- [ ] **Step 3: Build to verify no errors**

Run: `xcodebuild -project Beacon/Beacon.xcodeproj -scheme Beacon build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add Beacon/Beacon/Settings/SettingsKeys.swift
git commit -m "Add spotlight settings keys and defaults"
```

---

### Task 2: Create SpotlightRenderer

**Files:**
- Create: `Beacon/Beacon/Overlay/SpotlightRenderer.swift`

- [ ] **Step 1: Create SpotlightRenderer.swift**

```swift
import AppKit
import QuartzCore

@MainActor
class SpotlightRenderer {
    private let dimLayer = CAShapeLayer()
    private let defaults = UserDefaults.standard
    private nonisolated(unsafe) var settingsObserver: NSObjectProtocol?

    private var lastDrawnPosition: NSPoint = .zero
    private var lastDrawnBounds: NSRect = .zero
    private var lastEnabled: Bool = false
    private var lastRadius: CGFloat = -1
    private var lastDimOpacity: CGFloat = -1

    func setup(in layer: CALayer, bounds: NSRect) {
        dimLayer.fillRule = .evenOdd
        dimLayer.fillColor = NSColor.black.cgColor
        dimLayer.strokeColor = nil
        dimLayer.actions = [
            "path": NSNull(), "opacity": NSNull(), "hidden": NSNull(),
            "fillColor": NSNull(),
        ]
        layer.addSublayer(dimLayer)

        applySettings()

        settingsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: defaults,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.applySettings()
            }
        }
    }

    deinit {
        if let token = settingsObserver {
            NotificationCenter.default.removeObserver(token)
        }
    }

    func updatePosition(_ position: NSPoint, bounds: NSRect) {
        guard !dimLayer.isHidden else { return }
        guard position != lastDrawnPosition || bounds != lastDrawnBounds else { return }
        lastDrawnPosition = position
        lastDrawnBounds = bounds

        let radius = CGFloat(defaults.object(forKey: SettingsKeys.spotlightRadius) as? Double
            ?? SettingsDefaults.spotlightRadius)

        let path = CGMutablePath()
        path.addRect(CGRect(origin: .zero, size: bounds.size))
        path.addEllipse(in: CGRect(
            x: position.x - radius,
            y: position.y - radius,
            width: radius * 2,
            height: radius * 2
        ))
        dimLayer.path = path
    }

    private func applySettings() {
        let enabled = defaults.object(forKey: SettingsKeys.spotlightEnabled) as? Bool
            ?? SettingsDefaults.spotlightEnabled
        let radius = CGFloat(defaults.object(forKey: SettingsKeys.spotlightRadius) as? Double
            ?? SettingsDefaults.spotlightRadius)
        let dimOpacity = CGFloat(defaults.object(forKey: SettingsKeys.spotlightDimOpacity) as? Double
            ?? SettingsDefaults.spotlightDimOpacity)

        if enabled == lastEnabled && radius == lastRadius && dimOpacity == lastDimOpacity { return }
        lastEnabled = enabled
        lastRadius = radius
        lastDimOpacity = dimOpacity

        dimLayer.isHidden = !enabled
        dimLayer.opacity = Float(dimOpacity)

        if enabled {
            // Force redraw with new radius by resetting cached position
            lastDrawnPosition = .zero
            lastDrawnBounds = .zero
        }
    }
}
```

- [ ] **Step 2: Add file to Xcode project**

The file should be created at `Beacon/Beacon/Overlay/SpotlightRenderer.swift`. Xcode auto-discovers files in the project directory, but verify it appears in the project navigator after build.

- [ ] **Step 3: Build to verify no errors**

Run: `xcodebuild -project Beacon/Beacon.xcodeproj -scheme Beacon build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add Beacon/Beacon/Overlay/SpotlightRenderer.swift
git commit -m "Add SpotlightRenderer with even-odd circular cutout"
```

---

### Task 3: Integrate SpotlightRenderer into OverlayView

**Files:**
- Modify: `Beacon/Beacon/Overlay/OverlayView.swift`

- [ ] **Step 1: Add SpotlightRenderer property**

Add after `private let crosshairRenderer = CrosshairRenderer()`:

```swift
private let spotlightRenderer = SpotlightRenderer()
```

- [ ] **Step 2: Call setup in init**

Add after `crosshairRenderer.setup(in: layer, bounds: frame)`:

```swift
spotlightRenderer.setup(in: layer, bounds: frame)
```

**Important:** Spotlight must be added first so it renders *behind* the crosshair. Move the spotlight setup *before* the crosshair setup:

```swift
spotlightRenderer.setup(in: layer, bounds: frame)
crosshairRenderer.setup(in: layer, bounds: frame)
```

- [ ] **Step 3: Call updatePosition in updateCursorPosition**

Replace the body of `updateCursorPosition`:

```swift
func updateCursorPosition(_ position: NSPoint) {
    spotlightRenderer.updatePosition(position, bounds: bounds)
    crosshairRenderer.updatePosition(position, bounds: bounds)
}
```

- [ ] **Step 4: Build to verify no errors**

Run: `xcodebuild -project Beacon/Beacon.xcodeproj -scheme Beacon build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Manual test**

Run app. Open settings or use `defaults write` to enable spotlight:
```bash
defaults write com.beacon.app spotlightEnabled -bool true
```
Move mouse. Screen should dim except a 100px-radius circle around cursor. Crosshair should still be visible on top. Click-through should work.

- [ ] **Step 6: Commit**

```bash
git add Beacon/Beacon/Overlay/OverlayView.swift
git commit -m "Integrate SpotlightRenderer into overlay view"
```

---

## Chunk 2: Settings UI + Menu Bar Toggle

### Task 4: Create SpotlightSettingsSection

**Files:**
- Create: `Beacon/Beacon/Settings/SpotlightSettingsSection.swift`

- [ ] **Step 1: Create SpotlightSettingsSection.swift**

```swift
import SwiftUI

struct SpotlightSettingsSection: View {
    @AppStorage(SettingsKeys.spotlightEnabled) private var enabled = SettingsDefaults.spotlightEnabled
    @AppStorage(SettingsKeys.spotlightRadius) private var radius = SettingsDefaults.spotlightRadius
    @AppStorage(SettingsKeys.spotlightDimOpacity) private var dimOpacity = SettingsDefaults.spotlightDimOpacity

    var body: some View {
        Section("Spotlight") {
            Toggle("Enable Spotlight", isOn: $enabled)

            if enabled {
                sliderRow("Radius", value: $radius, range: 25...300, step: 5) {
                    "\(Int($0)) px"
                }

                sliderRow("Dim Opacity", value: $dimOpacity, range: 0.1...0.9, step: 0.05) {
                    String(format: "%.0f%%", $0 * 100)
                }
            }
        }
    }

    private func sliderRow(
        _ label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        format: @escaping (Double) -> String
    ) -> some View {
        HStack {
            Text(label)
            Slider(value: value, in: range, step: step)
            Text(format(value.wrappedValue))
                .monospacedDigit()
                .frame(width: 50, alignment: .trailing)
        }
    }
}
```

- [ ] **Step 2: Build to verify no errors**

Run: `xcodebuild -project Beacon/Beacon.xcodeproj -scheme Beacon build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Beacon/Beacon/Settings/SpotlightSettingsSection.swift
git commit -m "Add SpotlightSettingsSection UI"
```

---

### Task 5: Add SpotlightSettingsSection to SettingsView

**Files:**
- Modify: `Beacon/Beacon/Settings/SettingsView.swift`

- [ ] **Step 1: Insert SpotlightSettingsSection between Crosshair and General**

Replace the Form body:

```swift
Form {
    CrosshairSettingsSection()
    SpotlightSettingsSection()
    GeneralSettingsSection()
}
```

- [ ] **Step 2: Build to verify no errors**

Run: `xcodebuild -project Beacon/Beacon.xcodeproj -scheme Beacon build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Beacon/Beacon/Settings/SettingsView.swift
git commit -m "Add spotlight section to settings view"
```

---

### Task 6: Add Spotlight toggle to menu bar

**Files:**
- Modify: `Beacon/Beacon/App/BeaconApp.swift`

- [ ] **Step 1: Add AppStorage binding and toggle to MenuBarMenuContent**

Add `@AppStorage` property to `MenuBarMenuContent`:

```swift
@AppStorage(SettingsKeys.spotlightEnabled) private var spotlightEnabled = SettingsDefaults.spotlightEnabled
```

Add the toggle before the Settings button:

```swift
Toggle("Spotlight", isOn: $spotlightEnabled)
Divider()
```

The full `MenuBarMenuContent` body becomes:

```swift
var body: some View {
    Toggle("Spotlight", isOn: $spotlightEnabled)
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

- [ ] **Step 2: Build to verify no errors**

Run: `xcodebuild -project Beacon/Beacon.xcodeproj -scheme Beacon build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Manual test — full integration**

Run app. Verify:
1. Menu bar shows "Spotlight" toggle (unchecked by default)
2. Check "Spotlight" — screen dims except circle around cursor
3. Uncheck — dim disappears, crosshair still works
4. Open Settings — Spotlight section visible with Enable toggle, Radius slider, Dim Opacity slider
5. Toggle on in settings, adjust radius and opacity — changes apply immediately
6. Stop moving mouse — spotlight fades with crosshair (fade timeout)
7. Move mouse — spotlight reappears instantly
8. Click-through works (can interact with apps beneath dim)

- [ ] **Step 4: Commit**

```bash
git add Beacon/Beacon/App/BeaconApp.swift
git commit -m "Add spotlight toggle to menu bar"
```

---

## Final Verification

- [ ] **Step 1: Run full build**

```bash
xcodebuild -project Beacon/Beacon.xcodeproj -scheme Beacon build 2>&1 | tail -5
```

- [ ] **Step 2: Run app and verify all test plan items from spec**

See spec test plan (10 items) at `docs/superpowers/specs/2026-03-14-spotlight-mode-design.md`.

- [ ] **Step 3: Commit all remaining changes (if any)**

```bash
git add -A && git commit -m "Complete Milestone 6: Spotlight Mode"
```
