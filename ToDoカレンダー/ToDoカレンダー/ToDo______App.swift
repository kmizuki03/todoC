//
//  ToDo______App.swift
//  ToDoカレンダー
//
//  Created by 加藤 瑞樹 on 2026/01/03.
//

import SwiftUI
import SwiftData

@main
struct ToDo_______App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // TaskList を削除し、3つだけにしました
        .modelContainer(for: [TodoItem.self, TaskFolder.self, AppCalendar.self])
    }
}
