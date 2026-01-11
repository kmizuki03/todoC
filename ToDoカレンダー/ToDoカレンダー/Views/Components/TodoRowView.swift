//
//  TodoRowView.swift
//  ToDoカレンダー
//
//  Created by 加藤 瑞樹 on 2026/01/03.
//

import SwiftUI

struct TodoRowView: View {
    var title: String
    @Binding var isCompleted: Bool
    var isTimeSet: Bool
    var date: Date
    var location: String
    var folderName: String?
    var hasMemo: Bool = false

    var body: some View {
        HStack(alignment: .center) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundColor(isCompleted ? .green : .gray)
                .onTapGesture { withAnimation { isCompleted.toggle() } }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .strikethrough(isCompleted)
                    .foregroundColor(isCompleted ? .gray : .primary)

                HStack(spacing: 12) {
                    if isTimeSet {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                            Text(date, style: .time)
                        }
                    }

                    if !location.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.and.ellipse")
                            Text(location)
                        }
                    }

                    // リスト名ではなく「フォルダ名」を表示
                    if let folderName {
                        Text(folderName)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }

                    if hasMemo {
                        Image(systemName: "note.text")
                            .font(.caption)
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
