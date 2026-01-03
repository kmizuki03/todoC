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
    let targetCalendar: AppCalendar // ← 追加
    
    @Query private var tasks: [TodoItem]
    
    init(date: Date, isSelected: Bool, targetCalendar: AppCalendar) {
        self.date = date
        self.isSelected = isSelected
        self.targetCalendar = targetCalendar
        
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        let calendarID = targetCalendar.persistentModelID // IDで検索用
        
        // 日付 かつ カレンダーが一致するもの
        let predicate = #Predicate<TodoItem> { item in
            item.date >= start && item.date < end && item.calendar?.persistentModelID == calendarID
        }
        _tasks = Query(filter: predicate)
    }
    
    var body: some View {
        // (見た目のコードは以前と同じなので変更なし。そのまま使ってください)
        let total = tasks.count
        let completed = tasks.filter { $0.isCompleted }.count
        let percentage = total > 0 ? Int((Double(completed) / Double(total)) * 100) : 0
        
        ZStack {
            if isSelected {
                Circle().fill(Color.blue.opacity(0.2))
            }
            VStack(spacing: 2) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Calendar.current.isDateInToday(date) ? .blue : .primary)
                if total > 0 {
                    Text("\(percentage)%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(percentage == 100 ? .green : .secondary)
                } else {
                    Text(" ").font(.system(size: 10))
                }
            }
        }
        .frame(height: 45)
    }
}
