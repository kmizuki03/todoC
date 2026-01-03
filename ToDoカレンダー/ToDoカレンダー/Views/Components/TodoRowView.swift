//
//  TodoRowView.swift
//  ToDoカレンダー
//
//  Created by 加藤 瑞樹 on 2026/01/03.
//

import SwiftUI

struct TodoRowView: View {
    @Bindable var item: TodoItem
    
    var body: some View {
        HStack(alignment: .center) {
            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundColor(item.isCompleted ? .green : .gray)
                .onTapGesture { withAnimation { item.isCompleted.toggle() } }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.body)
                    .strikethrough(item.isCompleted)
                    .foregroundColor(item.isCompleted ? .gray : .primary)
                
                HStack(spacing: 12) {
                    if item.isTimeSet {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                            Text(item.date, style: .time)
                        }
                    }
                    
                    if !item.location.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.and.ellipse")
                            Text(item.location)
                        }
                    }
                    
                    // リスト名ではなく「フォルダ名」を表示
                    if let folderName = item.folder?.name {
                        Text(folderName) // アイコンや色はお好みで
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
