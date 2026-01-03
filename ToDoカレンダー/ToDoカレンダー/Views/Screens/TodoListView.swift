//
//  TodoListView.swift
//  ToDoカレンダー
//
//  Created by 加藤 瑞樹 on 2026/01/03.
//

import SwiftUI
import SwiftData

struct TodoListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [TodoItem]

    // 編集画面表示用
    @State private var editingItem: TodoItem?

    // 折りたたんでいるフォルダのIDリスト
    @State private var collapsedFolderIDs: Set<PersistentIdentifier> = []

    // フォルダ管理用のアラート状態
    @State private var folderToRename: TaskFolder?
    @State private var isShowingRenameAlert = false
    @State private var renameInput = ""

    @State private var folderToDelete: TaskFolder?
    @State private var isShowingDeleteAlert = false

    init(selectedDate: Date, targetCalendar: AppCalendar) {
        let start = Calendar.current.startOfDay(for: selectedDate)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        let calendarID = targetCalendar.persistentModelID

        _items = Query(filter: #Predicate { item in
            item.date >= start && item.date < end && item.calendar?.persistentModelID == calendarID
        }, sort: \.date)
    }

    var body: some View {
        if items.isEmpty {
            ContentUnavailableView("タスクなし", systemImage: "checklist")
        } else {
            List {
                // 1. フォルダごとのセクション（sortOrder順）
                ForEach(uniqueFolders) { folder in
                    Section(header: FolderHeader(folder: folder)) {
                        // 折りたたまれていない時だけタスクを表示
                        if !collapsedFolderIDs.contains(folder.persistentModelID) {
                            let tasksInFolder = items.filter { $0.folder == folder }

                            ForEach(tasksInFolder) { item in
                                rowView(for: item)
                            }
                            .onDelete { indexSet in deleteItems(at: indexSet, source: tasksInFolder) }
                        }
                    }
                }

                // 2. 未分類のセクション
                if hasUncategorizedItems {
                    Section(header: Text("未分類").foregroundColor(.secondary)) {
                        let uncategorizedTasks = items.filter { $0.folder == nil }
                        ForEach(uncategorizedTasks) { item in
                            rowView(for: item)
                        }
                        .onDelete { indexSet in deleteItems(at: indexSet, source: uncategorizedTasks) }
                    }
                }
            }
            .listStyle(.plain)
            .sheet(item: $editingItem) { item in
                EditTodoView(item: item)
            }
            // フォルダ名変更アラート
            .alert("フォルダ名の変更", isPresented: $isShowingRenameAlert) {
                TextField("新しい名前", text: $renameInput)
                Button("保存") {
                    if let folder = folderToRename {
                        folder.name = renameInput
                    }
                }
                Button("キャンセル", role: .cancel) {}
            }
            // フォルダ削除アラート
            .alert("フォルダを削除", isPresented: $isShowingDeleteAlert) {
                Button("削除", role: .destructive) {
                    if let folder = folderToDelete {
                        modelContext.delete(folder)
                    }
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("このフォルダ内のタスクは「未分類」になります。")
            }
        }
    }

    // MARK: - フォルダのヘッダービュー（カラー・アイコン対応）
    private func FolderHeader(folder: TaskFolder) -> some View {
        HStack(spacing: 8) {
            // アイコン（カラー付き）
            Image(systemName: folder.iconName ?? "folder.fill")
                .foregroundColor(folder.color)
                .font(.headline)

            Text(folder.name)
                .font(.headline)
                .foregroundColor(.primary)
                .textCase(nil)

            // テンプレート由来の場合の表示
            if folder.templateFolder != nil {
                Image(systemName: "link")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 開閉アイコン（回転アニメーション付き）
            Image(systemName: "chevron.right")
                .rotationEffect(.degrees(collapsedFolderIDs.contains(folder.persistentModelID) ? 0 : 90))
                .foregroundColor(.gray)
                .animation(.easeInOut(duration: 0.2), value: collapsedFolderIDs.contains(folder.persistentModelID))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                if collapsedFolderIDs.contains(folder.persistentModelID) {
                    collapsedFolderIDs.remove(folder.persistentModelID)
                } else {
                    collapsedFolderIDs.insert(folder.persistentModelID)
                }
            }
        }
        // 長押しメニュー
        .contextMenu {
            Button {
                folderToRename = folder
                renameInput = folder.name
                isShowingRenameAlert = true
            } label: {
                Label("名前を変更", systemImage: "pencil")
            }

            Button(role: .destructive) {
                folderToDelete = folder
                isShowingDeleteAlert = true
            } label: {
                Label("フォルダを削除", systemImage: "trash")
            }
        }
    }

    // MARK: - タスク行表示（フォルダカラー対応）
    private func rowView(for item: TodoItem) -> some View {
        HStack {
            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundColor(item.isCompleted ? .green : (item.folder?.color ?? .gray))
                .onTapGesture { withAnimation { item.isCompleted.toggle() } }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.body)
                    .strikethrough(item.isCompleted)
                    .foregroundColor(item.isCompleted ? .gray : .primary)

                HStack(spacing: 12) {
                    if item.isTimeSet {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                            Text(item.date, style: .time)
                        }
                    }
                    if !item.location.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.and.ellipse")
                            Text(item.location)
                        }
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture { editingItem = item }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers
    private var uniqueFolders: [TaskFolder] {
        let allFolders = items.compactMap { $0.folder }
        let unique = Set(allFolders)
        // sortOrder順にソート
        return Array(unique).sorted { $0.sortOrder < $1.sortOrder }
    }

    private var hasUncategorizedItems: Bool {
        items.contains { $0.folder == nil }
    }

    private func deleteItems(at offsets: IndexSet, source: [TodoItem]) {
        withAnimation {
            for index in offsets {
                modelContext.delete(source[index])
            }
        }
    }
}
