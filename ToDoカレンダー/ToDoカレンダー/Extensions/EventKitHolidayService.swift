//
//  EventKitHolidayService.swift
//  ToDoカレンダー
//
//  Created by 加藤 瑞樹 on 2026/01/11.
//

import Combine
import EventKit
import Foundation

@MainActor
final class EventKitHolidayService: ObservableObject {
    @Published private(set) var authorizationStatus: EKAuthorizationStatus =
        EKEventStore.authorizationStatus(for: .event)
    @Published private(set) var holidayNamesByDayKey: [Int: String] = [:]
    @Published private(set) var lastErrorMessage: String? = nil

    private let store = EKEventStore()

    func refreshHolidays(forMonthContaining month: Date, timeZone: TimeZone = .current) async {
        lastErrorMessage = nil
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)

        do {
            let granted = try await requestAccessIfNeeded()
            guard granted else {
                holidayNamesByDayKey = [:]
                return
            }

            let holidayCalendars = store.calendars(for: .event).filter { isHolidayCalendar($0) }
            guard !holidayCalendars.isEmpty else {
                holidayNamesByDayKey = [:]
                lastErrorMessage =
                    "祝日カレンダーが見つかりませんでした。iOSの『カレンダー』アプリ側で『日本の祝日』などのカレンダーを追加すると、自動で祝日名を表示できます。"
                return
            }

            let (start, end) = monthDateRange(month, timeZone: timeZone)
            let predicate = store.predicateForEvents(
                withStart: start, end: end, calendars: holidayCalendars)
            let events = store.events(matching: predicate)

            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = timeZone

            var map: [Int: String] = [:]
            for event in events {
                // 祝日カレンダーは基本的に終日予定。念のため全イベントを許容しつつ、開始日で束ねる。
                let key = dayKey(for: event.startDate, calendar: calendar)
                if map[key] == nil {
                    map[key] = event.title
                }
            }

            holidayNamesByDayKey = map
        } catch {
            holidayNamesByDayKey = [:]
            lastErrorMessage = error.localizedDescription
        }
    }

    func holidayName(for date: Date, timeZone: TimeZone = .current) -> String? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return holidayNamesByDayKey[dayKey(for: date, calendar: calendar)]
    }

    // MARK: - Private

    private func requestAccessIfNeeded() async throws -> Bool {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)

        if #available(iOS 17.0, *) {
            switch authorizationStatus {
            case .fullAccess, .authorized:
                return true
            case .notDetermined:
                let granted = try await store.requestFullAccessToEvents()
                authorizationStatus = EKEventStore.authorizationStatus(for: .event)
                return granted
            case .denied, .restricted, .writeOnly:
                lastErrorMessage = "カレンダーへのアクセスが許可されていません。設定アプリで許可してください。"
                return false
            default:
                return false
            }
        } else {
            switch authorizationStatus {
            case .authorized:
                return true
            case .notDetermined:
                let granted = try await store.requestAccess(to: .event)
                authorizationStatus = EKEventStore.authorizationStatus(for: .event)
                return granted
            case .denied, .restricted:
                lastErrorMessage = "カレンダーへのアクセスが許可されていません。設定アプリで許可してください。"
                return false
            default:
                return false
            }
        }
    }

    private func isHolidayCalendar(_ calendar: EKCalendar) -> Bool {
        let title = calendar.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = title.lowercased()

        // よくある祝日カレンダー名を雑に拾う（ユーザー環境差があるため）
        if title.contains("祝日") { return true }
        if lower.contains("holiday") || lower.contains("holidays") { return true }
        if lower.contains("japan") && lower.contains("holiday") { return true }

        return false
    }

    private func monthDateRange(_ date: Date, timeZone: TimeZone) -> (Date, Date) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let comps = calendar.dateComponents([.year, .month], from: date)
        let startOfMonth =
            calendar.date(from: DateComponents(year: comps.year, month: comps.month, day: 1))
            ?? calendar.startOfDay(for: date)
        let endOfMonth =
            calendar.date(byAdding: DateComponents(month: 1), to: startOfMonth)
            ?? calendar.date(byAdding: .day, value: 31, to: startOfMonth)!

        return (startOfMonth, endOfMonth)
    }

    private func dayKey(for date: Date, calendar: Calendar) -> Int {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        let year = c.year ?? 0
        let month = c.month ?? 0
        let day = c.day ?? 0
        return year * 10_000 + month * 100 + day
    }
}
