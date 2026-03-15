# Milestone 9: Polish + Edge Cases — Design Spec

## Overview

Final polish milestone for Beacon v1. Covers menu bar icon change, app icon creation, menu bar checkmark sync, overlay redraw on toggle, handling all-features-disabled state, and Launch at Login.

## 1. Menu Bar Icon

**Change**: Replace `systemImage: "target"` with `systemImage: "scope"` in `BeaconApp.swift` line 50.

**Why**: The current `target` SF Symbol is too thick/heavy. `scope` is a thinner crosshair-with-circle that directly communicates the app's purpose.

**File**: `BeaconApp.swift`

## 2. App Icon

**Design**: Amber/gold scope on dark slate gradient background.

- Background: linear gradient from `#1E293B` (top) to `#0F172A` (bottom), rounded rect with standard macOS super-ellipse
- Foreground: scope motif (circle + 4 crosshair lines extending to edges) in `#FBBF24` (amber), stroke width ~4pt at 128px scale
- Center: small filled amber dot with soft glow ring at `#FBBF24` 30% opacity

**Sizes needed** (macOS app icon set):
- 16x16, 16x16@2x (32px)
- 32x32, 32x32@2x (64px)
- 128x128, 128x128@2x (256px)
- 256x256, 256x256@2x (512px)
- 512x512, 512x512@2x (1024px)

**Approach**: Create a 1024x1024 SVG master, use `sips` to convert to PNG and generate all required sizes. Update `AppIcon.appiconset/Contents.json` to reference the generated PNGs.

**Files**: `Resources/Assets.xcassets/AppIcon.appiconset/`

## 3. Menu Bar Checkmark Sync

**Current state**: The menu only has a `Toggle` for Spotlight. There is no crosshair toggle in the menu bar (crosshair is always on when the app is running — there's no `crosshairEnabled` key).

**Assessment**: The Spotlight toggle already uses `@AppStorage(SettingsKeys.spotlightEnabled)` which is the same key the `SpotlightRenderer` reads from `UserDefaults`. SwiftUI's `Toggle` in `MenuBarExtra` renders as a checkmark automatically. This is already working correctly.

**No changes needed** — the existing `@AppStorage` binding keeps the checkmark in sync.

## 4. Overlay Redraw on Toggle

**Problem**: When the user toggles Spotlight from the menu bar while the mouse is stationary, the overlay doesn't update until the next mouse move because renderers only update in the `handleMouseMove` callback.

**Solution**: Observe `UserDefaults.didChangeNotification` in `AppDelegate` and trigger a re-render at the current cursor position when relevant settings change. This is a lightweight approach — we re-render using the last known `NSEvent.mouseLocation`.

**Implementation**:
- In `AppDelegate.applicationDidFinishLaunching`, add a `NotificationCenter` observer for `UserDefaults.didChangeNotification`
- In the handler, call `updateAllOverlays(cursorPosition: NSEvent.mouseLocation)`
- Do NOT unfade the overlays on settings change — the user can move the mouse to see the result. Unfading on every `UserDefaults` notification would cause erratic behavior while adjusting sliders (each drag fires multiple notifications, each would reset the fade timer).

**File**: `AppDelegate.swift`

**Note**: Both renderers already independently observe `UserDefaults.didChangeNotification` and call their own `applySettings()` (which resets their position cache). The `AppDelegate` observer's role is specifically to trigger the position update that completes the re-render when the mouse is stationary. `UserDefaults.didChangeNotification` fires for any key change, but the renderers' cache comparison makes redundant calls cheap.

## 5. All Features Disabled

**Current state**: The crosshair is always drawn (no enable/disable toggle). Spotlight has an enable toggle. When spotlight is disabled, the spotlight renderer hides its layers.

**Assessment**: Since the crosshair has no disable toggle, the "all features disabled" scenario doesn't currently arise — the crosshair always renders. The spotlight renderer already handles its disabled state by setting layer opacity to 0.

**Add a crosshair enable/disable toggle**:
- Add `crosshairEnabled` key to `SettingsKeys` and `SettingsDefaults` (default: `true`)
- Add `crosshairEnabled` to `defaults.register(defaults:)` dictionary in `AppDelegate.applicationDidFinishLaunching`
- `CrosshairRenderer`: read the key on each update, set all 4 line layers to `isHidden = true` when disabled (matching `SpotlightRenderer`'s pattern which uses `isHidden` rather than opacity)
- `MenuBarMenuContent`: add a `Toggle("Crosshair", ...)` above the Spotlight toggle
- VoiceOver announcement on toggle (matching the existing Spotlight pattern)

**When both crosshair and spotlight are disabled**: Both renderers hide their layers via `isHidden`. The overlay window remains present but draws nothing. This is correct — no visual artifacts, no wasted GPU work (hidden `CAShapeLayer`s are free).

**Files**: `SettingsKeys.swift`, `CrosshairRenderer.swift`, `BeaconApp.swift`, `AppDelegate.swift`

## 6. Launch at Login

**Framework**: `ServiceManagement` — `SMAppService.mainApp` (macOS 13+, well within our macOS 14+ target).

**Implementation**:
- Add `import ServiceManagement` to `GeneralSettingsSection.swift`
- Add a `Toggle("Launch at Login", ...)` bound to local `@State`
- On appear, read `SMAppService.mainApp.status == .enabled` to set initial state
- On toggle change, call `SMAppService.mainApp.register()` or `.unregister()`
- Handle errors by reverting the toggle and logging
- If status is `.requiresApproval`, show an inline `Text` note below the toggle directing user to System Settings > General > Login Items (consistent with the existing settings UI pattern of inline labels/descriptions)

**Note on App Sandbox**: `SMAppService` works with both sandboxed and non-sandboxed apps. No entitlement changes needed.

**File**: `GeneralSettingsSection.swift`

## Files Changed Summary

| File | Change |
|------|--------|
| `BeaconApp.swift` | Change icon to `scope`, add Crosshair toggle |
| `AppDelegate.swift` | Add `UserDefaults.didChangeNotification` observer for overlay redraw on settings change, register `crosshairEnabled` default |
| `SettingsKeys.swift` | Add `crosshairEnabled` key and default |
| `CrosshairRenderer.swift` | Respect `crosshairEnabled` toggle |
| `GeneralSettingsSection.swift` | Add Launch at Login toggle |
| `AppIcon.appiconset/` | Add icon PNGs and update `Contents.json` |

## Out of Scope

- Reading Guide (deferred to post-v1)
- Input Monitoring permission prompt (not needed — we use NSEvent monitors, not CGEventTap)
- Testing with Mission Control / fullscreen / Spaces / Accessibility Zoom (manual testing, not code changes)
- macOS 14/15 compatibility testing (manual)
