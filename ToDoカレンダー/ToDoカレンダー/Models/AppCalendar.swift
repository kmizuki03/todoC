//
//  AppCalendar.swift
//  ToDoカレンダー
//
//  Created by 加藤 瑞樹 on 2026/01/03.
//

import Foundation
import SwiftData

@Model
class AppCalendar {
    var name: String
    var colorHex: String // カレンダーのテーマ色（今回はシンプルに保持だけ）
    
    // このカレンダーに属するフォルダとタスク
    @Relationship(deleteRule: .cascade) var folders: [TaskFolder] = []
    @Relationship(deleteRule: .cascade) var items: [TodoItem] = [] // Inbox的なタスク用
    
    init(name: String, colorHex: String = "007AFF") {
        self.name = name
        self.colorHex = colorHex
    }
}
