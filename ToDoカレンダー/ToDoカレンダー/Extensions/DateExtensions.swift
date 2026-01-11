//
//  DateExtensions.swift
//  ToDoカレンダー
//
//  Created by 加藤 瑞樹 on 2026/01/03.
//

import Foundation

extension Date {
    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy年 M月"
        return formatter
    }()

    // その月の日付をすべて取得
    func getAllDays() -> [Date] {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: self))!
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!

        return range.compactMap { day -> Date? in
            return calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
    }

    // 月初の空白埋め（1日が何曜日か：日曜=0, 月曜=1...）
    func startOffset() -> Int {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: self))!
        return calendar.component(.weekday, from: startOfMonth) - 1
    }

    // "2024年 1月" のような表示用
    func formatMonth() -> String {
        Self.monthFormatter.string(from: self)
    }

    /// 指定日を含む月の月初（00:00）
    func startOfMonth() -> Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self))
            ?? self
    }

    /// 基準日（base）の「日」を維持しつつ、month の月内に収まるように日付を調整
    func adjustedDate(inMonth month: Date) -> Date {
        let calendar = Calendar.current

        let baseDay = calendar.component(.day, from: self)
        let year = calendar.component(.year, from: month)
        let monthValue = calendar.component(.month, from: month)

        let startOfMonth = month.startOfMonth()
        let daysInMonth = calendar.range(of: .day, in: .month, for: startOfMonth)?.count ?? 28

        let clampedDay = min(max(1, baseDay), daysInMonth)
        return calendar.date(from: DateComponents(year: year, month: monthValue, day: clampedDay))
            ?? startOfMonth
    }
}
