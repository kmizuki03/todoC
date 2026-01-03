//
//  AddTodoView.swift
//  ToDoカレンダー
//
//  Created by 加藤 瑞樹 on 2026/01/03.
//

import SwiftUI
import SwiftData

struct AddTodoView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var selectedDate: Date
    var targetCalendar: AppCalendar
    var onSave: (String, Date, Bool, String, TaskFolder?) -> Void
    
    @Query private var allFolders: [TaskFolder]
    
    @State private var title = ""
    @State private var location = ""
    @State private var time = Date()
    @State private var isTimeSet = true
    
    @State private var selectedFolder: TaskFolder?
    
    // 新規作成用アラート
    @State private var isShowingNewFolderAlert = false
    @State private var newFolderName = ""
    
    // ★追加: 削除確認用アラート
    @State private var isShowingDeleteAlert = false
    
    init(selectedDate: Date, targetCalendar: AppCalendar, onSave: @escaping (String, Date, Bool, String, TaskFolder?) -> Void) {
        self.selectedDate = selectedDate
        self.targetCalendar = targetCalendar
        self.onSave = onSave
        
        let calendarID = targetCalendar.persistentModelID
        let predicate = #Predicate<TaskFolder> { folder in
            folder.calendar?.persistentModelID == calendarID
        }
        _allFolders = Query(filter: predicate, sort: \.name)
    }
    
    var availableFolders: [TaskFolder] {
        let dailyFolders = allFolders.filter { folder in
            if let d = folder.date {
                return Calendar.current.isDate(d, inSameDayAs: selectedDate)
            }
            return false
        }
        
        let templates = allFolders.filter { $0.date == nil }
        
        let uniqueTemplates = templates.filter { template in
            !dailyFolders.contains { daily in daily.name == template.name }
        }
        
        return (dailyFolders + uniqueTemplates).sorted { $0.name < $1.name }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("タスク内容") {
                    TextField("タスク名", text: $title)
                    HStack {
                        Image(systemName: "mappin.and.ellipse").foregroundColor(.red)
                        TextField("場所", text: $location)
                    }
                }
                Section("時間") {
                    Toggle("時間を指定", isOn: $isTimeSet)
                    if isTimeSet {
                        DatePicker("時間", selection: $time, displayedComponents: .hourAndMinute)
                    }
                }
                Section("フォルダ（カテゴリー）") {
                    HStack {
                        Picker("フォルダ", selection: $selectedFolder) {
                            Text("未選択").tag(nil as TaskFolder?)
                            ForEach(availableFolders) { folder in
                                HStack {
                                    Text(folder.name)
                                    if folder.date == nil {
                                        Text("＊")
                                            .foregroundColor(.orange)
                                            .fontWeight(.bold)
                                    }
                                }
                                .tag(folder as TaskFolder?)
                            }
                        }
                        
                        // ★追加: 削除ボタン (当日フォルダが選択されている時のみ表示)
                        if let folder = selectedFolder, folder.date != nil {
                            Button(action: {
                                isShowingDeleteAlert = true
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                        
                        // 作成ボタン
                        Button(action: {
                            newFolderName = ""
                            isShowingNewFolderAlert = true
                        }) {
                            Image(systemName: "plus")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
            }
            .navigationTitle("タスク追加")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
            // 作成アラート
            .alert("当日限定フォルダを作成", isPresented: $isShowingNewFolderAlert) {
                TextField("フォルダ名", text: $newFolderName)
                Button("作成") {
                    createDailyFolder(name: newFolderName)
                }
                Button("キャンセル", role: .cancel) {}
            }
            // ★追加: 削除アラート
            .alert("フォルダを削除", isPresented: $isShowingDeleteAlert) {
                Button("削除", role: .destructive) {
                    deleteSelectedFolder()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("このフォルダを削除しますか？\n中身のタスクは「未分類」になります。")
            }
        }
    }
    
    // ★追加: フォルダ削除処理
    private func deleteSelectedFolder() {
        if let folder = selectedFolder {
            modelContext.delete(folder)
            selectedFolder = nil // 選択解除
        }
    }
    
    private func saveTask() {
        let finalDate = isTimeSet ? combineDateAndTime(date: selectedDate, time: time) : selectedDate
        var finalFolder: TaskFolder? = nil
        
        if let folder = selectedFolder {
            if folder.date == nil {
                let existingDaily = allFolders.first { existing in
                    guard let d = existing.date else { return false }
                    return Calendar.current.isDate(d, inSameDayAs: selectedDate) && existing.name == folder.name
                }
                
                if let existing = existingDaily {
                    finalFolder = existing
                } else {
                    let newDailyFolder = TaskFolder(name: folder.name, date: selectedDate, calendar: targetCalendar)
                    modelContext.insert(newDailyFolder)
                    finalFolder = newDailyFolder
                }
            } else {
                finalFolder = folder
            }
        }
        
        onSave(title, finalDate, isTimeSet, location, finalFolder)
        dismiss()
    }
    
    private func createDailyFolder(name: String) {
        let newFolder = TaskFolder(name: name, date: selectedDate, calendar: targetCalendar)
        modelContext.insert(newFolder)
        selectedFolder = newFolder
    }
    
    private func combineDateAndTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dComps = calendar.dateComponents([.year, .month, .day], from: date)
        let tComps = calendar.dateComponents([.hour, .minute], from: time)
        var merged = DateComponents()
        merged.year = dComps.year
        merged.month = dComps.month
        merged.day = dComps.day
        merged.hour = tComps.hour
        merged.minute = tComps.minute
        return calendar.date(from: merged) ?? date
    }
}
