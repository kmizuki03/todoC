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
    var colorHex: String  // カレンダーのテーマ色（今回はシンプルに保持だけ）

    /// "メイン" のような表示名に依存せず、アプリ上のデフォルト（固定）カレンダーを判定するためのフラグ
    var isDefault: Bool = false

    // このカレンダーに属するフォルダとタスク
    @Relationship(deleteRule: .cascade) var folders: [TaskFolder] = []
    @Relationship(deleteRule: .cascade) var items: [TodoItem] = []  // Inbox的なタスク用

    init(name: String, colorHex: String = "007AFF", isDefault: Bool = false) {
        self.name = name
        self.colorHex = colorHex
        self.isDefault = isDefault
    }
}
