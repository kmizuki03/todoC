import SwiftUI

struct TodoMemoView: View {
    @Environment(\.dismiss) private var dismiss

    @Bindable var item: TodoItem

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(item.title)
                        .font(.title3)
                        .fontWeight(.semibold)

                    HStack(spacing: 12) {
                        if item.isTimeSet {
                            Label {
                                Text(item.date, style: .time)
                            } icon: {
                                Image(systemName: "clock")
                            }
                        }

                        if !item.location.isEmpty {
                            Label(item.location, systemImage: "mappin.and.ellipse")
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    Divider()

                    if item.memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("メモはありません")
                            .foregroundStyle(.secondary)
                    } else {
                        Text(item.memo)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(16)
            }
            .navigationTitle("メモ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}
