//
//  EditTodoView.swift
//  ToDoカレンダー
//
//  Created by 加藤 瑞樹 on 2026/01/03.
//

import SwiftData
import SwiftUI

struct EditTodoView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var item: TodoItem

    @Query private var allFolders: [TaskFolder]
    @Query private var allItems: [TodoItem]

    @State private var isShowingNewFolderAlert = false
    @State private var newFolderName = ""

    @StateObject private var notificationError = NotificationErrorViewModel()

    init(item: TodoItem) {
        _item = Bindable(item)

        if let calendarID = item.calendar?.persistentModelID {
            // カレンダーに属する全てのタグを取得
            let folderPredicate = #Predicate<TaskFolder> { folder in
                folder.calendar?.persistentModelID == calendarID
            }
            _allFolders = Query(filter: folderPredicate, sort: \.sortOrder)

            // 同じ日のタスクを取得するため、全タスクをクエリ
            let itemPredicate = #Predicate<TodoItem> { item in
                item.calendar?.persistentModelID == calendarID
            }
            _allItems = Query(filter: itemPredicate)
        } else {
            _allFolders = Query(filter: #Predicate { $0.name == "" })
            _allItems = Query(filter: #Predicate { $0.title == "" })
        }
    }

    /// 選択可能なタグ: テンプレートタグ + その日に使用されたタグ + 現在選択中のタグ
    private var availableFolders: [TaskFolder] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: item.date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay

        // その日に使用されているタグのIDを取得
        let usedFolderIDs = Set(
            allItems
                .filter { $0.date >= startOfDay && $0.date < endOfDay }
                .compactMap { $0.folder?.persistentModelID }
        )

        // 現在選択中のタグのID
        let currentFolderID = item.folder?.persistentModelID

        // テンプレートタグ OR その日に使用されたタグ OR 現在選択中のタグ
        return allFolders.filter { folder in
            folder.isTemplate || usedFolderIDs.contains(folder.persistentModelID)
                || folder.persistentModelID == currentFolderID
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("タスク内容") {
                    TextField("タスク名", text: $item.title)
                    HStack {
                        Image(systemName: "mappin.and.ellipse").foregroundColor(.red)
                        TextField("場所", text: $item.location)
                    }
                }

                Section("時間") {
                    Toggle("時間を指定", isOn: $item.isTimeSet)
                    if item.isTimeSet {
                        DatePicker("日付", selection: $item.date, displayedComponents: .date)
                        DatePicker("時間", selection: $item.date, displayedComponents: .hourAndMinute)
                    } else {
                        DatePicker("日付", selection: $item.date, displayedComponents: .date)
                    }
                }

                Section("タグ") {
                    HStack {
                        Picker("タグ", selection: $item.folder) {
                            Text("なし").tag(nil as TaskFolder?)
                            ForEach(availableFolders) { folder in
                                FolderPickerRow(folder: folder)
                                    .tag(folder as TaskFolder?)
                            }
                        }
                        .onChange(of: item.folder) { _, newFolder in
                            // タグ変更時にバックアップを更新
                            item.tagName = newFolder?.name
                            item.tagColorName = newFolder?.colorName
                            item.tagIconName = newFolder?.iconName
                        }

                        Button(action: {
                            newFolderName = ""
                            isShowingNewFolderAlert = true
                        }) {
                            Image(systemName: "plus")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }

                    if let folder = item.folder {
                        FolderInfoView(folder: folder)
                    }
                }

                Section("メモ") {
                    TextEditor(text: $item.memo)
                        .frame(minHeight: 120)
                }
            }
            .navigationTitle("編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        Task {
                            do {
                                try await TaskNotificationManager.syncThrowing(for: item)
                                dismiss()
                            } catch {
                                notificationError.present(error)
                            }
                        }
                    }
                }
            }
            .onDisappear {
                TaskNotificationManager.sync(for: item)
            }
            .notificationErrorAlert(notificationError)
            .alert("新しいタグを作成", isPresented: $isShowingNewFolderAlert) {
                TextField("タグ名", text: $newFolderName)
                Button("作成") {
                    if let calendar = item.calendar {
                        let maxOrder = availableFolders.map { $0.sortOrder }.max() ?? 0
                        let newFolder = TaskFolder(
                            name: newFolderName,
                            calendar: calendar,
                            sortOrder: maxOrder + 1
                        )
                        modelContext.insert(newFolder)
                        item.folder = newFolder
                    }
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
}
