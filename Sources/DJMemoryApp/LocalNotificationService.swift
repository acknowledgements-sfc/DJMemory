import Foundation
import UserNotifications

struct LocalNotificationService {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func notifyArchiveSaved(count: Int) {
        guard count > 0 else { return }

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
}
