//
//  EditTodoView.swift
//  ToDoカレンダー
//
//  Created by 加藤 瑞樹 on 2026/01/03.
//

import SwiftUI
import SwiftData

struct EditTodoView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var item: TodoItem

    @Query private var folders: [TaskFolder]

    @State private var isShowingNewFolderAlert = false
    @State private var newFolderName = ""

    init(item: TodoItem) {
        _item = Bindable(item)

        if let calendarID = item.calendar?.persistentModelID {
            // テンプレートタグのみ表示
            let predicate = #Predicate<TaskFolder> { folder in
                folder.calendar?.persistentModelID == calendarID && folder.isTemplate == true
            }
            _folders = Query(filter: predicate, sort: \.sortOrder)
        } else {
            _folders = Query(filter: #Predicate { $0.name == "" })
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
                            ForEach(folders) { folder in
                                FolderPickerRow(folder: folder)
                                    .tag(folder as TaskFolder?)
                            }
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
            }
            .navigationTitle("編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                }
            }
            .alert("新しいタグを作成", isPresented: $isShowingNewFolderAlert) {
                TextField("タグ名", text: $newFolderName)
                Button("作成") {
                    if let calendar = item.calendar {
                        let maxOrder = folders.map { $0.sortOrder }.max() ?? 0
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
