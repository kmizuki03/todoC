import Combine
import Foundation
import SwiftData

@MainActor
final class AppStartupViewModel: ObservableObject {
    func bootstrap(modelContext: ModelContext, contentViewModel: ContentViewModel) async {
        if let defaultCalendar = AppCalendarIntegrity.ensureDefaultCalendarExists(
            modelContext: modelContext)
        {
            if contentViewModel.selectedCalendar == nil {
                contentViewModel.selectedCalendar = defaultCalendar
            }
        }

        await TaskNotificationManager.requestAuthorizationIfNeeded()
    }
}
