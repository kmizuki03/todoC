//
//  ContentView.swift
//  ToDoカレンダー
//
//  Created by 加藤 瑞樹 on 2026/01/03.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AppCalendar.name) private var allCalendars: [AppCalendar]

    @StateObject private var viewModel: ContentViewModel

    @StateObject private var holidayService = EventKitHolidayService()
    @StateObject private var calendarViewModel = CalendarViewModel()

    @AppStorage("appAppearance") private var appAppearanceRaw = AppAppearance.system.rawValue

    private let swipeThreshold: CGFloat = 60

    init(viewModel: ContentViewModel = ContentViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    let daysOfWeek = ["日", "月", "火", "水", "木", "金", "土"]

    private var isMainCalendarSelected: Bool {
        viewModel.selectedCalendar?.isDefault == true
    }

    private var appAppearance: AppAppearance {
        get { AppAppearance(rawValue: appAppearanceRaw) ?? .system }
        nonmutating set { appAppearanceRaw = newValue.rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            CalendarToolbarView(
                allCalendars: allCalendars,
                selectedCalendar: $viewModel.selectedCalendar,
                isShowingAddSheet: $viewModel.isShowingAddSheet,
                isShowingTemplateManager: $viewModel.isShowingTemplateManager,
                isShowingCalendarManager: $viewModel.isShowingCalendarManager,
                isShowingNewCalendarAlert: $viewModel.isShowingNewCalendarAlert,
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
                        viewModel.isShowingAddSheet = true
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
        .onChange(of: allCalendars.count) { _, _ in
            if viewModel.selectedCalendar == nil {
                viewModel.selectedCalendar =
                    allCalendars.first(where: { $0.isDefault }) ?? allCalendars.first
            }
        }
        // タスク追加シート
        .sheet(isPresented: $viewModel.isShowingAddSheet) {
            if let calendar = selectedCalendar {
                AddTodoView(selectedDate: calendarViewModel.selectedDate, targetCalendar: calendar)
                {
                    title, date, isTimeSet, location, memo, folder in
                    let newItem = TodoItem(
                        title: title,
                        date: date,
                        isTimeSet: isTimeSet,
                        location: location,
                        memo: memo,
                        calendar: calendar,
                        folder: folder
                    )
                    modelContext.insert(newItem)
                    Task {
                        do {
                            try await TaskNotificationManager.syncThrowing(for: newItem)
                        } catch {
                            viewModel.presentNotificationError(error)
                        }
                    }
                }
            }
        }
        // ★テンプレート管理シート
        .sheet(isPresented: $viewModel.isShowingTemplateManager) {
            if let calendar = selectedCalendar {
                TemplateFolderManagerView(targetCalendar: calendar)
            }
        }
        // カレンダー管理シート
        .sheet(isPresented: $viewModel.isShowingCalendarManager) {
            CalendarManagerView(selectedCalendar: $viewModel.selectedCalendar)
        }
        .alert("新規カレンダー", isPresented: $viewModel.isShowingNewCalendarAlert) {
            TextField("カレンダー名", text: $viewModel.newCalendarName)
            Button("作成") {
                viewModel.createNewCalendar(modelContext: modelContext)
            }
            Button("キャンセル", role: .cancel) {
                viewModel.newCalendarName = ""
            }
        }
        .notificationErrorAlert(viewModel.notificationError)
    }

    private var selectedCalendar: AppCalendar? {
        viewModel.selectedCalendar
    }
}
