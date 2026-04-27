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
