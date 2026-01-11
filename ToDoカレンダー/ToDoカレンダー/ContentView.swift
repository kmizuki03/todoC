//
//  ContentView.swift
//  ToDoカレンダー
//
//  Created by 加藤 瑞樹 on 2026/01/03.
//

import SwiftData
import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Query(sort: \AppCalendar.name) private var allCalendars: [AppCalendar]

    @StateObject private var holidayService = EventKitHolidayService()
    @StateObject private var calendarViewModel = CalendarViewModel()

    @AppStorage("appAppearance") private var appAppearanceRaw = AppAppearance.system.rawValue

    @State private var selectedCalendar: AppCalendar?

    private let swipeThreshold: CGFloat = 60

    // シート表示用フラグ
    @State private var isShowingAddSheet = false
    @State private var isShowingTemplateManager = false  // ← 追加
    @State private var isShowingCalendarManager = false
    @State private var isShowingNewCalendarAlert = false
    @State private var newCalendarName = ""

    @State private var isShowingNotificationError = false
    @State private var notificationErrorMessage = ""
    @State private var canOpenNotificationSettings = false

    let daysOfWeek = ["日", "月", "火", "水", "木", "金", "土"]

    private var isMainCalendarSelected: Bool {
        selectedCalendar?.isDefault == true
    }

    private var appAppearance: AppAppearance {
        get { AppAppearance(rawValue: appAppearanceRaw) ?? .system }
        nonmutating set { appAppearanceRaw = newValue.rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            CalendarToolbarView(
                allCalendars: allCalendars,
                selectedCalendar: $selectedCalendar,
                isShowingAddSheet: $isShowingAddSheet,
                isShowingTemplateManager: $isShowingTemplateManager,
                isShowingCalendarManager: $isShowingCalendarManager,
                isShowingNewCalendarAlert: $isShowingNewCalendarAlert,
                appAppearance: Binding(
                    get: { appAppearance },
                    set: { appAppearance = $0 }
                )
            )

            MonthCalendarView(
                viewModel: calendarViewModel,
                daysOfWeek: daysOfWeek,
                swipeThreshold: swipeThreshold,
                targetCalendar: selectedCalendar,
                showAllCalendars: isMainCalendarSelected,
                onDayTapped: { date in
                    if calendarViewModel.selectDate(date) {
                        isShowingAddSheet = true
                    }
                }
            )

            Divider()

            // 3. リスト
            if let calendar = selectedCalendar {
                TodoListView(
                    selectedDate: calendarViewModel.selectedDate,
                    targetCalendar: calendar,
                    showAllCalendars: isMainCalendarSelected)
            } else {
                ContentUnavailableView("カレンダーを選択", systemImage: "calendar")
            }
        }
        .environmentObject(holidayService)
        .task {
            await holidayService.refreshHolidays(forMonthContaining: calendarViewModel.currentMonth)
        }
        .onChange(of: calendarViewModel.currentMonth) { _, newValue in
            Task {
                await holidayService.refreshHolidays(forMonthContaining: newValue)
            }
        }
        // タスク追加シート
        .sheet(isPresented: $isShowingAddSheet) {
            if let calendar = selectedCalendar {
                AddTodoView(selectedDate: calendarViewModel.selectedDate, targetCalendar: calendar)
                {
                    title, date, isTimeSet, location, folder in
                    let newItem = TodoItem(
                        title: title,
                        date: date,
                        isTimeSet: isTimeSet,
                        location: location,
                        calendar: calendar,
                        folder: folder
                    )
                    modelContext.insert(newItem)
                    Task {
                        do {
                            try await TaskNotificationManager.syncThrowing(for: newItem)
                        } catch {
                            let presentation = TaskNotificationManager.presentation(for: error)
                            notificationErrorMessage = presentation.message
                            canOpenNotificationSettings = presentation.canOpenSettings
                            isShowingNotificationError = true
                        }
                    }
                }
            }
        }
        // ★テンプレート管理シート
        .sheet(isPresented: $isShowingTemplateManager) {
            if let calendar = selectedCalendar {
                TemplateFolderManagerView(targetCalendar: calendar)
            }
        }
        // カレンダー管理シート
        .sheet(isPresented: $isShowingCalendarManager) {
            CalendarManagerView(selectedCalendar: $selectedCalendar)
        }
        .alert("新規カレンダー", isPresented: $isShowingNewCalendarAlert) {
            TextField("カレンダー名", text: $newCalendarName)
            Button("作成") {
                let newCal = AppCalendar(name: newCalendarName, isDefault: false)
                modelContext.insert(newCal)
                selectedCalendar = newCal
                newCalendarName = ""
            }
            Button("キャンセル", role: .cancel) {}
        }
        .alert("通知", isPresented: $isShowingNotificationError) {
            if canOpenNotificationSettings {
                Button("設定を開く") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text(notificationErrorMessage)
        }
        .onAppear {
            let defaultCalendar = ensureDefaultCalendarExists()
            if selectedCalendar == nil {
                selectedCalendar = defaultCalendar ?? allCalendars.first
            }
        }
    }

    @discardableResult
    private func ensureDefaultCalendarExists() -> AppCalendar? {
        if allCalendars.isEmpty {
            let defaultCal = AppCalendar(name: "メイン", isDefault: true)
            modelContext.insert(defaultCal)
            return defaultCal
        }

        let defaults = allCalendars.filter { $0.isDefault }
        if let firstDefault = defaults.first {
            // 万一複数立っていたら 1つに正規化
            for extra in defaults.dropFirst() {
                extra.isDefault = false
            }
            return firstDefault
        }

        // 既存データ移行: 旧ロジックの "メイン" を優先、なければ先頭をデフォルト化
        if let legacyMain = allCalendars.first(where: { $0.name == "メイン" }) {
            legacyMain.isDefault = true
            return legacyMain
        }

        allCalendars.first?.isDefault = true
        return allCalendars.first
    }
}
