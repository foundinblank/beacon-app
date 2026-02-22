# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Beacon is a macOS menu-bar-only accessibility app that helps visually impaired users track the mouse cursor. It provides a crosshair overlay, spotlight mode, reading guide ("focus strip"), and auto-center with flash animation. No dock icon (`LSUIElement = true`). Target: macOS 14+ (Sonoma), App Store distribution.

Full specification: `.claude/plans/beacon-v1.md`

## Tech Stack

- **Swift** with **AppKit** (overlay windows) + **SwiftUI** (settings panel only)
- **Core Animation** (`CAShapeLayer`) for GPU-accelerated rendering
- **CGEventTap** for low-latency mouse tracking
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
Fullscreen borderless transparent `NSWindow` per monitor with `ignoresMouseEvents = true` (clicks pass through). Each window hosts an `NSView` with `CAShapeLayer` objects for crosshair lines, spotlight circle, and reading guide regions. Layer positions are updated via `CGEventTap` callback — no per-frame redraw.

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

`CGEventTap` requires **Input Monitoring** permission (System Settings > Privacy & Security > Input Monitoring). The app must detect if not granted and prompt the user on first launch.

## Verification Checklist

After each change:
1. Build and run
2. Verify the feature works
3. Verify no regressions on previous features
4. Test click-through (can interact with apps beneath overlay)
5. Test with multiple monitors if available
6. Check CPU/memory usage isn't excessive (Activity Monitor)
