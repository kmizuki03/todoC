//
//  TodoItem.swift
//  ToDoカレンダー
//
//  Created by 加藤 瑞樹 on 2026/01/03.
//

import Foundation
import SwiftData
import SwiftUI

@Model
class TodoItem {
    var title: String
    var date: Date
    var isTimeSet: Bool
    var location: String
    var isCompleted: Bool

    var calendar: AppCalendar?
    var folder: TaskFolder?

    // タグ情報のバックアップ（タグ削除後も表示用に保持）
    var tagName: String?
    var tagColorName: String?
    var tagIconName: String?

    init(title: String, date: Date, isTimeSet: Bool = true, location: String = "", isCompleted: Bool = false, calendar: AppCalendar? = nil, folder: TaskFolder? = nil) {
        self.title = title
        self.date = date
        self.isTimeSet = isTimeSet
        self.location = location
        self.isCompleted = isCompleted
        self.calendar = calendar
        self.folder = folder
        // タグ情報をバックアップ
        self.tagName = folder?.name
        self.tagColorName = folder?.colorName
        self.tagIconName = folder?.iconName
    }

    // 表示用のタグ名（folderがあればそちら、なければバックアップ）
    var displayTagName: String? {
        folder?.name ?? tagName
    }

    // 表示用のタグカラー
    var displayTagColor: Color {
        let colorName = folder?.colorName ?? tagColorName
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

    // 表示用のタグアイコン
    var displayTagIcon: String {
        folder?.iconName ?? tagIconName ?? "tag.fill"
    }

    // タグを設定（バックアップも更新）
    func setTag(_ newFolder: TaskFolder?) {
        folder = newFolder
        tagName = newFolder?.name
        tagColorName = newFolder?.colorName
        tagIconName = newFolder?.iconName
    }

    // タグ情報をクリア
    func clearTag() {
        folder = nil
        tagName = nil
        tagColorName = nil
        tagIconName = nil
    }
}
