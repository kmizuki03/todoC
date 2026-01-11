import Foundation
import SwiftData

enum AppCalendarIntegrity {
    /// デフォルトカレンダーの存在・一意性を保証し、該当カレンダーを返します。
    /// - Note: 既存データ移行として、旧ロジックの "メイン" を優先します。
    @MainActor
    @discardableResult
    static func ensureDefaultCalendarExists(modelContext: ModelContext) -> AppCalendar? {
        do {
            let descriptor = FetchDescriptor<AppCalendar>(sortBy: [SortDescriptor(\.name)])
            let calendars = try modelContext.fetch(descriptor)

            if calendars.isEmpty {
                let defaultCal = AppCalendar(name: "メイン", isDefault: true)
                modelContext.insert(defaultCal)
                return defaultCal
            }

            let defaults = calendars.filter { $0.isDefault }
            if let firstDefault = defaults.first {
                for extra in defaults.dropFirst() {
                    extra.isDefault = false
                }
                return firstDefault
            }

            if let legacyMain = calendars.first(where: { $0.name == "メイン" }) {
                legacyMain.isDefault = true
                return legacyMain
            }

            calendars.first?.isDefault = true
            return calendars.first
        } catch {
            return nil
        }
    }
}
