# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Beacon is a macOS menu-bar-only accessibility app that helps visually impaired users track the mouse cursor. It provides a crosshair overlay, spotlight mode, reading guide ("focus strip"), and auto-center with flash animation. No dock icon (`LSUIElement = true`). Target: macOS 14+ (Sonoma), App Store distribution.


## Tech Stack

- **Swift 6** with strict concurrency — all UI types annotated `@MainActor`
- **AppKit** (overlay windows) + **SwiftUI** (settings panel only)
- **Core Animation** (`CAShapeLayer`) for GPU-accelerated rendering
- **NSEvent monitors** (global + local) for mouse tracking
- **Carbon `RegisterEventHotKey`** for global hotkeys
- **UserDefaults / @AppStorage** for settings persistence

## Build & Run

This is an Xcode project. No external dependencies.

```
# Build from command line
xcodebuild -project Beacon/Beacon.xcodeproj -scheme Beacon build

# Run from Xcode: Cmd+R
```

## Architecture

### Overlay System
Fullscreen borderless transparent `NSPanel` (subclass with `canBecomeKey = false`) per monitor with `ignoresMouseEvents = true` (clicks pass through). Each window hosts an `NSView` with `CAShapeLayer` objects for crosshair lines, spotlight circle, and reading guide regions. Layer positions are updated via `NSEvent` monitor callback — no per-frame redraw. Only the overlay on the screen containing the cursor renders; others hide via layer opacity.

### Settings Bridge (AppKit ↔ SwiftUI)
SwiftUI views use `@AppStorage("key")`. AppKit overlay reads `UserDefaults.standard` with the same keys. No shared `ObservableObject` — both sides read/write the same `UserDefaults` keys directly. Colors stored as hex strings, converted via `NSColor` extension.

### App Entry Point
`@main` SwiftUI app with `@NSApplicationDelegateAdaptor`. Uses a `Settings` scene only (no `WindowGroup`). `AppDelegate` creates overlays, mouse tracker, hotkey manager, and menu bar.

### Multi-Monitor
One `OverlayWindowController` per `NSScreen`. Rebuilt on `NSApplication.didChangeScreenParametersNotification`. Crosshair follows cursor across screens by converting global mouse coordinates to per-screen local coordinates.

## Critical Gotcha: Coordinate Systems

This is the biggest source of bugs:
- **AppKit/NSScreen**: origin bottom-left, y increases upward
- **CoreGraphics/CGWarpMouseCursorPosition**: origin top-left, y increases downward

All conversions go through `ScreenUtilities`. Always use it — never convert coordinates inline.

## Permissions

Currently using `NSEvent` monitors which don't require Input Monitoring permission. If we switch back to `CGEventTap` for lower latency, it will require **Input Monitoring** permission (System Settings > Privacy & Security > Input Monitoring) and the app must detect if not granted and prompt the user on first launch.

## Verification Checklist

After each change:
1. Build and run
2. Verify the feature works
3. Verify no regressions on previous features
4. Test click-through (can interact with apps beneath overlay)
5. Test with multiple monitors if available
6. Check CPU/memory usage isn't excessive (Activity Monitor)

## Bug Fixes

When fixing bugs in Swift/SwiftUI, do NOT speculatively refactor adjacent code. Fix only the reported issue. Ask before making additional changes.

## macOS / Swift Development

For macOS development: prefer NSEvent monitors over CGEventTap for background tracking, remember y-coordinate flipping for screen coordinates, and avoid deprecated AppKit APIs. Always verify API availability for the target macOS version before using it.

## Workflow

After any Swift code change, run a build (`xcodebuild`) before committing to catch @MainActor isolation, concurrency, and type errors early.