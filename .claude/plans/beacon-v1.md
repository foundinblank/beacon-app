# Beacon — macOS Visual Cursor Accessibility Toolkit

## Context

People with visual impairments struggle to track the mouse cursor on macOS. Existing crosshair apps (CrosshairPointer, PrecisionMouse) exist but have limitations: noticeable rendering lag at fast mouse speeds, no auto-center feature, no reading guide, and either cost $10 or lack customization. Beacon will be an accessibility-first crosshair toolkit sold for $0.99 on the App Store (with free copies available on request), differentiated by butter-smooth rendering, a unique auto-center-with-animation feature, and a reading guide — features no competitor offers together.

**Working name**: Beacon (alternative to revisit later: Sightline)

## Tech Stack

- **Swift 6** — strict concurrency, all UI types annotated `@MainActor`
- **AppKit** — for overlay window management (SwiftUI cannot create click-through transparent windows)
- **SwiftUI** — for the settings UI panel and `MenuBarExtra`
- **Core Animation (CAShapeLayer)** — for GPU-accelerated smooth crosshair rendering (move layers instead of redrawing)
- **NSEvent monitors** — global + local monitors for mouse tracking (CGEventTap had issues when backgrounded; revisit if latency becomes noticeable)
- **Carbon RegisterEventHotKey** — for global hotkey without accessibility permission complexity
- **Target**: macOS 14+ (Sonoma)

## Available Skills

The following Claude Code skills are available for use when working on this project:

- **macos-app-design** (project) — macOS application design patterns, menu bar structure, keyboard shortcuts, multi-window behavior
- **macos-development** (project) — macOS development guidance including Swift 6+, SwiftUI, SwiftData, architecture, AppKit bridging
- **swiftui-expert-skill** (user) — SwiftUI best practices for state management, view composition, performance, macOS-specific APIs
- **macos** (user) — macOS platform-specific development with menu bar apps, window management, AppKit integration

## How It Works

A fullscreen, borderless, transparent `NSWindow` floats on top of all content with `ignoresMouseEvents = true` (all clicks pass through). This is the standard macOS overlay pattern used by Apple's own accessibility features, CrossOver, and all crosshair apps. One overlay window per connected monitor, automatically managed on connect/disconnect.

Crosshair lines are `CAShapeLayer` objects whose positions update via `CGEventTap` mouse tracking — GPU-composited, no per-frame redraw. This eliminates the "low framerate" feel of competing apps.

No dock icon (`LSUIElement = true`). App lives in the menu bar only.

## v1 Features

### 1. Crosshair Overlay

- Four line segments (left/right/up/down from cursor)
- Customizable: color, thickness, line style (solid/dashed/dotted)
- Keepout gap around cursor (adjustable)
- Edge gap from screen borders (adjustable)
- Fade out after configurable idle timeout, instant reappear on move

### 2. Spotlight Mode

- Semi-transparent circular highlight around cursor
- Customizable radius, color, opacity

### 3. Reading Guide ("Focus Strip")

- Regions above and below a horizontal band around cursor are dimmed
- Creates a "mail slot" effect for reading lines of text
- Adjustable band height and dim opacity

### 4. Auto-Center

- Global hotkey (default: Cmd+Shift+C) moves cursor to center of current screen
- Flash + fade animation at center point to draw eyes (bright circle scales up and fades out over ~0.5s)
- Also accessible from menu bar

### 5. Menu Bar Interface

- NSStatusItem with icon (SF Symbol `"target"`)
- Toggle crosshair / spotlight / reading guide (with checkmarks)
- "Center Cursor" action
- "Settings..." opens SwiftUI settings panel
- "Quit Beacon"

### 6. Settings Panel (SwiftUI)

- All customization options organized by feature section
- Persisted via UserDefaults/@AppStorage
- Changes take effect immediately on the overlay

### 7. Multi-Monitor

- One overlay window per connected screen
- Automatic detection of monitor connect/disconnect via `NSApplication.didChangeScreenParametersNotification`
- Crosshair follows cursor across screens

## Project Structure

