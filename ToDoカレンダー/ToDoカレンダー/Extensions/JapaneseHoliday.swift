//
//  JapaneseHoliday.swift
//  ToDoカレンダー
//
//  Created by 加藤 瑞樹 on 2026/01/11.
//

import Foundation

enum JapaneseHoliday {
    private static var nameCache: [Int: [Int: String]] = [:]

    /// 日本の祝日かどうか（2000年以降を主対象。2019-2021の特例は対応）
    static func isHoliday(_ date: Date, timeZone: TimeZone = .current) -> Bool {
        holidayName(date, timeZone: timeZone) != nil
    }

    /// 祝日名を返す（祝日でない場合はnil）
    static func holidayName(_ date: Date, timeZone: TimeZone = .current) -> String? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = comps.year, let month = comps.month, let day = comps.day else { return nil }

        let names = holidayNames(for: year, calendar: calendar)
        return names[dayKey(year: year, month: month, day: day)]
    }

    // MARK: - Core

    private static func holidayNames(for year: Int, calendar: Calendar) -> [Int: String] {
        if let cached = nameCache[year] { return cached }

        var names: [Int: String] = [:]

        func add(_ month: Int, _ day: Int, _ name: String) {
            names[dayKey(year: year, month: month, day: day)] = name
        }

        func add(date: Date, _ name: String) {
            let c = calendar.dateComponents([.year, .month, .day], from: date)
            guard let y = c.year, let m = c.month, let d = c.day else { return }
            names[dayKey(year: y, month: m, day: d)] = name
        }

        // 固定日
        add(1, 1, "元日")
        add(2, 11, "建国記念の日")
        add(11, 3, "文化の日")
        add(11, 23, "勤労感謝の日")

        // 天皇誕生日（2019はなし、2020〜は2/23）
        if year >= 2020 {
            add(2, 23, "天皇誕生日")
        }

        // 春分の日 / 秋分の日
        add(3, vernalEquinoxDay(year: year), "春分の日")
        add(9, autumnEquinoxDay(year: year), "秋分の日")

        // 4〜5月
        if year >= 2007 {
            add(4, 29, "昭和の日")
            add(5, 4, "みどりの日")
        } else {
            add(4, 29, "みどりの日")
            // 2000〜2006の5/4は国民の休日（祝日挟み）として後段で付与されるが、
            // 明示しておくと表示が安定する。
            add(5, 4, "国民の休日")
        }
        add(5, 3, "憲法記念日")
        add(5, 5, "こどもの日")

        // ハッピーマンデー系
        if year >= 2000 {
            if let d = nthWeekday(ofMonth: 1, year: year, weekday: 2, nth: 2, calendar: calendar) {
                add(date: d, "成人の日")
            }

            // スポーツの日/体育の日: 10月第2月曜（2020/2021は特例）
            if !(year == 2020 || year == 2021) {
                if let d = nthWeekday(ofMonth: 10, year: year, weekday: 2, nth: 2, calendar: calendar) {
                    let name = year >= 2020 ? "スポーツの日" : "体育の日"
                    add(date: d, name)
                }
            }
        }

        // 海の日
        if year == 2020 {
            add(7, 23, "海の日")
        } else if year == 2021 {
            add(7, 22, "海の日")
        } else if year >= 2003 {
            if let d = nthWeekday(ofMonth: 7, year: year, weekday: 2, nth: 3, calendar: calendar) {
                add(date: d, "海の日")
            }
        } else {
            add(7, 20, "海の日")
        }

        // 山の日（2016〜、2020/2021は特例）
        if year == 2020 {
            add(8, 10, "山の日")
        } else if year == 2021 {
            add(8, 8, "山の日")
        } else if year >= 2016 {
            add(8, 11, "山の日")
        }

        // 敬老の日
        if year >= 2003 {
            if let d = nthWeekday(ofMonth: 9, year: year, weekday: 2, nth: 3, calendar: calendar) {
                add(date: d, "敬老の日")
            }
        } else {
            add(9, 15, "敬老の日")
        }

        // スポーツの日（特例）
        if year == 2020 {
            add(7, 24, "スポーツの日")
        } else if year == 2021 {
            add(7, 23, "スポーツの日")
        }

        // 2019 特例（即位関連）
        if year == 2019 {
            add(5, 1, "即位の日")
            add(10, 22, "即位礼正殿の儀")
        }

        // 祝日の振替休日（最初に付与）
        applySubstituteHolidays(year: year, calendar: calendar, into: &names)

        // 国民の休日（祝日に挟まれた平日）
        applyCitizensHolidays(year: year, calendar: calendar, into: &names)

        // 国民の休日で増えた分が日曜に当たることは基本ないが、念のため再適用
        applySubstituteHolidays(year: year, calendar: calendar, into: &names)

        nameCache[year] = names
        return names
    }

    private static func applySubstituteHolidays(year: Int, calendar: Calendar, into names: inout [Int: String]) {
        guard let start = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let end = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)) else { return }

        var date = start
        while date < end {
            let comps = calendar.dateComponents([.year, .month, .day, .weekday], from: date)
            guard let y = comps.year, let m = comps.month, let d = comps.day, let weekday = comps.weekday else {
                date = calendar.date(byAdding: .day, value: 1, to: date)!
                continue
            }

            let key = dayKey(year: y, month: m, day: d)
            if names[key] != nil && weekday == 1 {
                var substitute = calendar.date(byAdding: .day, value: 1, to: date)!
                while true {
                    let sc = calendar.dateComponents([.year, .month, .day, .weekday], from: substitute)
                    guard let sy = sc.year, let sm = sc.month, let sd = sc.day else { break }
                    let sk = dayKey(year: sy, month: sm, day: sd)
                    if names[sk] == nil {
                        names[sk] = "振替休日"
                        break
                    }
                    substitute = calendar.date(byAdding: .day, value: 1, to: substitute)!
                }
            }

            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
    }

    private static func applyCitizensHolidays(year: Int, calendar: Calendar, into names: inout [Int: String]) {
        guard let start = calendar.date(from: DateComponents(year: year, month: 1, day: 2)),
              let end = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)) else { return }

        var date = start
        while date < end {
            let comps = calendar.dateComponents([.year, .month, .day], from: date)
            guard let y = comps.year, let m = comps.month, let d = comps.day else {
                date = calendar.date(byAdding: .day, value: 1, to: date)!
                continue
            }

            let key = dayKey(year: y, month: m, day: d)
            if names[key] == nil {
                let prev = calendar.date(byAdding: .day, value: -1, to: date)!
                let next = calendar.date(byAdding: .day, value: 1, to: date)!

                let pc = calendar.dateComponents([.year, .month, .day], from: prev)
                let nc = calendar.dateComponents([.year, .month, .day], from: next)

                if let py = pc.year, let pm = pc.month, let pd = pc.day,
                   let ny = nc.year, let nm = nc.month, let nd = nc.day {
                    let prevKey = dayKey(year: py, month: pm, day: pd)
                    let nextKey = dayKey(year: ny, month: nm, day: nd)

                    if names[prevKey] != nil && names[nextKey] != nil {
                        names[key] = "国民の休日"
                    }
                }
            }

            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
    }

    // MARK: - Helpers

    private static func dayKey(year: Int, month: Int, day: Int) -> Int {
        year * 10_000 + month * 100 + day
    }

    /// nth=1... の指定で、その月の第n曜日の日付を返す
    /// weekday: 1=日, 2=月, ... 7=土
    private static func nthWeekday(ofMonth month: Int, year: Int, weekday: Int, nth: Int, calendar: Calendar) -> Date? {
        guard nth >= 1 else { return nil }
        guard let firstDay = calendar.date(from: DateComponents(year: year, month: month, day: 1)) else { return nil }

        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let delta = (weekday - firstWeekday + 7) % 7
        let day = 1 + delta + (nth - 1) * 7

        return calendar.date(from: DateComponents(year: year, month: month, day: day))
    }

    // 1980年を基準にした近似式（日本の祝日法で一般に用いられる式）
    private static func vernalEquinoxDay(year: Int) -> Int {
        // 2000〜2099向け
        let base = 20.8431
        let day = Int(floor(base + 0.242194 * Double(year - 1980) - floor(Double(year - 1980) / 4.0)))
        return max(19, min(22, day))
    }

    private static func autumnEquinoxDay(year: Int) -> Int {
        // 2000〜2099向け
        let base = 23.2488
        let day = Int(floor(base + 0.242194 * Double(year - 1980) - floor(Double(year - 1980) / 4.0)))
        return max(22, min(24, day))
    }
}
