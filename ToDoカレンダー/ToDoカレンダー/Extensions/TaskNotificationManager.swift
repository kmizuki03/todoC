import Foundation
import SwiftData
import UserNotifications

enum TaskNotificationError: LocalizedError {
    case authorizationDenied
    case authorizationRequestFailed(underlying: Error)
    case schedulingFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "通知が許可されていません。設定アプリで通知を許可してください。"
        case .authorizationRequestFailed:
            return "通知の許可リクエストに失敗しました。"
        case .schedulingFailed:
            return "通知の登録に失敗しました。"
        }
    }
}

struct TaskNotificationErrorPresentation {
    let message: String
    let canOpenSettings: Bool
}

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

    static func requestAuthorizationIfNeededThrowing() async throws {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .notDetermined:
            do {
                _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                throw TaskNotificationError.authorizationRequestFailed(underlying: error)
            }
        default:
            return
        }
    }

    static func sync(for item: TodoItem) {
        Task {
            _ = try? await syncThrowing(for: item)
        }
    }

    static func syncThrowing(for item: TodoItem) async throws {
        cancel(for: item)

        guard item.isTimeSet else { return }
        guard !item.isCompleted else { return }
        guard item.date > Date() else { return }

        try await requestAuthorizationIfNeededThrowing()

        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            break
        default:
            throw TaskNotificationError.authorizationDenied
        }

        try await scheduleThrowing(for: item)
    }

    static func cancel(for item: TodoItem) {
        let identifier = notificationIdentifier(for: item)
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
    }

    private static func scheduleThrowing(for item: TodoItem) async throws {
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

        let request = UNNotificationRequest(
            identifier: identifier, content: content, trigger: trigger)

        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, Error>) in
            UNUserNotificationCenter.current().add(request) { error in
                if let error {
                    continuation.resume(
                        throwing: TaskNotificationError.schedulingFailed(underlying: error))
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private static func notificationIdentifier(for item: TodoItem) -> String {
        // persistentModelIDは安定した識別子として使える
        "todo-\(item.persistentModelID)"
    }

    static func presentation(for error: Error) -> TaskNotificationErrorPresentation {
        if let typed = error as? TaskNotificationError {
            switch typed {
            case .authorizationDenied:
                return .init(message: typed.localizedDescription, canOpenSettings: true)
            default:
                return .init(message: typed.localizedDescription, canOpenSettings: false)
            }
        }

        return .init(message: error.localizedDescription, canOpenSettings: false)
    }
}
