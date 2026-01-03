//
//  EditTodoView.swift
//  ToDoカレンダー
//
//  Created by 加藤 瑞樹 on 2026/01/03.
//

import SwiftUI
import SwiftData

struct EditTodoView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // 編集対象のタスク（Bindableにすることで直接書き換わります）
    @Bindable var item: TodoItem
    
    // そのカレンダーに属するフォルダ一覧
    @Query private var folders: [TaskFolder]
    
    // 新規フォルダ作成用
    @State private var isShowingNewFolderAlert = false
    @State private var newFolderName = ""
    
    // イニシャライザ：タスクが所属するカレンダーのフォルダだけを検索するように設定
    init(item: TodoItem) {
        _item = Bindable(item)
        
        // item.calendar に紐づくフォルダだけをフィルタリング
        if let calendarID = item.calendar?.persistentModelID {
            let predicate = #Predicate<TaskFolder> { folder in
                folder.calendar?.persistentModelID == calendarID
            }
            _folders = Query(filter: predicate, sort: \.name)
        } else {
            // 万が一カレンダーがない場合はフォルダなし（または空の条件）
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
                        // 日付と時間を個別に変更できるようにする
                        DatePicker("日付", selection: $item.date, displayedComponents: .date)
                        DatePicker("時間", selection: $item.date, displayedComponents: .hourAndMinute)
                    } else {
                        // 時間指定がない場合でも日付だけは変えられるように
                         DatePicker("日付", selection: $item.date, displayedComponents: .date)
                    }
                }
                
                Section("フォルダ（カテゴリー）") {
                    HStack {
                        Picker("フォルダ", selection: $item.folder) {
                            Text("未選択").tag(nil as TaskFolder?)
                            ForEach(folders) { folder in
                                Text(folder.name).tag(folder as TaskFolder?)
                            }
                        }
                        
                        // この画面でもフォルダを作れるように
                        Button(action: {
                            newFolderName = ""
                            isShowingNewFolderAlert = true
                        }) {
                            Image(systemName: "folder.badge.plus")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(BorderlessButtonStyle())
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
                        let newFolder = TaskFolder(name: newFolderName, calendar: calendar)
                        modelContext.insert(newFolder)
                        item.folder = newFolder // 作成したらそのフォルダを選択状態に
                    }
                }
                Button("キャンセル", role: .cancel) {}
            }
        }
    }
}
