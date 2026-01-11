//
//  CalendarManagerView.swift
//  ToDoカレンダー
//
//  Created by 加藤 瑞樹 on 2026/01/11.
//

import SwiftData
import SwiftUI

struct CalendarManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Binding var selectedCalendar: AppCalendar?

    @Query(sort: \AppCalendar.name) private var allCalendars: [AppCalendar]

    @State private var pendingDelete: [AppCalendar] = []
    @State private var isShowingDeleteConfirm = false

    @State private var isShowingError = false
    @State private var errorMessage = ""

    @State private var isShowingNewCalendarAlert = false
    @State private var newCalendarName = ""

    var body: some View {
        NavigationStack {
            List {
                appCalendarsSection
                deleteWarningSection
            }
            .navigationTitle("カレンダー管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        newCalendarName = ""
                        isShowingNewCalendarAlert = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    EditButton()
                }
            }
            .alert("削除確認", isPresented: $isShowingDeleteConfirm) {
                Button("削除", role: .destructive) {
                    deletePendingCalendars()
                }
                Button("キャンセル", role: .cancel) {
                    pendingDelete = []
                }
            } message: {
                if pendingDelete.count == 1 {
                    Text("「\(pendingDelete[0].name)」を削除しますか？")
                } else {
                    Text("\(pendingDelete.count)件のカレンダーを削除しますか？")
                }
            }
            .alert("エラー", isPresented: $isShowingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
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
        }
        .onAppear {
            if let ensured = AppCalendarIntegrity.ensureDefaultCalendarExists(
                modelContext: modelContext),
                selectedCalendar == nil
            {
                selectedCalendar = ensured
            }
        }
    }

    // MARK: - Sections

    private var appCalendarsSection: some View {
        Section("カレンダー") {
            if allCalendars.isEmpty {
                Text("カレンダーがありません")
                    .foregroundColor(.secondary)
            } else {
                ForEach(allCalendars) { calendar in
                    HStack {
                        Text(calendar.name)
                        Spacer()
                        if calendar.isDefault {
                            Text("固定")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedCalendar = calendar
                        dismiss()
                    }
                }
                .onDelete(perform: requestDelete)
            }
        }
    }

    private var deleteWarningSection: some View {
        Section {
            Text("※ カレンダーを削除すると、そのカレンダー内のタスクとタグも削除されます。")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private func requestDelete(at offsets: IndexSet) {
        let candidates = offsets.map { allCalendars[$0] }

        if candidates.contains(where: { $0.isDefault }) {
            errorMessage = "デフォルトカレンダーは削除できません。"
            isShowingError = true
            return
        }

        pendingDelete = candidates
        isShowingDeleteConfirm = !pendingDelete.isEmpty
    }

    private func deletePendingCalendars() {
        guard !pendingDelete.isEmpty else { return }

        // 削除後に選択カレンダーが消える場合は、メインへフォールバック
        let deletingSelected = pendingDelete.contains {
            $0.persistentModelID == selectedCalendar?.persistentModelID
        }

        for calendar in pendingDelete {
            modelContext.delete(calendar)
        }

        pendingDelete = []

        if deletingSelected {
            selectedCalendar =
                allCalendars.first(where: { $0.isDefault })
                ?? allCalendars.first
        }
    }
}
