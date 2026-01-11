//
//  TodoListView.swift
//  ToDoカレンダー
//
//  Created by 加藤 瑞樹 on 2026/01/03.
//

import SwiftData
import SwiftUI

struct TodoListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [TodoItem]

    private let showAllCalendars: Bool

    @State private var editingItem: TodoItem?
    @State private var memoItem: TodoItem?
    @State private var collapsedTagNames: Set<String> = []

    @State private var folderToRename: TaskFolder?
    @State private var isShowingRenameAlert = false
    @State private var renameInput = ""

    @State private var folderToDelete: TaskFolder?
    @State private var isShowingDeleteAlert = false

    @StateObject private var notificationError = NotificationErrorViewModel()

    init(selectedDate: Date, targetCalendar: AppCalendar, showAllCalendars: Bool = false) {
        self.showAllCalendars = showAllCalendars
        let start = Calendar.current.startOfDay(for: selectedDate)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        let calendarID = targetCalendar.persistentModelID

        let showAll = showAllCalendars
        _items = Query(
            filter: #Predicate { item in
                item.date >= start && item.date < end
                    && (showAll || item.calendar?.persistentModelID == calendarID)
            }, sort: \.date)
    }

    var body: some View {
        let tasksByFolder = tasksGroupedByFolder
        let tasksByOrphanTagName = tasksGroupedByOrphanedTagName
        let uncategorizedTasks = uncategorizedItems

        if items.isEmpty {
            ContentUnavailableView("タスクなし", systemImage: "checklist")
        } else {
            List {
                // 現存するタグごとのセクション
                ForEach(uniqueFolders) { folder in
                    Section {
                        FolderHeader(folder: folder)
                            .listRowInsets(
                                EdgeInsets(top: 10, leading: 16, bottom: 6, trailing: 16)
                            )
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)

                        if !collapsedTagNames.contains(folder.name) {
                            let tasksInFolder = tasksByFolder[folder] ?? []

                            ForEach(tasksInFolder) { item in
                                rowView(for: item)
                            }
                            .onDelete { indexSet in deleteItems(at: indexSet, source: tasksInFolder)
                            }
                        }
                    }
                }

                // 削除されたタグ（バックアップ情報で表示）
                ForEach(orphanedTagNames, id: \.self) { tagName in
                    Section {
                        OrphanedTagHeader(tagName: tagName)
                            .listRowInsets(
                                EdgeInsets(top: 10, leading: 16, bottom: 6, trailing: 16)
                            )
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)

                        if !collapsedTagNames.contains(tagName) {
                            let tasksWithTag = tasksByOrphanTagName[tagName] ?? []

                            ForEach(tasksWithTag) { item in
                                rowView(for: item)
                            }
                            .onDelete { indexSet in deleteItems(at: indexSet, source: tasksWithTag)
                            }
                        }
                    }
                }

                // 未分類のセクション
                if !uncategorizedTasks.isEmpty {
                    Section {
                        Text("未分類")
                            .foregroundColor(.secondary)
                            .textCase(nil)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 4)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .listRowInsets(
                                EdgeInsets(top: 10, leading: 16, bottom: 6, trailing: 16)
                            )
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)

                        ForEach(uncategorizedTasks) { item in
                            rowView(for: item)
                        }
                        .onDelete { indexSet in
                            deleteItems(at: indexSet, source: uncategorizedTasks)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .sheet(item: $editingItem) { item in
                EditTodoView(item: item)
            }
            .sheet(item: $memoItem) { item in
                TodoMemoView(item: item)
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
                    deleteFolder()
                }
                Button("キャンセル", role: .cancel) {
                    folderToDelete = nil
                }
            } message: {
                Text("タグは削除されますが、タスクのタグ表示は維持されます。")
            }
            .notificationErrorAlert(notificationError)
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
                .animation(
                    .easeInOut(duration: 0.2), value: collapsedTagNames.contains(folder.name))
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
            Button {
                withAnimation {
                    item.isCompleted.toggle()
                }
                Task {
                    do {
                        try await TaskNotificationManager.syncThrowing(for: item)
                    } catch {
                        notificationError.present(error)
                    }
                }
            } label: {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(item.isCompleted ? .green : item.displayTagColor)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.body)
                    .strikethrough(item.isCompleted)
                    .foregroundColor(item.isCompleted ? .gray : .primary)

                HStack(spacing: 12) {
                    if showAllCalendars, let calName = item.calendar?.name {
                        Text(calName)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }
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

            Spacer()

            if !item.memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Image(systemName: "note.text")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            memoItem = item
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                TaskNotificationManager.cancel(for: item)
                modelContext.delete(item)
            } label: {
                Label("削除", systemImage: "trash")
            }

            Button {
                editingItem = item
            } label: {
                Label("編集", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }

    // MARK: - Helpers
    private var uniqueFolders: [TaskFolder] {
        let allFolders = items.compactMap { $0.folder }
        let unique = Set(allFolders)
        return Array(unique).sorted { $0.sortOrder < $1.sortOrder }
    }

    private var tasksGroupedByFolder: [TaskFolder: [TodoItem]] {
        Dictionary(grouping: items.filter { $0.folder != nil }, by: { $0.folder! })
    }

    private var tasksGroupedByOrphanedTagName: [String: [TodoItem]] {
        Dictionary(
            grouping: items.filter { $0.folder == nil && $0.tagName != nil },
            by: { $0.tagName! }
        )
    }

    private var uncategorizedItems: [TodoItem] {
        items.filter { $0.folder == nil && $0.tagName == nil }
    }

    // 削除されたタグのタグ名一覧（folder == nil だけど tagName がある）
    private var orphanedTagNames: [String] {
        let names =
            items
            .filter { $0.folder == nil && $0.tagName != nil }
            .compactMap { $0.tagName }
        return Array(Set(names)).sorted()
    }

    private func deleteItems(at offsets: IndexSet, source: [TodoItem]) {
        withAnimation {
            for index in offsets {
                let item = source[index]
                TaskNotificationManager.cancel(for: item)
                modelContext.delete(item)
            }
        }
    }

    private func deleteFolder() {
        guard let folder = folderToDelete else { return }

        // 削除前にフォルダ情報をローカル変数にコピー
        let folderName = folder.name
        let folderColorName = folder.colorName
        let folderIconName = folder.iconName

        // 先に参照をクリア
        folderToDelete = nil

        // バックアップを更新してから削除
        for item in items where item.folder?.persistentModelID == folder.persistentModelID {
            item.tagName = folderName
            item.tagColorName = folderColorName
            item.tagIconName = folderIconName
            item.folder = nil
        }

        // フォルダを削除
        modelContext.delete(folder)
    }
}
