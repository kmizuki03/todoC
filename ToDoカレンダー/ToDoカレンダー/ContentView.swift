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

    @AppStorage("appAppearance") private var appAppearanceRaw = AppAppearance.system.rawValue
    
    @State private var selectedCalendar: AppCalendar?
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @State private var isCalendarCollapsed = false

    private let swipeThreshold: CGFloat = 60

    private static let collapsedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy年M月d日(EEE)"
        return formatter
    }()
    
    // シート表示用フラグ
    @State private var isShowingAddSheet = false
    @State private var isShowingTemplateManager = false // ← 追加
    @State private var isShowingCalendarManager = false
    @State private var isShowingNewCalendarAlert = false
    @State private var newCalendarName = ""

    let daysOfWeek = ["日", "月", "火", "水", "木", "金", "土"]

    private var isMainCalendarSelected: Bool {
        selectedCalendar?.name == "メイン"
    }

    private var appAppearance: AppAppearance {
        get { AppAppearance(rawValue: appAppearanceRaw) ?? .system }
        nonmutating set { appAppearanceRaw = newValue.rawValue }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. 画面上部：操作バー（タグ管理／カレンダー選択／追加）
            HStack(spacing: 12) {
                Button(action: { isShowingTemplateManager = true }) {
                    Image(systemName: "tag")
                        .font(.headline)
                        .frame(width: 36, height: 36)
                        .background(Color.gray.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)

                Menu {
                    ForEach(allCalendars) { cal in
                        Button(cal.name) { selectedCalendar = cal }
                    }
                    Divider()
                    Button("＋ カレンダーを追加") { isShowingNewCalendarAlert = true }
                    Button("カレンダー管理") { isShowingCalendarManager = true }

                    Divider()
                    Button {
                        appAppearance = .system
                    } label: {
                        if appAppearance == .system {
                            Label("表示: システム", systemImage: "checkmark")
                        } else {
                            Text("表示: システム")
                        }
                    }
                    Button {
                        appAppearance = .light
                    } label: {
                        if appAppearance == .light {
                            Label("表示: ライト", systemImage: "checkmark")
                        } else {
                            Text("表示: ライト")
                        }
                    }
                    Button {
                        appAppearance = .dark
                    } label: {
                        if appAppearance == .dark {
                            Label("表示: ダーク", systemImage: "checkmark")
                        } else {
                            Text("表示: ダーク")
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(selectedCalendar?.name ?? "カレンダー")
                            .font(.headline)
                        Image(systemName: "chevron.down")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .foregroundColor(.primary)
                }

                Spacer(minLength: 0)

                Button(action: { isShowingAddSheet = true }) {
                    Image(systemName: "plus")
                        .font(.headline)
                        .frame(width: 36, height: 36)
                        .background(Color.gray.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 6)
                
                // 2. 月カレンダー
                VStack(spacing: isCalendarCollapsed ? 8 : 15) {
                    HStack {
                        Button(action: { changeMonth(by: -1) }) { Image(systemName: "chevron.left") }
                        Spacer()
                        Button(action: { goToToday() }) {
                            Text(currentMonth.formatMonth()).font(.title2.bold())
                        }
                        .buttonStyle(.plain)
                        Spacer()
                        HStack(spacing: 12) {
                            Button(action: { changeMonth(by: 1) }) { Image(systemName: "chevron.right") }

                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isCalendarCollapsed.toggle()
                                }
                            } label: {
                                Image(systemName: isCalendarCollapsed ? "chevron.down" : "chevron.up")
                                    .font(.subheadline.weight(.semibold))
                                    .padding(6)
                                    .background(Color.gray.opacity(0.15))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(isCalendarCollapsed ? "カレンダーを開く" : "カレンダーを畳む")
                        }
                    }
                    .padding(.horizontal)

                    if isCalendarCollapsed {
                        HStack {
                            Text(Self.collapsedDateFormatter.string(from: selectedDate))
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.secondary)
                                .textCase(nil)

                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.horizontal)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isCalendarCollapsed = false
                            }
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    if !isCalendarCollapsed {
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
                                        targetCalendar: calendar,
                                        showAllCalendars: isMainCalendarSelected
                                    )
                                    .onTapGesture { handleDateTap(date) }
                                }
                            }
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding()
                .contentShape(Rectangle())
                .simultaneousGesture(
                    DragGesture(minimumDistance: 20, coordinateSpace: .local)
                        .onEnded { value in
                            let horizontal = value.translation.width
                            let vertical = value.translation.height

                            guard abs(horizontal) > abs(vertical) * 1.2 else { return }
                            guard abs(horizontal) > swipeThreshold else { return }

                            if horizontal < 0 {
                                changeMonth(by: 1)
                            } else {
                                changeMonth(by: -1)
                            }
                        }
                )
                
                Divider()
                
                // 3. リスト
                if let calendar = selectedCalendar {
                    TodoListView(selectedDate: selectedDate, targetCalendar: calendar, showAllCalendars: isMainCalendarSelected)
                } else {
                    ContentUnavailableView("カレンダーを選択", systemImage: "calendar")
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
                        TaskNotificationManager.sync(for: newItem)
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

                currentMonth = startOfMonth(for: currentMonth)
            }
    }
    
    private func changeMonth(by value: Int) {
        guard let shifted = Calendar.current.date(byAdding: .month, value: value, to: currentMonth) else { return }
        let newMonth = startOfMonth(for: shifted)

        withAnimation(.easeInOut(duration: 0.2)) {
            currentMonth = newMonth
            selectedDate = adjustedDateInMonth(from: selectedDate, month: newMonth)
        }
    }

    private func goToToday() {
        let today = Date()
        withAnimation(.easeInOut(duration: 0.2)) {
            currentMonth = startOfMonth(for: today)
            selectedDate = today
        }
    }

    private func handleDateTap(_ date: Date) {
        let isSameDay = Calendar.current.isDate(date, inSameDayAs: selectedDate)

        selectedDate = date
        if isSameDay {
            isShowingAddSheet = true
        }
    }

    private func startOfMonth(for date: Date) -> Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: date)) ?? date
    }

    private func adjustedDateInMonth(from base: Date, month: Date) -> Date {
        let calendar = Calendar.current

        let baseDay = calendar.component(.day, from: base)
        let year = calendar.component(.year, from: month)
        let monthValue = calendar.component(.month, from: month)

        let startOfMonth = startOfMonth(for: month)
        let daysInMonth = calendar.range(of: .day, in: .month, for: startOfMonth)?.count ?? 28

        let clampedDay = min(max(1, baseDay), daysInMonth)
        return calendar.date(from: DateComponents(year: year, month: monthValue, day: clampedDay)) ?? startOfMonth
    }
}
