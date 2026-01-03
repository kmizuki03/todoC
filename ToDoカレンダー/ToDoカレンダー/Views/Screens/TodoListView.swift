//
//  TodoListView.swift
//  ToDoカレンダー
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
    
    // ★追加: 折りたたんでいるフォルダのIDリスト
    @State private var collapsedFolderIDs: Set<PersistentIdentifier> = []
    
    // ★追加: フォルダ管理用のアラート状態
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
                // 1. フォルダごとのセクション
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
            // ★追加: フォルダ名変更アラート
            .alert("フォルダ名の変更", isPresented: $isShowingRenameAlert) {
                TextField("新しい名前", text: $renameInput)
                Button("保存") {
                    if let folder = folderToRename {
                        folder.name = renameInput
                    }
                }
                Button("キャンセル", role: .cancel) {}
            }
            // ★追加: フォルダ削除アラート
            .alert("フォルダを削除", isPresented: $isShowingDeleteAlert) {
                Button("削除", role: .destructive) {
                    if let folder = folderToDelete {
                        modelContext.delete(folder)
                    }
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("このフォルダ内のタスクも全て削除されます。よろしいですか？")
            }
        }
    }
    
    // ★追加: フォルダのヘッダービュー（タップ判定とメニュー）
    private func FolderHeader(folder: TaskFolder) -> some View {
        HStack {
            Text(folder.name)
                .font(.headline)
                .foregroundColor(.primary)
                .textCase(nil) // デフォルトの大文字変換を無効化
            
            Spacer()
            
            // 開閉アイコン（回転アニメーション付き）
            Image(systemName: "chevron.right")
                .rotationEffect(.degrees(collapsedFolderIDs.contains(folder.persistentModelID) ? 0 : 90))
                .foregroundColor(.gray)
                .animation(.easeInOut(duration: 0.2), value: collapsedFolderIDs.contains(folder.persistentModelID))
        }
        .contentShape(Rectangle()) // 行全体をタップ可能にする
        .onTapGesture {
            // タップで開閉切り替え
            withAnimation {
                if collapsedFolderIDs.contains(folder.persistentModelID) {
                    collapsedFolderIDs.remove(folder.persistentModelID)
                } else {
                    collapsedFolderIDs.insert(folder.persistentModelID)
                }
            }
        }
        // 長押しメニュー（コンテキストメニュー）
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
    
    // --- 以下、既存のロジック ---
    
    private func rowView(for item: TodoItem) -> some View {
        HStack {
            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundColor(item.isCompleted ? .green : .gray)
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
    
    private var uniqueFolders: [TaskFolder] {
        let allFolders = items.compactMap { $0.folder }
        let unique = Set(allFolders)
        return Array(unique).sorted { $0.name < $1.name }
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
