import Combine
import Foundation
import SwiftUI

@MainActor
final class CalendarViewModel: ObservableObject {
    @Published var selectedDate: Date
    @Published var currentMonth: Date
    @Published var isCalendarCollapsed: Bool

    init(
        selectedDate: Date = Date(),
        currentMonth: Date = Date(),
        isCalendarCollapsed: Bool = false
    ) {
        self.selectedDate = selectedDate
        self.currentMonth = currentMonth.startOfMonth()
        self.isCalendarCollapsed = isCalendarCollapsed
    }

    func changeMonth(by value: Int) {
        guard let shifted = Calendar.current.date(byAdding: .month, value: value, to: currentMonth)
        else { return }
        let newMonth = shifted.startOfMonth()

        withAnimation(.easeInOut(duration: 0.2)) {
            currentMonth = newMonth
            selectedDate = selectedDate.adjustedDate(inMonth: newMonth)
        }
    }

    func goToToday() {
        let today = Date()
        withAnimation(.easeInOut(duration: 0.2)) {
            currentMonth = today.startOfMonth()
            selectedDate = today
        }
    }

    /// 同じ日を再タップした場合は true（= 追加シートを出すなどの用途）
    func selectDate(_ date: Date) -> Bool {
        let isSameDay = Calendar.current.isDate(date, inSameDayAs: selectedDate)
        selectedDate = date
        return isSameDay
    }
}
