# Standing Desk Timer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a macOS menu bar app that cycles between 45-minute sitting and 15-minute standing phases, showing a live countdown in the menu bar and firing a notification banner at each transition.

**Architecture:** Three Swift files — `TimerViewModel` owns the state machine and `Timer.publish` loop, `ContentView` renders the dropdown popup with a progress bar and reset button, and `StandingTimerApp` is the `@main` entry point using `MenuBarExtra`. All Swift files are written first, then `xcodegen` generates the `.xcodeproj` from a `project.yml`.

**Tech Stack:** Swift 5.9, SwiftUI, Combine, UserNotifications, MenuBarExtra (macOS 13+), xcodegen (via Homebrew).

---

### Task 1: Write TimerViewModel

**Files:**
- Create: `apps/StandingTimer/StandingTimer/TimerViewModel.swift`

- [ ] **Step 1: Create the source directory**

```bash
mkdir -p /Users/nathan/Repos/skills/apps/StandingTimer/StandingTimer
```

- [ ] **Step 2: Write TimerViewModel.swift**

Create `apps/StandingTimer/StandingTimer/TimerViewModel.swift`:

```swift
import Foundation
import UserNotifications
import Combine

enum TimerPhase {
    case sitting, standing

    var duration: TimeInterval { self == .sitting ? 45 * 60 : 15 * 60 }
    var next: TimerPhase { self == .sitting ? .standing : .sitting }
    var label: String { self == .sitting ? "Sitting" : "Standing" }
    var prefix: String { self == .sitting ? "↓" : "↑" }
    var notificationTitle: String {
        self == .sitting ? "Time to stand! 🧍" : "Time to sit down! 🪑"
    }
}

class TimerViewModel: ObservableObject {
    @Published var phase: TimerPhase = .sitting
    @Published var remaining: TimeInterval = TimerPhase.sitting.duration

    private var cancellable: AnyCancellable?

    var menuBarTitle: String {
        let m = Int(remaining) / 60
        let s = Int(remaining) % 60
        return "\(phase.prefix) \(String(format: "%02d:%02d", m, s))"
    }

    var progress: Double { 1.0 - (remaining / phase.duration) }

    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        cancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    private func tick() {
        if remaining > 0 {
            remaining -= 1
        } else {
            transition()
        }
    }

    private func transition() {
        sendNotification(for: phase)
        phase = phase.next
        remaining = phase.duration
    }

    func reset() { remaining = phase.duration }

    private func sendNotification(for phase: TimerPhase) {
        let content = UNMutableNotificationContent()
        content.title = phase.notificationTitle
        content.sound = .default
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        )
    }
}
```

- [ ] **Step 3: Commit**

```bash
git -C /Users/nathan/Repos/skills add apps/StandingTimer/StandingTimer/TimerViewModel.swift
git -C /Users/nathan/Repos/skills commit -m "feat: add TimerViewModel — state machine and notification dispatch"
```

---

### Task 2: Write ContentView

**Files:**
- Create: `apps/StandingTimer/StandingTimer/ContentView.swift`

- [ ] **Step 1: Write ContentView.swift**

Create `apps/StandingTimer/StandingTimer/ContentView.swift`:

```swift
import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: TimerViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.phase.label)
                .font(.headline)

            ProgressView(value: viewModel.progress)
                .progressViewStyle(.linear)

            Button("Reset") { viewModel.reset() }
                .buttonStyle(.borderless)
        }
        .padding()
        .frame(width: 200)
    }
}
```

- [ ] **Step 2: Commit**

```bash
git -C /Users/nathan/Repos/skills add apps/StandingTimer/StandingTimer/ContentView.swift
git -C /Users/nathan/Repos/skills commit -m "feat: add ContentView dropdown with progress bar and reset button"
```

---

### Task 3: Write StandingTimerApp entry point

**Files:**
- Create: `apps/StandingTimer/StandingTimer/StandingTimerApp.swift`

- [ ] **Step 1: Write StandingTimerApp.swift**

Create `apps/StandingTimer/StandingTimer/StandingTimerApp.swift`:

```swift
import SwiftUI

@main
struct StandingTimerApp: App {
    @StateObject private var viewModel = TimerViewModel()

    var body: some Scene {
        MenuBarExtra {
            ContentView(viewModel: viewModel)
        } label: {
            Text(viewModel.menuBarTitle)
                .monospacedDigit()
        }
        .menuBarExtraStyle(.window)
    }
}
```

- [ ] **Step 2: Commit**

```bash
git -C /Users/nathan/Repos/skills add apps/StandingTimer/StandingTimer/StandingTimerApp.swift
git -C /Users/nathan/Repos/skills commit -m "feat: add StandingTimerApp @main entry point"
```

---

### Task 4: Generate Xcode project and build

**Files:**
- Create: `apps/StandingTimer/project.yml`
- Create: `apps/StandingTimer/StandingTimer.xcodeproj` (generated)

- [ ] **Step 1: Ensure xcodegen is installed**

```bash
which xcodegen || brew install xcodegen
```

Expected: a path like `/opt/homebrew/bin/xcodegen`

- [ ] **Step 2: Write project.yml**

Create `apps/StandingTimer/project.yml`:

```yaml
name: StandingTimer
options:
  bundleIdPrefix: com.nathanhabib
  deploymentTarget:
    macOS: "13.0"
targets:
  StandingTimer:
    type: application
    platform: macOS
    sources: [StandingTimer]
    info:
      path: StandingTimer/Info.plist
      properties:
        LSUIElement: YES
        CFBundleDisplayName: StandingTimer
    settings:
      base:
        SWIFT_VERSION: "5.9"
        CODE_SIGN_STYLE: Automatic
        PRODUCT_BUNDLE_IDENTIFIER: com.nathanhabib.StandingTimer
```

- [ ] **Step 3: Generate the Xcode project**

```bash
cd /Users/nathan/Repos/skills/apps/StandingTimer && xcodegen generate
```

Expected: `✅ Created project at StandingTimer.xcodeproj`

- [ ] **Step 4: Build**

```bash
cd /Users/nathan/Repos/skills/apps/StandingTimer && xcodebuild \
  -scheme StandingTimer \
  -destination 'platform=macOS' \
  -configuration Debug \
  SYMROOT=build \
  build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Launch the app to verify**

```bash
open /Users/nathan/Repos/skills/apps/StandingTimer/build/Debug/StandingTimer.app
```

Verify:
- Menu bar shows `↓ 45:00` counting down every second
- Clicking the menu bar item opens a dropdown with "Sitting" label, a progress bar, and a Reset button
- Reset button resets the countdown to 45:00
- On first launch, macOS asks for notification permission — grant it

- [ ] **Step 6: Commit**

```bash
git -C /Users/nathan/Repos/skills add apps/StandingTimer/project.yml apps/StandingTimer/StandingTimer.xcodeproj
git -C /Users/nathan/Repos/skills commit -m "chore: add xcodegen project for StandingTimer"
```
