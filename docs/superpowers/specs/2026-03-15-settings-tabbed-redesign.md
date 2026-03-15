# Settings Panel Tabbed Redesign

## Problem

1. Menu bar has Crosshair and Spotlight toggles, but the settings panel only has a Spotlight toggle — inconsistent.
2. The settings panel is a single scrolling form that resizes dynamically with `.fixedSize(vertical: true)`, which causes it to spill off the screen edge when sections expand.
3. Adding a crosshair enable toggle raises the question of where color pickers belong across features.

## Design

### Tab Structure

Replace the single scrolling `Form` in `SettingsView` with a `TabView` using 4 text-only tab labels (segmented style). Each tab contains its own `Form` with `.formStyle(.grouped)`.

**Tabs:** Crosshair | Spotlight | Ping | General

Default selected tab: Crosshair. Persist last-selected tab across opens via `@AppStorage("selectedSettingsTab")`.

### Window Sizing

- Use `@ScaledMetric` for `idealWidth` (currently 450, already exists).
- Set `minWidth: 400`, `minHeight: 300`, `idealHeight: 400`.
- **No `.fixedSize(vertical: true)`** — content scrolls internally within each tab if it exceeds the window height (important for Dynamic Type / large text accessibility).
- Keep `.scrollBounceBehavior(.basedOnSize)`.

### Color Model

A new `masterColor` settings key stores the global color used when sync is enabled. This replaces the old model where crosshair color was the sync source.

**When "Sync color" is ON (in General tab):**
- General tab: color picker is **active** — this is the master color all features use.
- Crosshair/Spotlight/Ping tabs: color pickers are **disabled/grayed out** with a hint: *"Color is set in the General tab"*.
- AppKit renderers read `masterColor` instead of their per-feature color key.

**When "Sync color" is OFF:**
- General tab: color picker is **disabled/grayed out** (not in use).
- Crosshair/Spotlight/Ping tabs: each color picker is **active** and independent.
- AppKit renderers read their per-feature color key as before.

### Tab Contents

#### Crosshair Tab
- **Enable Crosshair** toggle
- **Color** picker row (disabled with hint when sync on)
- **Thickness** slider (0.5–10 px, step 0.5)
- **Line style** picker (Solid, Dashed, Dotted)
- **Dash length** slider (1–20 px, shown when dashed)
- **Spacing** slider (1–20 px, shown when dashed/dotted)

All controls below "Enable Crosshair" are always visible regardless of toggle state (the tab has room and hiding them would be jarring in a dedicated tab).

#### Spotlight Tab
- **Enable Spotlight** toggle
- **Radius** slider (25–300 px, step 5)
- **Dim opacity** slider (0.0–1.0 stored, displayed as 0–100%, step 0.05)
- **Border width** slider (0–10 px, step 0.5)
- **Border color** picker row — visibility rules:
  - Sync ON: shown as disabled with hint *"Color is set in the General tab"* (regardless of border width)
  - Sync OFF, border width > 0: shown and active
  - Sync OFF, border width = 0: hidden

All controls below "Enable Spotlight" are always visible regardless of toggle state.

#### Ping Tab
- **Shortcut** static label: ⌘⇧/
- **Mode** segmented picker (Center + Ripple, Center Only, Ripple Only)
- **Ripple color** picker row — visibility rules:
  - Sync ON: shown as disabled with hint *"Color is set in the General tab"* (regardless of mode)
  - Sync OFF, mode includes ripple: shown and active
  - Sync OFF, mode is Center Only: hidden

#### General Tab
- **Sync color** toggle
- **Color** picker row (disabled when sync off; active when sync on)
- **Fade after idle** slider (0–10s, step 0.5)
- **Launch at Login** toggle

### Settings Keys Changes

| Key | Type | Default | Notes |
|-----|------|---------|-------|
| `masterColor` | String (hex) | `"#FF0000"` | New. Add to both `SettingsKeys` and `SettingsDefaults`. Also add `masterNSColor` to `SettingsDefaults`. |
| `crosshairEnabled` | Bool | `true` | Already exists (added in M9). |
| `syncColor` | Bool | `true` | Already exists. |
| `selectedSettingsTab` | Int | `0` | New. Persists last-selected tab index. |

All other existing keys unchanged.

### File Changes

