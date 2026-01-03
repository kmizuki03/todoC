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

    // 編集対象のタスク
    @Bindable var item: TodoItem

    // そのカレンダーに属するフォルダ一覧
    @Query private var folders: [TaskFolder]

    // 新規フォルダ作成用
    @State private var isShowingNewFolderAlert = false
    @State private var newFolderName = ""

    init(item: TodoItem) {
        _item = Bindable(item)

        if let calendarID = item.calendar?.persistentModelID {
            let predicate = #Predicate<TaskFolder> { folder in
                folder.calendar?.persistentModelID == calendarID
            }
            _folders = Query(filter: predicate, sort: \.sortOrder)
        } else {
            _folders = Query(filter: #Predicate { $0.name == "" })
        }
    }

    // 表示用のフォルダ一覧（当日フォルダ優先）
    var availableFolders: [TaskFolder] {
        let itemDate = item.date
        let dailyFolders = folders.filter { folder in
            if let d = folder.date {
                return Calendar.current.isDate(d, inSameDayAs: itemDate)
            }
            return false
        }

        let templates = folders.filter { $0.date == nil }

        let uniqueTemplates = templates.filter { template in
            !dailyFolders.contains { daily in daily.name == template.name }
        }

        return (dailyFolders + uniqueTemplates).sorted { $0.sortOrder < $1.sortOrder }
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

                Section("フォルダ（カテゴリー）") {
                    HStack {
                        Picker("フォルダ", selection: $item.folder) {
                            Text("未選択").tag(nil as TaskFolder?)
                            ForEach(availableFolders) { folder in
                                FolderPickerRow(folder: folder)
                                    .tag(folder as TaskFolder?)
                            }
                        }

                        Button(action: {
                            newFolderName = ""
                            isShowingNewFolderAlert = true
                        }) {
                            Image(systemName: "folder.badge.plus")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }

                    // 選択中のフォルダ情報
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
            .alert("新しいフォルダ", isPresented: $isShowingNewFolderAlert) {
                TextField("フォルダ名", text: $newFolderName)
                Button("作成") {
                    if let calendar = item.calendar {
                        let maxOrder = folders.map { $0.sortOrder }.max() ?? 0
                        let newFolder = TaskFolder(
                            name: newFolderName,
                            date: item.date, // 当日限定フォルダとして作成
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
            Image(systemName: folder.iconName ?? "folder.fill")
                .foregroundColor(folder.color)
                .font(.caption)

            Text(folder.name)

            if folder.date == nil {
                Text("(\(folder.name))")
                    .foregroundColor(.orange)
                    .font(.caption2)
            }
        }
    }

    // MARK: - 選択中フォルダ情報
    @ViewBuilder
    private func FolderInfoView(folder: TaskFolder) -> some View {
        HStack {
            Image(systemName: folder.iconName ?? "folder.fill")
                .foregroundColor(folder.color)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(folder.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if folder.date == nil {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                        Text("\(folder.name) テンプレート")
                    }
                    .font(.caption2)
                    .foregroundColor(.orange)
                } else if let template = folder.templateFolder {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                        Text("\(template.name) から生成")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                        Text("当日限定フォルダ")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
