# Ping — Auto-Center + Ripple Animation

## Overview

Ping is a cursor locator feature for Beacon. It helps visually impaired users find their cursor by warping it to screen center, playing a contracting ripple animation, or both. Triggered via Cmd-Shift-/ global hotkey or the menu bar. This replaces the "Auto-Center + Flash" concept from the original spec (Milestone 8) — the ripple replaces the flash animation entirely.

## Trigger: Global Hotkey (Cmd-Shift-/)

A `GlobalHotkeyManager` registers a system-wide hotkey using Carbon `RegisterEventHotKey`. This is reliable and doesn't require timing-sensitive detection like the earlier double-tap Caps Lock approach.

**Why not double-tap Caps Lock?** The original design used `CapsLockDetector` monitoring `NSEvent.flagsChanged`, but this proved unreliable — each physical press toggles state (on/off), making double-tap detection timing-sensitive and inconsistent. It also required IOKit/CGEvent workarounds to reset Caps Lock state, and triggered Accessibility permission prompts.

**Permissions:** Carbon `RegisterEventHotKey` works without additional permissions (no Accessibility or Input Monitoring needed).

**File:** `Utilities/GlobalHotkeyManager.swift`

## Ping Modes

User-configurable via settings. Both the hotkey and the menu bar item respect the same mode.

| Mode | Warps cursor to center | Plays ripple |
|------|----------------------|--------------|
| Center + Ripple (default) | Yes | Yes, at screen center |
| Center only | Yes | No |
| Ripple only | No | Yes, at current cursor position |

Ping works regardless of whether crosshair/spotlight are enabled — it is an independent action.

## Ripple Animation

3 concentric `CAShapeLayer` ring strokes that contract inward toward the cursor, guiding the eye to the cursor position.

- **Direction:** Outside-in (large radius → cursor point). Draws the eye inward toward the cursor.
- **Rings:** 3 stroke-only rings (~2pt line width), no fill
- **Starting radius:** ~150pt (internal constant, not user-facing)
- **End radius:** ~0pt (contracts to cursor point)
- **Animation method:** Animate `path` property (not `transform.scale`) so stroke width remains constant as rings contract.
- **Per-ring duration:** 0.4s
- **Stagger:** Each ring starts 0.1s after the previous (`beginTime` offsets)
- **Total duration:** 0.6s (last ring starts at 0.2s, animates for 0.4s)
- **Opacity:** Each ring fades from 1.0 → 0.0 over its 0.4s duration
- **Z-ordering:** Ripple layers are added above all other layers (crosshair, spotlight) since they are temporary
- **Cleanup:** All ripple layers are removed after the final ring's animation completes via `DispatchQueue.main.asyncAfter`

**File:** `Overlay/RippleAnimationManager.swift`

## Auto-Center Action

When triggered (via hotkey or menu bar):

1. Determine current screen (the screen containing the cursor)
2. **Restore visibility:** If crosshair is faded out due to idle timeout, call `fadeIn()` and reset the fade timer
3. Based on ping mode:
   - If centering: convert screen center to CG coordinates via `ScreenUtilities.screenCenter(of:)`, warp cursor with `CGWarpMouseCursorPosition`
   - If rippling without centering: use current cursor position in AppKit coordinates
4. Trigger ripple animation (if mode includes it) on the correct screen's `OverlayView`
5. Post VoiceOver announcement: "Cursor centered" (if centering) or "Ping" (if ripple only)

**Integration:** `AppDelegate.performPing()` orchestrates the action. `OverlayView` exposes a `playRipple(at:)` method. Menu bar button calls `performPing()` via the `AppDelegate` instance passed from `@NSApplicationDelegateAdaptor`.

**Note:** SwiftUI wraps `NSApp.delegate` with its own delegate, so the real `AppDelegate` must be passed directly from the `@NSApplicationDelegateAdaptor` property — casting `NSApp.delegate as? AppDelegate` does not work.

## Sync Color System

A "Sync color" toggle in the Crosshair settings section that unifies the color of crosshair, spotlight border, and ripple.

- **When enabled (default):** Changing the crosshair color immediately updates `rippleColor` and `spotlightBorderColor` in UserDefaults. Individual color pickers in Spotlight and Ping sections are hidden.
- **When disabled:** Individual `ColorPickerRow` controls (preset swatches + color well) appear in the Spotlight section (border color) and Ping section (ripple color).
- `SpotlightRenderer` reads `spotlightBorderColor` (not `crosshairColor`) for the border stroke color.

**Settings keys added:**
- `syncColor` — Bool, default `true`
- `spotlightBorderColor` — String (hex), default `"#FF0000"`

**Files affected:** `SettingsKeys.swift`, `CrosshairSettingsSection.swift`, `SpotlightSettingsSection.swift`, `PingSettingsSection.swift`, `SpotlightRenderer.swift`

## Settings UI

- All labels use sentence case (e.g., "Line thickness", "Dim opacity", "Border width")
- Reusable `ColorPickerRow` component provides consistent preset color swatches + color well across all color settings
- Settings window uses `.fixedSize(horizontal: false, vertical: true)` and `.scrollBounceBehavior(.basedOnSize)` for content-adaptive sizing that accommodates accessibility text size changes
- Settings keys: `pingMode`, `rippleColor`, `syncColor`, `spotlightBorderColor`

## Menu Bar

- "Ping" menu item in `MenuBarMenuContent` in `BeaconApp.swift`
- Calls `appDelegate.performPing()` via direct reference from `@NSApplicationDelegateAdaptor`
- Respects the user's ping mode setting

## Files Created

| File | Purpose |
|------|---------|
| `Utilities/GlobalHotkeyManager.swift` | Cmd-Shift-/ global hotkey via Carbon |
| `Overlay/RippleAnimationManager.swift` | Contracting ripple animation |
| `Settings/PingSettingsSection.swift` | Ping mode + ripple color settings |
| `Settings/ColorPickerRow.swift` | Reusable preset color swatches + color well |

## Files Modified

| File | Changes |
|------|---------|
| `App/AppDelegate.swift` | Create GlobalHotkeyManager, add `performPing()`, restore fade on ping, register new defaults |
| `App/BeaconApp.swift` | Add "Ping" menu item, pass real AppDelegate to menu content |
| `Overlay/OverlayView.swift` | Add `playRipple(at:)` method, create RippleAnimationManager |
| `Overlay/OverlayWindowController.swift` | Add `playRipple(at:)` with global→local coordinate conversion |
| `Overlay/SpotlightRenderer.swift` | Read `spotlightBorderColor` instead of `crosshairColor` |
| `Settings/SettingsKeys.swift` | Add ping keys, sync color keys, PingMode enum |
| `Settings/SettingsView.swift` | Add Ping section, content-adaptive window sizing |
| `Settings/CrosshairSettingsSection.swift` | Add sync color toggle, use ColorPickerRow, sentence case |
| `Settings/SpotlightSettingsSection.swift` | Add border color picker when sync off, sentence case |
| `Settings/PingSettingsSection.swift` | Hide ripple color when sync on |

## Architecture Fit

- Follows existing renderer pattern (CAShapeLayer + explicit CABasicAnimation)
- Settings bridge: @AppStorage in SwiftUI, UserDefaults in AppKit — same pattern as all other features
- Multi-monitor: ripple plays only on the screen containing the cursor, same as crosshair/spotlight visibility logic
- Debug logging via `os.Logger` (subsystem: `com.beacon.app`) with category-based filtering