| Action | File | Notes |
|--------|------|-------|
| Modify | `SettingsView.swift` | Replace `Form` with `TabView`, update frame constraints, add `@AppStorage` for selected tab |
| Rename | `CrosshairSettingsSection.swift` → `CrosshairSettingsTab.swift` | Rename struct, wrap in own `Form`, add enable toggle, add sync-aware color picker |
| Rename | `SpotlightSettingsSection.swift` → `SpotlightSettingsTab.swift` | Rename struct, wrap in own `Form`, add sync-aware border color |
| Rename | `PingSettingsSection.swift` → `PingSettingsTab.swift` | Rename struct, wrap in own `Form`, add sync-aware ripple color |
| Rename | `GeneralSettingsSection.swift` → `GeneralSettingsTab.swift` | Rename struct, wrap in own `Form`, add master color picker, move sync toggle here |
| Modify | `SettingsKeys.swift` | Add `masterColor` key + default + NSColor constant |
| Modify | `AppDelegate.swift` | Migration logic (before `register`), register `masterColor` default |
| Modify | `CrosshairRenderer.swift` | Read `masterColor` when `syncColor` is true; cache the resolved color, not the raw key |
| Modify | `SpotlightRenderer.swift` | Read `masterColor` when `syncColor` is true; cache the resolved color |
| Modify | `RippleAnimationManager.swift` | Read `masterColor` when `syncColor` is true |

### Renderer Color Logic

Each renderer reads color based on sync state. The `else` branch must read each renderer's **own** per-feature key — not `crosshairColor` for all.

**CrosshairRenderer:**
```swift
let colorHex: String
if defaults.object(forKey: SettingsKeys.syncColor) as? Bool ?? SettingsDefaults.syncColor {
    colorHex = defaults.string(forKey: SettingsKeys.masterColor) ?? SettingsDefaults.masterColor
} else {
    colorHex = defaults.string(forKey: SettingsKeys.crosshairColor) ?? SettingsDefaults.crosshairColor
}
```

**SpotlightRenderer:**
```swift
let borderColorHex: String
if defaults.object(forKey: SettingsKeys.syncColor) as? Bool ?? SettingsDefaults.syncColor {
    borderColorHex = defaults.string(forKey: SettingsKeys.masterColor) ?? SettingsDefaults.masterColor
} else {
    borderColorHex = defaults.string(forKey: SettingsKeys.spotlightBorderColor) ?? SettingsDefaults.spotlightBorderColor
}
```

**RippleAnimationManager:**
```swift
let rippleColorHex: String
if defaults.object(forKey: SettingsKeys.syncColor) as? Bool ?? SettingsDefaults.syncColor {
    rippleColorHex = defaults.string(forKey: SettingsKeys.masterColor) ?? SettingsDefaults.masterColor
} else {
    rippleColorHex = defaults.string(forKey: SettingsKeys.rippleColor) ?? SettingsDefaults.rippleColor
}
```

**Cache invalidation:** Renderers with change-detection caches (`lastColorHex`) must cache the **resolved** color (after the sync branch), not the raw per-feature key value. This ensures that changing `masterColor` while sync is on triggers a repaint even if the per-feature color hasn't changed.

### Migration

**Important:** Migration must run **before** `defaults.register(defaults:)`, because `register` fills in default values for unset keys, which would make the "has no stored value" check always false.

In `AppDelegate.applicationDidFinishLaunching`, before the `register(defaults:)` call:

```swift
// One-time migration: copy crosshairColor → masterColor for existing users
if defaults.object(forKey: SettingsKeys.masterColor) == nil,
   let existingColor = defaults.string(forKey: SettingsKeys.crosshairColor) {
    defaults.set(existingColor, forKey: SettingsKeys.masterColor)
}
```

### Sync Toggle Migration

The old `CrosshairSettingsSection` has `onChange` handlers that propagate crosshair color to `rippleColor` and `spotlightBorderColor` when sync is toggled. These handlers must be **removed** — they conflict with the new model where `masterColor` is the source of truth at render time. Per-feature color keys should only be written when the user changes them directly via their tab's color picker.

### Accessibility

- All existing VoiceOver labels, values, and hints preserved on every control.
- `@ScaledMetric` for width scaling with Dynamic Type.
- No fixed vertical size — scrolls internally for large text.
- Increase Contrast and Reduce Motion support unaffected.
- Disabled color pickers still accessible to VoiceOver (announced as disabled).
- `LaunchAtLogin` reads `SMAppService.mainApp.status` at view init time; SwiftUI `TabView` may defer tab body evaluation, but this is acceptable since the status is stable.
