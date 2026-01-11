import Combine
import Foundation
import SwiftData

final class ContentViewModel: ObservableObject {
    @Published var selectedCalendar: AppCalendar?

    // シート表示
    @Published var isShowingAddSheet = false
    @Published var isShowingTemplateManager = false
    @Published var isShowingCalendarManager = false

    // 新規カレンダー
    @Published var isShowingNewCalendarAlert = false
    @Published var newCalendarName = ""

    // 通知エラー表示
    let notificationError = NotificationErrorViewModel()

    func createNewCalendar(modelContext: ModelContext) {
        let trimmed = newCalendarName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let newCal = AppCalendar(name: trimmed, isDefault: false)
        modelContext.insert(newCal)

        selectedCalendar = newCal
        newCalendarName = ""
    }

    func presentNotificationError(_ error: Error) {
        notificationError.present(error)
    }
}
