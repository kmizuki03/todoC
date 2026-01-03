//
//  TemplateFolderManagerView.swift
//  ToDoカレンダー
//
//  Created by 加藤 瑞樹 on 2026/01/03.
//

import SwiftUI
import SwiftData

struct TemplateFolderManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var targetCalendar: AppCalendar

    // テンプレート(dateがnilのもの)だけを取得
    @Query private var templateFolders: [TaskFolder]

    // 全フォルダ（クリーンアップ用）
    @Query private var allFolders: [TaskFolder]

    @State private var isAddingFolder = false
    @State private var newFolderName = ""
    @State private var newFolderColor: String? = nil
    @State private var newFolderIcon: String? = "folder.fill"

    // 編集用
    @State private var editingFolder: TaskFolder?
    @State private var isEditingFolder = false
    @State private var editFolderName = ""
    @State private var editFolderColor: String? = nil
    @State private var editFolderIcon: String? = nil

    // エラー表示用
    @State private var showError = false
    @State private var errorMessage = ""

    // クリーンアップ確認用
    @State private var showCleanupAlert = false
    @State private var oldFoldersCount = 0

    // 一括生成確認用
    @State private var showBulkCreateAlert = false

    init(targetCalendar: AppCalendar) {
        self.targetCalendar = targetCalendar
        let calendarID = targetCalendar.persistentModelID

        let templatePredicate = #Predicate<TaskFolder> { folder in
            folder.calendar?.persistentModelID == calendarID &&
            folder.date == nil // 日付なし＝テンプレ
        }
        _templateFolders = Query(filter: templatePredicate, sort: \.sortOrder)

        let allPredicate = #Predicate<TaskFolder> { folder in
            folder.calendar?.persistentModelID == calendarID
        }
        _allFolders = Query(filter: allPredicate)
    }

    var sortedTemplates: [TaskFolder] {
        templateFolders.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        NavigationStack {
            List {
                // テンプレートセクション
                Section(header: Text("テンプレートフォルダ")) {
                    if sortedTemplates.isEmpty {
                        Text("テンプレートがありません").foregroundColor(.secondary)
                    } else {
                        ForEach(sortedTemplates) { folder in
                            FolderRow(folder: folder)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    startEditing(folder: folder)
                                }
                        }
                        .onDelete(perform: deleteFolders)
                        .onMove(perform: moveFolders)
                    }

                    Button {
                        resetNewFolderState()
                        isAddingFolder = true
                    } label: {
                        Label("新しいテンプレートを追加", systemImage: "plus.circle.fill")
                    }
                    .foregroundColor(.blue)
                }

                // 一括操作セクション
                Section(header: Text("一括操作")) {
                    Button {
                        showBulkCreateAlert = true
                    } label: {
                        Label("今日のフォルダを一括生成", systemImage: "folder.badge.plus")
                    }
                    .disabled(templateFolders.isEmpty)

                    Button(role: .destructive) {
                        countOldFolders()
                        if oldFoldersCount > 0 {
                            showCleanupAlert = true
                        } else {
                            errorMessage = "削除対象の古いフォルダはありません"
                            showError = true
                        }
                    } label: {
                        Label("古い当日フォルダを削除", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("フォルダ管理")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    EditButton()
                }
            }
            // 新規作成シート
            .sheet(isPresented: $isAddingFolder) {
                FolderEditSheet(
                    title: "テンプレート作成",
                    folderName: $newFolderName,
                    folderColor: $newFolderColor,
                    folderIcon: $newFolderIcon,
                    existingNames: templateFolders.map { $0.name },
                    onSave: createTemplate,
                    onCancel: { isAddingFolder = false }
                )
            }
            // 編集シート
            .sheet(isPresented: $isEditingFolder) {
                FolderEditSheet(
                    title: "テンプレート編集",
                    folderName: $editFolderName,
                    folderColor: $editFolderColor,
                    folderIcon: $editFolderIcon,
                    existingNames: templateFolders.filter { $0.id != editingFolder?.id }.map { $0.name },
                    onSave: saveEditedTemplate,
                    onCancel: { isEditingFolder = false }
                )
            }
            // エラーアラート
            .alert("エラー", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            // クリーンアップ確認アラート
            .alert("古いフォルダを削除", isPresented: $showCleanupAlert) {
                Button("削除", role: .destructive) {
                    cleanupOldFolders()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("\(oldFoldersCount)件の古い当日フォルダ（7日以上前）を削除します。\n中身が空のフォルダのみ削除されます。")
            }
            // 一括生成確認アラート
            .alert("今日のフォルダを一括生成", isPresented: $showBulkCreateAlert) {
                Button("生成") {
                    bulkCreateTodayFolders()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("全てのテンプレートから今日のフォルダを生成します。\n既に存在するフォルダはスキップされます。")
            }
        }
    }

    // MARK: - フォルダ行表示
    @ViewBuilder
    private func FolderRow(folder: TaskFolder) -> some View {
        HStack {
            Image(systemName: folder.iconName ?? "folder.fill")
                .foregroundColor(folder.color)
                .font(.title2)

            VStack(alignment: .leading) {
                Text(folder.name)
                    .font(.body)
                if folder.colorName != nil || folder.iconName != nil {
                    Text("カスタマイズ済み")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Actions
    private func resetNewFolderState() {
        newFolderName = ""
        newFolderColor = nil
        newFolderIcon = "folder.fill"
    }

    private func startEditing(folder: TaskFolder) {
        editingFolder = folder
        editFolderName = folder.name
        editFolderColor = folder.colorName
        editFolderIcon = folder.iconName
        isEditingFolder = true
    }

    private func createTemplate() {
        let maxOrder = templateFolders.map { $0.sortOrder }.max() ?? 0
        let newFolder = TaskFolder(
            name: newFolderName,
            date: nil,
            calendar: targetCalendar,
            colorName: newFolderColor,
            iconName: newFolderIcon,
            sortOrder: maxOrder + 1
        )
        modelContext.insert(newFolder)
        isAddingFolder = false
    }

    private func saveEditedTemplate() {
        guard let folder = editingFolder else { return }
        folder.name = editFolderName
        folder.colorName = editFolderColor
        folder.iconName = editFolderIcon
        isEditingFolder = false
    }

    private func deleteFolders(at offsets: IndexSet) {
        withAnimation {
            let sorted = sortedTemplates
            for index in offsets {
                modelContext.delete(sorted[index])
            }
        }
    }

    private func moveFolders(from source: IndexSet, to destination: Int) {
        var sorted = sortedTemplates
        sorted.move(fromOffsets: source, toOffset: destination)
        for (index, folder) in sorted.enumerated() {
            folder.sortOrder = index
        }
    }

    private func countOldFolders() {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        oldFoldersCount = allFolders.filter { folder in
            guard let date = folder.date else { return false }
            return date < sevenDaysAgo && folder.items.isEmpty
        }.count
    }

    private func cleanupOldFolders() {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let foldersToDelete = allFolders.filter { folder in
            guard let date = folder.date else { return false }
            return date < sevenDaysAgo && folder.items.isEmpty
        }
        for folder in foldersToDelete {
            modelContext.delete(folder)
        }
    }

    private func bulkCreateTodayFolders() {
        let today = Calendar.current.startOfDay(for: Date())

        for template in templateFolders {
            // 既に今日のフォルダが存在するかチェック
            let existsToday = allFolders.contains { folder in
                guard let date = folder.date else { return false }
                return Calendar.current.isDate(date, inSameDayAs: today) && folder.name == template.name
            }

            if !existsToday {
                let newFolder = TaskFolder(
                    name: template.name,
                    date: today,
                    calendar: targetCalendar,
                    templateFolder: template,
                    colorName: template.colorName,
                    iconName: template.iconName,
                    sortOrder: template.sortOrder
                )
                modelContext.insert(newFolder)
            }
        }
    }
}

// MARK: - フォルダ編集シート
struct FolderEditSheet: View {
    let title: String
    @Binding var folderName: String
    @Binding var folderColor: String?
    @Binding var folderIcon: String?
    let existingNames: [String]
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var showDuplicateError = false

    var isDuplicate: Bool {
        existingNames.contains { $0.lowercased() == folderName.lowercased() }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("名前") {
                    TextField("フォルダ名", text: $folderName)
                    if isDuplicate {
                        Text("この名前は既に使用されています")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Section("カラー") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        // 「なし」オプション
                        Button {
                            folderColor = nil
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 40, height: 40)
                                Text("×")
                                    .foregroundColor(.gray)
                            }
                            .overlay(
                                Circle()
                                    .stroke(folderColor == nil ? Color.primary : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        ForEach(TaskFolder.availableColors, id: \.name) { colorItem in
                            Button {
                                folderColor = colorItem.name
                            } label: {
                                Circle()
                                    .fill(colorFromName(colorItem.name))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(folderColor == colorItem.name ? Color.primary : Color.clear, lineWidth: 2)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("アイコン") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(TaskFolder.availableIcons, id: \.name) { iconItem in
                            Button {
                                folderIcon = iconItem.name
                            } label: {
                                VStack {
                                    Image(systemName: iconItem.name)
                                        .font(.title2)
                                        .frame(width: 40, height: 40)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(folderIcon == iconItem.name ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                                        )
                                    Text(iconItem.display)
                                        .font(.caption2)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .foregroundColor(folderIcon == iconItem.name ? .accentColor : .primary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("プレビュー") {
                    HStack {
                        Image(systemName: folderIcon ?? "folder.fill")
                            .foregroundColor(folderColor != nil ? colorFromName(folderColor!) : .accentColor)
                            .font(.title2)
                        Text(folderName.isEmpty ? "フォルダ名" : folderName)
                            .foregroundColor(folderName.isEmpty ? .secondary : .primary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { onSave() }
                        .disabled(folderName.isEmpty || isDuplicate)
                }
            }
        }
    }

    private func colorFromName(_ name: String) -> Color {
        switch name {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "gray": return .gray
        default: return .accentColor
        }
    }
}
