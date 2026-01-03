//
//  TodoItem.swift
//  ToDoカレンダー
//
//  Created by 加藤 瑞樹 on 2026/01/03.
//

import Foundation
import SwiftData

@Model
class TodoItem {
    var title: String
    var date: Date
    var isTimeSet: Bool
    var location: String
    var isCompleted: Bool
    
    var calendar: AppCalendar? // 親カレンダー
    var folder: TaskFolder?    // 所属フォルダ（カテゴリー）
    
    init(title: String, date: Date, isTimeSet: Bool = true, location: String = "", isCompleted: Bool = false, calendar: AppCalendar? = nil, folder: TaskFolder? = nil) {
        self.title = title
        self.date = date
        self.isTimeSet = isTimeSet
        self.location = location
        self.isCompleted = isCompleted
        self.calendar = calendar
        self.folder = folder
    }
}