```bash
Beacon/
  Beacon.xcodeproj/
  Beacon/
    App/
      BeaconApp.swift                 -- @main, SwiftUI lifecycle + NSApplicationDelegateAdaptor
      AppDelegate.swift               -- Creates overlays, mouse tracker, hotkey, menu bar
    Overlay/
      OverlayWindowController.swift   -- One fullscreen transparent NSWindow per screen
      OverlayView.swift               -- NSView host for CAShapeLayers
      CrosshairRenderer.swift         -- Creates/updates CAShapeLayer crosshair lines
      SpotlightRenderer.swift         -- Spotlight circle layer
      ReadingGuideRenderer.swift      -- Dimmed region layers above/below cursor
      FlashAnimationView.swift        -- Auto-center flash + fade animation
    Settings/
      SettingsView.swift              -- Main settings panel
      CrosshairSettingsSection.swift  -- Crosshair customization controls
      SpotlightSettingsSection.swift  -- Spotlight controls
      ReadingGuideSettingsSection.swift
      GeneralSettingsSection.swift    -- Hotkey config, fade timeout
    MenuBar/
      MenuBarManager.swift            -- NSStatusItem + menu construction
    Utilities/
      ScreenUtilities.swift           -- Coordinate conversion, screen center calc
      MouseTracker.swift              -- CGEventTap wrapper for low-latency tracking
      HotkeyManager.swift             -- Carbon RegisterEventHotKey wrapper
    Resources/
      Assets.xcassets/                -- App icon, menu bar icon
      Beacon.entitlements             -- App Sandbox + input monitoring
      Info.plist                      -- LSUIElement = true
```

## Implementation Milestones

Each milestone produces a runnable, testable app.

### Milestone 1: Crosshair on Screen

**Goal**: Transparent overlay window with crosshair lines following the mouse using CAShapeLayer + CGEventTap.

**Create Xcode project first**:

1. Xcode > File > New > Project > macOS > App
2. Product Name: Beacon, Interface: SwiftUI, Language: Swift
3. Save to `/Users/adamstone/git/crosshair-app/`
4. Set minimum deployment: macOS 14.0
5. Add `LSUIElement = YES` to Info.plist (no dock icon)
6. Enable App Sandbox in entitlements

**Files**:

- `BeaconApp.swift` — `@main` with `@NSApplicationDelegateAdaptor`, `Settings` scene only (no `WindowGroup`)
- `AppDelegate.swift` — creates one `OverlayWindowController` on `NSScreen.main`, initializes `MouseTracker`
- `OverlayWindowController.swift` — creates `NSWindow` (borderless, transparent, floating, click-through, `canJoinAllSpaces`)
- `OverlayView.swift` — `NSView` with `wantsLayer = true`, hosts crosshair `CAShapeLayer`s
- `CrosshairRenderer.swift` — creates 4 `CAShapeLayer` line segments, updates positions on mouse move
- `MouseTracker.swift` — `CGEventTap` wrapper, fires callback with mouse position
- `ScreenUtilities.swift` — coordinate conversion between AppKit (bottom-left origin) and CoreGraphics (top-left origin)

**Test**: Launch app. Red crosshair follows mouse smoothly. Clicks pass through. No dock icon. Quit via Activity Monitor.

### Milestone 2: Menu Bar + Quit

**Goal**: Menu bar icon with Quit so you can close the app properly.

**Files**:

- `MenuBarManager.swift` — `NSStatusItem` with `NSMenu` containing "Quit Beacon"

**Changes**: `AppDelegate` creates `MenuBarManager`.

**Test**: Target icon in menu bar. Click > "Quit Beacon" terminates app.

### Milestone 3: Settings Model + UI

**Goal**: Crosshair color, thickness, style, gaps configurable via settings panel.

**Files**:

- `SettingsView.swift` — main settings view
- `CrosshairSettingsSection.swift` — `ColorPicker`, `Slider`s, `Picker` for line style
- `GeneralSettingsSection.swift` — fade timeout slider

**Changes**:

- `CrosshairRenderer` reads from `UserDefaults` instead of hardcoded values
- `MenuBarManager` adds "Settings..." item (uses `NSApp.sendAction(Selector(("showSettingsWindow:")))`)

**Note on settings architecture**: SwiftUI views use `@AppStorage` directly. AppKit overlay reads `UserDefaults.standard` on each update. No shared `ObservableObject` needed — both sides use the same `UserDefaults` keys.

**Test**: Open settings from menu bar. Change color to blue, thickness to 5, style to dotted. Crosshair updates immediately.

### Milestone 4: Multi-Monitor

**Goal**: Overlay on all connected screens, handles plug/unplug.

**Changes**:

- `AppDelegate` iterates `NSScreen.screens`, creates one `OverlayWindowController` per screen
- Observes `NSApplication.didChangeScreenParametersNotification` to rebuild overlays
- `OverlayView` converts global `NSEvent.mouseLocation` to local coordinates per-screen

**Test**: Connect external monitor. Crosshair appears on both screens and follows cursor across them.

### Milestone 5: Fade Timeout

**Goal**: Crosshair fades out after idle, reappears on move.

**Changes**:

- `MouseTracker` tracks `lastMoveTime`
- `OverlayView` / crosshair layers animate opacity to 0 after timeout
- Instant reappear (opacity = 1) on next mouse move
- `GeneralSettingsSection` already has fade timeout slider from M3

**Test**: Set fade to 2s. Stop moving mouse. Crosshair smoothly fades. Move mouse — instant reappear.

### Milestone 6: Spotlight Mode

**Goal**: Optional circular highlight around cursor.

