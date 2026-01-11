import Combine
import Foundation

@MainActor
final class NotificationErrorViewModel: ObservableObject {
    @Published var isPresented = false
    @Published var message = ""
    @Published var canOpenSettings = false

    func present(_ error: Error) {
        let presentation = TaskNotificationManager.presentation(for: error)
        message = presentation.message
        canOpenSettings = presentation.canOpenSettings
        isPresented = true
    }
}
