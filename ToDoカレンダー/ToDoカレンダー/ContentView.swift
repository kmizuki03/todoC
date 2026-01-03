//
//  ContentView.swift
//  ToDoカレンダー
//
//  Created by 加藤 瑞樹 on 2026/01/03.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AppCalendar.name) private var allCalendars: [AppCalendar]
    
    @State private var selectedCalendar: AppCalendar?
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    
    // シート表示用フラグ
    @State private var isShowingAddSheet = false
    @State private var isShowingTemplateManager = false // ← 追加
    @State private var isShowingNewCalendarAlert = false
    @State private var newCalendarName = ""

    let daysOfWeek = ["日", "月", "火", "水", "木", "金", "土"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 1. カレンダー選択ヘッダー
                if let calendar = selectedCalendar {
                    HStack {
                        Menu {
                            ForEach(allCalendars) { cal in
                                Button(cal.name) { selectedCalendar = cal }
                            }
                            Divider()
                            Button("＋ カレンダーを追加") { isShowingNewCalendarAlert = true }
                        } label: {
                            HStack {
                                Text(calendar.name)
                                    .font(.title3.bold())
                                Image(systemName: "chevron.down.circle.fill")
                                    .font(.caption)
                            }
                            .foregroundColor(.primary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                
                // 2. 月カレンダー
                VStack(spacing: 15) {
                    HStack {
                        Button(action: { changeMonth(by: -1) }) { Image(systemName: "chevron.left") }
                        Spacer()
                        Text(currentMonth.formatMonth()).font(.title2.bold())
                        Spacer()
                        Button(action: { changeMonth(by: 1) }) { Image(systemName: "chevron.right") }
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        ForEach(daysOfWeek, id: \.self) { day in
                            Text(day).font(.caption).foregroundColor(.gray).frame(maxWidth: .infinity)
                        }
                    }
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                        ForEach(0..<currentMonth.startOffset(), id: \.self) { _ in Text("") }
                        ForEach(currentMonth.getAllDays(), id: \.self) { date in
                            if let calendar = selectedCalendar {
                                DayCellView(
                                    date: date,
                                    isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                                    targetCalendar: calendar
                                )
                                .onTapGesture { selectedDate = date }
                            }
                        }
                    }
                }
                .padding()
                
                Divider()
                
                // 3. リスト
                if let calendar = selectedCalendar {
                    TodoListView(selectedDate: selectedDate, targetCalendar: calendar)
                } else {
                    ContentUnavailableView("カレンダーを選択", systemImage: "calendar")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 左上：タグ管理ボタン
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { isShowingTemplateManager = true }) {
                        Image(systemName: "tag")
                    }
                }
                
                // 右上：タスク追加ボタン
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { isShowingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            // タスク追加シート
            .sheet(isPresented: $isShowingAddSheet) {
                if let calendar = selectedCalendar {
                    AddTodoView(selectedDate: selectedDate, targetCalendar: calendar) { title, date, isTimeSet, location, folder in
                        let newItem = TodoItem(
                            title: title,
                            date: date,
                            isTimeSet: isTimeSet,
                            location: location,
                            calendar: calendar,
                            folder: folder
                        )
                        modelContext.insert(newItem)
                    }
                }
            }
            // ★テンプレート管理シート
            .sheet(isPresented: $isShowingTemplateManager) {
                if let calendar = selectedCalendar {
                    TemplateFolderManagerView(targetCalendar: calendar)
                }
            }
            .alert("新規カレンダー", isPresented: $isShowingNewCalendarAlert) {
                TextField("カレンダー名", text: $newCalendarName)
                Button("作成") {
                    let newCal = AppCalendar(name: newCalendarName)
                    modelContext.insert(newCal)
                    selectedCalendar = newCal
                    newCalendarName = ""
                }
                Button("キャンセル", role: .cancel) {}
            }
            .onAppear {
                if allCalendars.isEmpty {
                    let defaultCal = AppCalendar(name: "メイン")
                    modelContext.insert(defaultCal)
                    selectedCalendar = defaultCal
                } else if selectedCalendar == nil {
                    selectedCalendar = allCalendars.first
                }
            }
        }
    }
    
    private func changeMonth(by value: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }
}
