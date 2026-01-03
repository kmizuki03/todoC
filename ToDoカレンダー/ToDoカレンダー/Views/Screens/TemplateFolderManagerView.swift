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

    // テンプレートタグのみ取得
    @Query private var allFolders: [TaskFolder]

    @State private var isAddingFolder = false
    @State private var newFolderName = ""
    @State private var newFolderColor: String? = nil
    @State private var newFolderIcon: String? = "tag.fill"

    @State private var editingFolder: TaskFolder?
    @State private var isEditingFolder = false
    @State private var editFolderName = ""
    @State private var editFolderColor: String? = nil
    @State private var editFolderIcon: String? = nil

    @State private var showError = false
    @State private var errorMessage = ""

    init(targetCalendar: AppCalendar) {
        self.targetCalendar = targetCalendar
        let calendarID = targetCalendar.persistentModelID

        // isTemplate == true のタグのみ取得
        let predicate = #Predicate<TaskFolder> { folder in
            folder.calendar?.persistentModelID == calendarID && folder.isTemplate == true
        }
        _allFolders = Query(filter: predicate, sort: \.sortOrder)
    }

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("タグ一覧")) {
                    if allFolders.isEmpty {
                        Text("タグがありません").foregroundColor(.secondary)
                    } else {
                        ForEach(allFolders) { folder in
                            FolderRow(folder: folder)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    startEditing(folder: folder)
                                }
                        }
                        .onDelete(perform: hideFolders)
                        .onMove(perform: moveFolders)
                    }

                    Button {
                        resetNewFolderState()
                        isAddingFolder = true
                    } label: {
                        Label("新しいタグを追加", systemImage: "plus.circle.fill")
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("タグ管理")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    EditButton()
                }
            }
            .sheet(isPresented: $isAddingFolder) {
                FolderEditSheet(
                    title: "タグ作成",
                    folderName: $newFolderName,
                    folderColor: $newFolderColor,
                    folderIcon: $newFolderIcon,
                    existingNames: allFolders.map { $0.name },
                    onSave: createFolder,
                    onCancel: { isAddingFolder = false }
                )
            }
            .sheet(isPresented: $isEditingFolder) {
                FolderEditSheet(
                    title: "タグ編集",
                    folderName: $editFolderName,
                    folderColor: $editFolderColor,
                    folderIcon: $editFolderIcon,
                    existingNames: allFolders.filter { $0.id != editingFolder?.id }.map { $0.name },
                    onSave: saveEditedFolder,
                    onCancel: { isEditingFolder = false }
                )
            }
            .alert("エラー", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - フォルダ行表示
    @ViewBuilder
    private func FolderRow(folder: TaskFolder) -> some View {
        HStack {
            Image(systemName: folder.iconName ?? "tag.fill")
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
        newFolderIcon = "tag.fill"
    }

    private func startEditing(folder: TaskFolder) {
        editingFolder = folder
        editFolderName = folder.name
        editFolderColor = folder.colorName
        editFolderIcon = folder.iconName
        isEditingFolder = true
    }

    private func createFolder() {
        let maxOrder = allFolders.map { $0.sortOrder }.max() ?? 0
        let newFolder = TaskFolder(
            name: newFolderName,
            calendar: targetCalendar,
            colorName: newFolderColor,
            iconName: newFolderIcon,
            sortOrder: maxOrder + 1,
            isTemplate: true  // テンプレートとして作成
        )
        modelContext.insert(newFolder)
        isAddingFolder = false
    }

    private func saveEditedFolder() {
        guard let folder = editingFolder else { return }
        folder.name = editFolderName
        folder.colorName = editFolderColor
        folder.iconName = editFolderIcon
        isEditingFolder = false
    }

    // 削除ではなく非表示にする（既存タスクのタグは維持）
    private func hideFolders(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                allFolders[index].isTemplate = false
            }
        }
    }

    private func moveFolders(from source: IndexSet, to destination: Int) {
        var sorted = Array(allFolders)
        sorted.move(fromOffsets: source, toOffset: destination)
        for (index, folder) in sorted.enumerated() {
            folder.sortOrder = index
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

    var isDuplicate: Bool {
        existingNames.contains { $0.lowercased() == folderName.lowercased() }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("名前") {
                    TextField("タグ名", text: $folderName)
                    if isDuplicate {
                        Text("この名前は既に使用されています")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Section("カラー") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
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
                        Image(systemName: folderIcon ?? "tag.fill")
                            .foregroundColor(folderColor != nil ? colorFromName(folderColor!) : .accentColor)
                            .font(.title2)
                        Text(folderName.isEmpty ? "タグ名" : folderName)
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
