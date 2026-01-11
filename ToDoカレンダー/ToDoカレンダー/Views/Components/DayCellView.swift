//
//  DayCellView.swift
//  ToDoカレンダー
//
//  Created by 加藤 瑞樹 on 2026/01/03.
//

import SwiftUI
import SwiftData

struct DayCellView: View {
    let date: Date
    let isSelected: Bool
    let targetCalendar: AppCalendar
    let showAllCalendars: Bool
    
    @Query private var tasks: [TodoItem]
    
    init(date: Date, isSelected: Bool, targetCalendar: AppCalendar, showAllCalendars: Bool = false) {
        self.date = date
        self.isSelected = isSelected
        self.targetCalendar = targetCalendar
        self.showAllCalendars = showAllCalendars
        
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        let calendarID = targetCalendar.persistentModelID // IDで検索用
        
        // 日付一致。メイン表示のときは全カレンダー、それ以外はカレンダー一致。
        let showAll = showAllCalendars
        let predicate = #Predicate<TodoItem> { item in
            item.date >= start && item.date < end && (showAll || item.calendar?.persistentModelID == calendarID)
        }
        _tasks = Query(filter: predicate)
    }
    
    var body: some View {
        // (見た目のコードは以前と同じなので変更なし。そのまま使ってください)
        let total = tasks.count
        let completed = tasks.filter { $0.isCompleted }.count
        let percentage = total > 0 ? Int((Double(completed) / Double(total)) * 100) : 0

        let weekday = Calendar.current.component(.weekday, from: date)
        let isSunday = weekday == 1
        let isSaturday = weekday == 7
        let holidayName = JapaneseHoliday.holidayName(date)
        let isHoliday = holidayName != nil

        let dayTextColor: Color = {
            if isHoliday || isSunday { return .red }
            if isSaturday { return .blue }
            if Calendar.current.isDateInToday(date) { return .blue }
            return .primary
        }()
        
        ZStack {
            if isSelected {
                Circle().fill(Color.blue.opacity(0.2))
            }
            VStack(spacing: 2) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(dayTextColor)

                if let holidayName {
                    Text(holidayName)
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(.red)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                if total > 0 {
                    Text("\(percentage)%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(percentage == 100 ? .green : .secondary)
                } else {
                    Text(" ").font(.system(size: 10))
                }
            }
        }
        .frame(height: holidayName == nil ? 45 : 52)
    }
}
