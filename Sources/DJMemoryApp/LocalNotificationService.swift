import Foundation
import UserNotifications

struct LocalNotificationService {
    /// UserNotifications requires a real `.app` bundle. SPM/Xcode package runs
    /// (Products/Debug/DJMemoryApp) have no bundle proxy and assert on `.current()`.
    static var canUseUserNotifications: Bool {
        Bundle.main.bundleURL.pathExtension.lowercased() == "app"
    }

    private let center: UNUserNotificationCenter?

    init(center: UNUserNotificationCenter? = nil) {
        if let center {
            self.center = center
        } else if Self.canUseUserNotifications {
            self.center = .current()
        } else {
            self.center = nil
        }
    }

    func requestAuthorization() {
        center?.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func notifyArchiveSaved(count: Int) {
        guard let center, count > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Set saved"
        content.body = count == 1
            ? "DJMemory archived a completed recording."
            : "DJMemory archived \(count) completed recordings."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "archive-saved-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        center.add(request)
    }

    static func captureStartedBody(displayName _: String, at date: Date = Date(), calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        return String(format: "Recording started - %02d:%02d", hour, minute)
    }

    func notifyCaptureStarted(displayName: String, at date: Date = Date()) {
        guard let center else { return }

        let content = UNMutableNotificationContent()
        content.title = "Recording started"
        content.body = Self.captureStartedBody(displayName: displayName, at: date)
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "capture-started-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        center.add(request)
    }
}
