# Milestone 6: Spotlight Mode — Design Spec

## Summary

Add an inverted spotlight effect: the entire screen is dimmed except for a clear circle around the cursor, creating a stage-spotlight effect that helps visually impaired users locate and track the cursor.

## Visual Effect

- **Technique**: Single `CAShapeLayer` with a compound path — full-screen rectangle + circular cutout at cursor position, using even-odd fill rule
- **Dim color**: Black
- **Dim opacity**: User-configurable (default 0.5)
- **Circle radius**: User-configurable (default 100px)
- **Disabled by default** — user enables via menu bar toggle or settings

## Future Enhancement

Option A (filled semi-transparent highlight disc) will be added as an alternative spotlight style in a future milestone, giving users a choice between inverted spotlight and highlight disc based on their vision needs.

## New Files

### `SpotlightRenderer.swift`
- Follows existing renderer pattern (`CrosshairRenderer` as template)
- `@MainActor` class
- **`setup(in: CALayer, bounds: NSRect)`** — creates one `CAShapeLayer`, disables implicit animations via `NSNull()` actions, subscribes to `UserDefaults.didChangeNotification`
- **`updatePosition(_ position: NSPoint, bounds: NSRect)`** — builds compound `CGMutablePath` (`addRect` for screen bounds + `addEllipse` for circle cutout centered on cursor), guards early if position/bounds unchanged. Caches `lastDrawnPosition` and `lastDrawnBounds`.
- **`applySettings()`** — reads `spotlightEnabled`, `spotlightRadius`, `spotlightDimOpacity` from UserDefaults; hides layer when disabled; caches `lastEnabled`, `lastRadius`, `lastDimOpacity` to skip redundant updates
- Fill rule: `.evenOdd` on the shape layer
- Fill color: `NSColor.black.withAlphaComponent(dimOpacity).cgColor`

### `SpotlightSettingsSection.swift`
- SwiftUI `Section("Spotlight")` following `CrosshairSettingsSection` pattern
- `@AppStorage` bindings for all spotlight settings
- Controls:
  - Toggle: Enable/disable spotlight
  - Slider: Circle radius (25–300px)
  - Slider: Dim opacity (0.1–0.9)

## Modified Files

### `SettingsKeys.swift`
Add keys and defaults:
- `spotlightEnabled` (Bool, default `false`)
- `spotlightRadius` (Double, default `100.0`)
- `spotlightDimOpacity` (Double, default `0.5`)

### `OverlayView.swift`
- Add `SpotlightRenderer` instance
- Call `setup()` in init
- Call `updatePosition()` in `updateCursorPosition(_:)`

### `SettingsView.swift`
- Add `SpotlightSettingsSection()` between Crosshair and General sections

### `BeaconApp.swift` (MenuBarMenuContent)
- Add "Spotlight" toggle with `@AppStorage(SettingsKeys.spotlightEnabled)` checkmark

## Behavior Details

- **Fade timeout**: Applies automatically — spotlight layer is a child of `OverlayView.layer`, so it fades/reappears with the crosshair
- **Multi-monitor**: Works automatically — one `SpotlightRenderer` per `OverlayView` per screen
- **When disabled**: Layer is hidden, `updatePosition` returns early (no path computation)
- **Click-through**: Unaffected — overlay window already has `ignoresMouseEvents = true`
- **Interaction with crosshair**: Both render simultaneously — crosshair lines appear on top of the spotlight dim (layer ordering: spotlight first, crosshair second)

## Settings Defaults

| Key | Type | Default | Range |
|-----|------|---------|-------|
| `spotlightEnabled` | Bool | `false` | — |
| `spotlightRadius` | Double | `100.0` | 25–300 |
| `spotlightDimOpacity` | Double | `0.5` | 0.1–0.9 |

## Test Plan

1. Toggle spotlight on from menu bar — screen dims except circle around cursor
2. Move mouse — clear circle follows smoothly
3. Adjust radius in settings — circle size changes immediately
4. Adjust opacity in settings — dim level changes immediately
5. Toggle off — dim disappears, crosshair still works
6. Test with crosshair enabled simultaneously
7. Test fade timeout — spotlight fades with crosshair
8. Test multi-monitor — spotlight appears on active screen only
9. Test click-through — can interact with apps beneath dim overlay
10. Check CPU/memory usage in Activity Monitor
