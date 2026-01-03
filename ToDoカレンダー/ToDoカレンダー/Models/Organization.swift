//
//  Organization.swift
//  ToDoカレンダー
//
//  Created by 加藤 瑞樹 on 2026/01/03.
//

import Foundation
import SwiftData
import SwiftUI

/// タグ（カテゴリ）- タスクが直接参照
@Model
class TaskFolder {
    var name: String
    var calendar: AppCalendar?

    // カラー設定
    var colorName: String?

    // アイコン設定（SF Symbols）
    var iconName: String?

    // 並び順
    var sortOrder: Int = 0

    // テンプレートかどうか（タグ管理画面で作成 = true、タスク作成時に作成 = false）
    var isTemplate: Bool = false

    // フォルダ削除時は、中のタスクを「未分類」にする
    @Relationship(deleteRule: .nullify) var items: [TodoItem] = []

    init(name: String, calendar: AppCalendar? = nil, colorName: String? = nil, iconName: String? = nil, sortOrder: Int = 0, isTemplate: Bool = false) {
        self.name = name
        self.calendar = calendar
        self.colorName = colorName
        self.iconName = iconName
        self.sortOrder = sortOrder
        self.isTemplate = isTemplate
    }

    // カラー名からSwiftUI Colorを取得
    var color: Color {
        switch colorName {
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

    // 利用可能なカラー一覧
    static let availableColors: [(name: String, display: String)] = [
        ("red", "レッド"),
        ("blue", "ブルー"),
        ("green", "グリーン"),
        ("orange", "オレンジ"),
        ("purple", "パープル"),
        ("pink", "ピンク"),
        ("yellow", "イエロー"),
        ("gray", "グレー")
    ]

    // 利用可能なアイコン一覧
    static let availableIcons: [(name: String, display: String)] = [
        ("folder.fill", "フォルダ"),
        ("cart.fill", "買い物"),
        ("briefcase.fill", "仕事"),
        ("book.fill", "勉強"),
        ("house.fill", "家"),
        ("heart.fill", "健康"),
        ("gamecontroller.fill", "趣味"),
        ("car.fill", "移動"),
        ("fork.knife", "食事"),
        ("phone.fill", "連絡"),
        ("star.fill", "重要"),
        ("flag.fill", "フラグ")
    ]
}
