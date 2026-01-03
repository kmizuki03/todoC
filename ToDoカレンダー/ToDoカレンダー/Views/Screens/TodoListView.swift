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

    @State private var editingItem: TodoItem?
    @State private var collapsedTagNames: Set<String> = []

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
                // 現存するタグごとのセクション
                ForEach(uniqueFolders) { folder in
                    Section(header: FolderHeader(folder: folder)) {
                        if !collapsedTagNames.contains(folder.name) {
                            let tasksInFolder = items.filter { $0.folder == folder }

                            ForEach(tasksInFolder) { item in
                                rowView(for: item)
                            }
                            .onDelete { indexSet in deleteItems(at: indexSet, source: tasksInFolder) }
                        }
                    }
                }

                // 削除されたタグ（バックアップ情報で表示）
                ForEach(orphanedTagNames, id: \.self) { tagName in
                    Section(header: OrphanedTagHeader(tagName: tagName)) {
                        if !collapsedTagNames.contains(tagName) {
                            let tasksWithTag = items.filter { $0.folder == nil && $0.tagName == tagName }

                            ForEach(tasksWithTag) { item in
                                rowView(for: item)
                            }
                            .onDelete { indexSet in deleteItems(at: indexSet, source: tasksWithTag) }
                        }
                    }
                }

                // 未分類のセクション
                if hasUncategorizedItems {
                    Section(header: Text("未分類").foregroundColor(.secondary)) {
                        let uncategorizedTasks = items.filter { $0.folder == nil && $0.tagName == nil }
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
            .alert("タグ名の変更", isPresented: $isShowingRenameAlert) {
                TextField("新しい名前", text: $renameInput)
                Button("保存") {
                    if let folder = folderToRename {
                        folder.name = renameInput
                    }
                }
                Button("キャンセル", role: .cancel) {}
            }
            .alert("タグを削除", isPresented: $isShowingDeleteAlert) {
                Button("削除", role: .destructive) {
                    if let folder = folderToDelete {
                        modelContext.delete(folder)
                    }
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("タグは削除されますが、タスクのタグ表示は維持されます。")
            }
        }
    }

    // MARK: - 現存するタグヘッダー
    private func FolderHeader(folder: TaskFolder) -> some View {
        HStack(spacing: 8) {
            Image(systemName: folder.iconName ?? "tag.fill")
                .foregroundColor(folder.color)
                .font(.headline)

            Text(folder.name)
                .font(.headline)
                .foregroundColor(.primary)
                .textCase(nil)

            Spacer()

            Image(systemName: "chevron.right")
                .rotationEffect(.degrees(collapsedTagNames.contains(folder.name) ? 0 : 90))
                .foregroundColor(.gray)
                .animation(.easeInOut(duration: 0.2), value: collapsedTagNames.contains(folder.name))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                if collapsedTagNames.contains(folder.name) {
                    collapsedTagNames.remove(folder.name)
                } else {
                    collapsedTagNames.insert(folder.name)
                }
            }
        }
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
                Label("タグを削除", systemImage: "trash")
            }
        }
    }

    // MARK: - 削除されたタグのヘッダー（バックアップ情報で表示）
    private func OrphanedTagHeader(tagName: String) -> some View {
        let sampleItem = items.first { $0.folder == nil && $0.tagName == tagName }

        return HStack(spacing: 8) {
            Image(systemName: sampleItem?.displayTagIcon ?? "tag.fill")
                .foregroundColor(sampleItem?.displayTagColor ?? .gray)
                .font(.headline)

            Text(tagName)
                .font(.headline)
                .foregroundColor(.primary)
                .textCase(nil)

            // 削除済みマーク
            Text("(削除済み)")
                .font(.caption2)
                .foregroundColor(.secondary)

            Spacer()

            Image(systemName: "chevron.right")
                .rotationEffect(.degrees(collapsedTagNames.contains(tagName) ? 0 : 90))
                .foregroundColor(.gray)
                .animation(.easeInOut(duration: 0.2), value: collapsedTagNames.contains(tagName))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                if collapsedTagNames.contains(tagName) {
                    collapsedTagNames.remove(tagName)
                } else {
                    collapsedTagNames.insert(tagName)
                }
            }
        }
    }

    // MARK: - タスク行表示
    private func rowView(for item: TodoItem) -> some View {
        HStack {
            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundColor(item.isCompleted ? .green : item.displayTagColor)
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
        return Array(unique).sorted { $0.sortOrder < $1.sortOrder }
    }

    // 削除されたタグのタグ名一覧（folder == nil だけど tagName がある）
    private var orphanedTagNames: [String] {
        let names = items
            .filter { $0.folder == nil && $0.tagName != nil }
            .compactMap { $0.tagName }
        return Array(Set(names)).sorted()
    }

    private var hasUncategorizedItems: Bool {
        items.contains { $0.folder == nil && $0.tagName == nil }
    }

    private func deleteItems(at offsets: IndexSet, source: [TodoItem]) {
        withAnimation {
            for index in offsets {
                modelContext.delete(source[index])
            }
        }
    }
}
