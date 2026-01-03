//
//  TemplateFolderManagerView.swift
//  ToDoカレンダー
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
    
    @State private var isAddingFolder = false
    @State private var newFolderName = ""
    
    init(targetCalendar: AppCalendar) {
        self.targetCalendar = targetCalendar
        let calendarID = targetCalendar.persistentModelID
        
        let predicate = #Predicate<TaskFolder> { folder in
            folder.calendar?.persistentModelID == calendarID &&
            folder.date == nil // 日付なし＝テンプレ
        }
        _templateFolders = Query(filter: predicate, sort: \.name)
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("テンプレートフォルダ")) {
                    if templateFolders.isEmpty {
                        Text("テンプレートがありません").foregroundColor(.secondary)
                    } else {
                        ForEach(templateFolders) { folder in
                            Text(folder.name)
                        }
                        .onDelete(perform: deleteFolders)
                    }
                    
                    Button("＋ 新しいテンプレートを追加") {
                        isAddingFolder = true
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("フォルダ管理")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            .alert("テンプレート作成", isPresented: $isAddingFolder) {
                TextField("フォルダ名", text: $newFolderName)
                Button("作成") {
                    // date: nil で作成
                    let newFolder = TaskFolder(name: newFolderName, date: nil, calendar: targetCalendar)
                    modelContext.insert(newFolder)
                    newFolderName = ""
                }
                Button("キャンセル", role: .cancel) {}
            }
        }
    }
    
    private func deleteFolders(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(templateFolders[index])
            }
        }
    }
}
