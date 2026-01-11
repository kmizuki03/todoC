import Foundation
import UserNotifications
import SwiftData

enum TaskNotificationManager {
    static func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .notDetermined:
            do {
                _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                return
            }
        default:
            return
        }
    }

    static func sync(for item: TodoItem) {
        cancel(for: item)

        guard item.isTimeSet else { return }
        guard !item.isCompleted else { return }
        guard item.date > Date() else { return }

        schedule(for: item)
    }

    static func cancel(for item: TodoItem) {
        let identifier = notificationIdentifier(for: item)
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
    }

    private static func schedule(for item: TodoItem) {
        let identifier = notificationIdentifier(for: item)

        let content = UNMutableNotificationContent()
        content.title = item.title

        var detailParts: [String] = []
        if let calendarName = item.calendar?.name {
            detailParts.append(calendarName)
        }
        if !item.location.isEmpty {
            detailParts.append(item.location)
        }
        content.body = detailParts.joined(separator: " ・ ")
        content.sound = .default

        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: item.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    private static func notificationIdentifier(for item: TodoItem) -> String {
        // persistentModelIDは安定した識別子として使える
        "todo-\(item.persistentModelID)"
    }
}
