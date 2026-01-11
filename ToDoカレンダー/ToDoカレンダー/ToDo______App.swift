//
//  ToDo______App.swift
//  ToDoカレンダー
//
//  Created by 加藤 瑞樹 on 2026/01/03.
//

import Foundation
import SwiftData
import SwiftUI

@main
struct ToDo_______App: App {
    @AppStorage("appAppearance") private var appAppearanceRaw = AppAppearance.system.rawValue

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(AppAppearance(rawValue: appAppearanceRaw)?.colorScheme)
                .environment(\.locale, Locale(identifier: "ja_JP"))
        }
        // TaskList を削除し、3つだけにしました
        .modelContainer(for: [TodoItem.self, TaskFolder.self, AppCalendar.self])
    }
}