**Files**:

- `SpotlightRenderer.swift` — `CAShapeLayer` filled circle, moves with cursor
- `SpotlightSettingsSection.swift` — radius, color, opacity controls

**Changes**: `OverlayView` manages spotlight layer. `MenuBarManager` adds Spotlight toggle.

**Test**: Toggle spotlight on. Semi-transparent circle follows cursor. Adjust radius/opacity in settings.

### Milestone 7: Reading Guide

**Goal**: Dimmed regions above/below cursor band.

**Files**:

- `ReadingGuideRenderer.swift` — two `CAShapeLayer` rectangles (top dim, bottom dim)
- `ReadingGuideSettingsSection.swift` — band height, dim opacity

**Changes**: `OverlayView` manages reading guide layers. `MenuBarManager` adds toggle.

**Test**: Toggle on. Screen dims above and below a clear horizontal strip at cursor height. Adjust band height. Works with crosshair and spotlight simultaneously.

### Milestone 8: Auto-Center + Flash

**Goal**: Global hotkey moves cursor to screen center with flash animation.

**Files**:

- `HotkeyManager.swift` — Carbon `RegisterEventHotKey` wrapper (~50 lines)
- `FlashAnimationView.swift` — `CAShapeLayer` circle with scale-up + fade-out `CABasicAnimation`

**Changes**:

- `AppDelegate.performAutoCenter()` — calls `CGWarpMouseCursorPosition` then triggers flash
- `MenuBarManager` adds "Center Cursor" item
- Settings section for hotkey configuration

**Test**: Press Cmd+Shift+C. Cursor jumps to center of current screen. Bright circle flashes and fades at center.

### Milestone 9: Polish + Edge Cases

- Menu bar checkmarks stay in sync with feature toggles
- Overlay redraws on toggle even when mouse is stationary
- Handle all features disabled (draw nothing)
- Test with Mission Control, fullscreen apps, Spaces
- Test compatibility with Apple Accessibility Zoom (System Settings > Accessibility > Zoom) — verify overlay renders correctly and coordinates stay accurate when Zoom is active
- Add app icon
- First-launch prompt for Input Monitoring permission (needed for CGEventTap)
- Add "Launch at Login" toggle in settings using `SMAppService.mainApp` (macOS 13+)
- Test on macOS 14 and 15

## Technical Notes

**Coordinate systems** (biggest source of bugs):

- AppKit/NSScreen: origin bottom-left, y up
- CoreGraphics/CGWarpMouseCursorPosition: origin top-left, y down
- `ScreenUtilities` handles all conversions

**Permissions**: `CGEventTap` requires Input Monitoring permission (System Settings > Privacy & Security > Input Monitoring). App should detect if not granted and show a user-friendly prompt on first launch.

**Settings pattern**: `@AppStorage("key")` in SwiftUI views, `UserDefaults.standard.double(forKey: "key")` in AppKit. Same keys, no bridging needed.

**NSColor in @AppStorage**: Store colors as hex strings, convert via a small `NSColor` extension.

**Opening Settings from menu bar**: `NSApp.activate(ignoringOtherApps: true)` then `NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)` on macOS 14+.

**Apple Accessibility Zoom compatibility**: macOS Zoom (System Settings > Accessibility > Zoom) can use a fullscreen or picture-in-picture lens that alters the relationship between screen coordinates and visible content. Our overlay windows sit at the NSWindow level, so they should move with Zoom naturally, but this needs testing — especially that crosshair coordinates remain correct and the overlay doesn't interfere with Zoom's own UI. This is a Milestone 9 test case, not an implementation task upfront.

**Launch at Login**: Use `SMAppService.mainApp.register()` (macOS 13+, ServiceManagement framework). Provides a toggle in settings; macOS handles the rest. No legacy LaunchAgent or LoginItem helper needed.

## Verification

After each milestone:

1. Build and run from Xcode (Cmd+R)
2. Verify the feature works as described in that milestone's "Test" section
3. Verify no regressions (previous features still work)
4. Test click-through (can interact with apps beneath overlay)
5. From milestone 4 onward: test with multiple monitors if available

Final verification before release:

- All features work independently and in combination
- Settings persist across app restart
- Multi-monitor connect/disconnect works
- Auto-center works on correct screen
- Crosshair movement is smooth at fast mouse speeds
- App uses minimal CPU/memory (check Activity Monitor)
- App works in all Spaces and alongside fullscreen apps

## Future Enhancements (Post-v1)

- Gradient color animation for auto-center (replace flash with color sweep)
- Audio cues / sonification for cursor position (for hearing low-vision users)
- Pointer trails / motion echo
- Inverted color zone around cursor
- Intentional "reduced motion" / framerate-limit setting
- Customizable hotkeys for toggling individual features
- App Store distribution ($0.99, free on direct request)
