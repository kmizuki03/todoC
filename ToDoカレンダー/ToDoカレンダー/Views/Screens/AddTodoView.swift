//
//  AddTodoView.swift
//  ToDoカレンダー
//
//  Created by 加藤 瑞樹 on 2026/01/03.
//

import SwiftUI
import SwiftData

struct AddTodoView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var selectedDate: Date
    var targetCalendar: AppCalendar
    var onSave: (String, Date, Bool, String, TaskFolder?) -> Void

    @Query private var allFolders: [TaskFolder]

    @State private var title = ""
    @State private var location = ""
    @State private var time = Date()
    @State private var isTimeSet = true

    @State private var selectedFolder: TaskFolder?

    // 新規作成用
    @State private var isShowingNewFolderAlert = false
    @State private var newFolderName = ""

    init(selectedDate: Date, targetCalendar: AppCalendar, onSave: @escaping (String, Date, Bool, String, TaskFolder?) -> Void) {
        self.selectedDate = selectedDate
        self.targetCalendar = targetCalendar
        self.onSave = onSave

        let calendarID = targetCalendar.persistentModelID
        // テンプレートタグのみ表示
        let predicate = #Predicate<TaskFolder> { folder in
            folder.calendar?.persistentModelID == calendarID && folder.isTemplate == true
        }
        _allFolders = Query(filter: predicate, sort: \.sortOrder)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("タスク内容") {
                    TextField("タスク名", text: $title)
                    HStack {
                        Image(systemName: "mappin.and.ellipse").foregroundColor(.red)
                        TextField("場所", text: $location)
                    }
                }
                Section("時間") {
                    Toggle("時間を指定", isOn: $isTimeSet)
                    if isTimeSet {
                        DatePicker("時間", selection: $time, displayedComponents: .hourAndMinute)
                    }
                }
                Section("タグ") {
                    HStack {
                        Picker("タグ", selection: $selectedFolder) {
                            Text("なし").tag(nil as TaskFolder?)
                            ForEach(allFolders) { folder in
                                FolderPickerRow(folder: folder)
                                    .tag(folder as TaskFolder?)
                            }
                        }

                        // 作成ボタン
                        Button(action: {
                            newFolderName = ""
                            isShowingNewFolderAlert = true
                        }) {
                            Image(systemName: "plus")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }

                    // 選択中のタグ情報表示
                    if let folder = selectedFolder {
                        FolderInfoView(folder: folder)
                    }
                }
            }
            .navigationTitle("タスク追加")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .alert("新しいタグを作成", isPresented: $isShowingNewFolderAlert) {
                TextField("タグ名", text: $newFolderName)
                Button("作成") {
                    createFolder(name: newFolderName)
                }
                Button("キャンセル", role: .cancel) {}
            }
        }
    }

    // MARK: - フォルダピッカー行
    @ViewBuilder
    private func FolderPickerRow(folder: TaskFolder) -> some View {
        HStack(spacing: 6) {
            Image(systemName: folder.iconName ?? "tag.fill")
                .foregroundColor(folder.color)
                .font(.caption)
            Text(folder.name)
        }
    }

    // MARK: - 選択中フォルダ情報
    @ViewBuilder
    private func FolderInfoView(folder: TaskFolder) -> some View {
        HStack {
            Image(systemName: folder.iconName ?? "tag.fill")
                .foregroundColor(folder.color)
                .font(.title2)

            Text(folder.name)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Actions
    private func saveTask() {
        let finalDate = isTimeSet ? combineDateAndTime(date: selectedDate, time: time) : selectedDate
        // タグを直接参照（コピーなし）
        onSave(title, finalDate, isTimeSet, location, selectedFolder)
        dismiss()
    }

    private func createFolder(name: String) {
        let maxOrder = allFolders.map { $0.sortOrder }.max() ?? 0
        let newFolder = TaskFolder(
            name: name,
            calendar: targetCalendar,
            sortOrder: maxOrder + 1
        )
        modelContext.insert(newFolder)
        selectedFolder = newFolder
    }

    private func combineDateAndTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dComps = calendar.dateComponents([.year, .month, .day], from: date)
        let tComps = calendar.dateComponents([.hour, .minute], from: time)
        var merged = DateComponents()
        merged.year = dComps.year
        merged.month = dComps.month
        merged.day = dComps.day
        merged.hour = tComps.hour
        merged.minute = tComps.minute
        return calendar.date(from: merged) ?? date
    }
}
