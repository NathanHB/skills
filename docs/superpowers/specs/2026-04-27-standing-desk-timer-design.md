# Standing Desk Timer — Design Spec

**Date:** 2026-04-27
**Platform:** macOS menu bar app (Swift, macOS 13+)

## Overview

A lightweight macOS menu bar app that cycles between a 45-minute sitting phase and a 15-minute standing phase, alerting the user with a macOS notification banner at each transition. The menu bar shows a live countdown at all times.

## State Machine

Two states, cycling indefinitely:

- **Sitting** — 45:00 countdown. On expiry: send "Time to stand!" notification, transition to Standing.
- **Standing** — 15:00 countdown. On expiry: send "Time to sit down!" notification, transition to Sitting.

Start state: Sitting (45:00). The timer always runs — there is no pause.

## Menu Bar Display

The `MenuBarExtra` label updates every second:

- Sitting: `↓ MM:SS`
- Standing: `↑ MM:SS`

## Dropdown UI (ContentView)

Clicking the menu bar item opens a small popover containing:

1. **State label** — "Sitting" or "Standing"
2. **Progress bar** — shows time elapsed as a fraction of the current phase duration
3. **Reset button** — restarts the current phase countdown from the beginning

No other controls.

## Notifications

- On first launch, request `UNUserNotificationCenter` authorization.
- When a phase expires, fire a local notification:
  - Sitting → Standing: title "Time to stand! 🧍"
  - Standing → Sitting: title "Time to sit down! 🪑"
- Notifications are delivered via macOS banner (standard system behavior).

## File Structure

```
StandingTimer/
├── StandingTimerApp.swift   — @main entry, MenuBarExtra scene, requests notification permission on launch
├── TimerViewModel.swift     — ObservableObject: state machine, Timer.publish loop, notification dispatch
└── ContentView.swift        — SwiftUI dropdown: state label, progress bar, reset button
```

## Constraints

- macOS 13+ required (MenuBarExtra API)
- No external dependencies
- Single app target, no unit tests needed for this scope
