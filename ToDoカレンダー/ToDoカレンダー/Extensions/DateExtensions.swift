//
//  DateExtensions.swift
//  ToDoカレンダー
//
//  Created by 加藤 瑞樹 on 2026/01/03.
//

import Foundation

extension Date {
    // その月の日付をすべて取得
    func getAllDays() -> [Date] {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: self))!
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        
        return range.compactMap { day -> Date? in
            return calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
    }
    
    // 月初の空白埋め（1日が何曜日か：日曜=0, 月曜=1...）
    func startOffset() -> Int {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: self))!
        return calendar.component(.weekday, from: startOfMonth) - 1
    }
    
    // "2024年 1月" のような表示用
    func formatMonth() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy年 M月"
        return formatter.string(from: self)
    }
}
