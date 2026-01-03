//
//  Organization.swift
//  ToDoカレンダー
//
//  Created by 加藤 瑞樹 on 2026/01/03.
//

import Foundation
import SwiftData

@Model
class TaskFolder {
    var name: String
    var date: Date? // nil=テンプレ、日付あり=その日限定
    var calendar: AppCalendar?
    
    // isArchived を削除しました
    
    // フォルダ削除時は、中のタスクを「未分類」にする
    @Relationship(deleteRule: .nullify) var items: [TodoItem] = []
    
    init(name: String, date: Date? = nil, calendar: AppCalendar? = nil) {
        self.name = name
        self.date = date
        self.calendar = calendar
    }
}
