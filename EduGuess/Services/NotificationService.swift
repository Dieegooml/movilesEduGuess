import Foundation
import UserNotifications

actor NotificationService {
    static let shared = NotificationService()

    func requestPermission() {
        Task { @MainActor in
            try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        }
    }

    func scheduleDailyChallengeReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["daily_challenge"])

        let content = UNMutableNotificationContent()
        content.title = "Desafío Diario"
        content.body = "¡El personaje del día ya está disponible! Ven a adivinarlo."
        content.sound = .default

        var components = DateComponents()
        components.hour = 8
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_challenge", content: content, trigger: trigger)
        center.add(request)
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
