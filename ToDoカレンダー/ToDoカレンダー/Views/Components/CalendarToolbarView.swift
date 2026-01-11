import SwiftData
import SwiftUI

struct CalendarToolbarView: View {
    let allCalendars: [AppCalendar]
    @Binding var selectedCalendar: AppCalendar?

    @Binding var isShowingAddSheet: Bool
    @Binding var isShowingTemplateManager: Bool
    @Binding var isShowingCalendarManager: Bool
    @Binding var isShowingNewCalendarAlert: Bool

    @Binding var appAppearance: AppAppearance

    var body: some View {
        HStack(spacing: 12) {
            Button(action: { isShowingTemplateManager = true }) {
                Image(systemName: "tag")
                    .font(.headline)
                    .frame(width: 36, height: 36)
                    .background(Color.gray.opacity(0.12))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            Menu {
                ForEach(allCalendars) { cal in
                    Button {
                        selectedCalendar = cal
                    } label: {
                        if selectedCalendar?.persistentModelID == cal.persistentModelID {
                            Label(cal.name, systemImage: "checkmark")
                        } else {
                            Text(cal.name)
                        }
                    }
                }

                Divider()
                Button("＋ カレンダーを追加") { isShowingNewCalendarAlert = true }
                Button("カレンダー管理") { isShowingCalendarManager = true }

                Divider()

                Button {
                    appAppearance = .system
                } label: {
                    if appAppearance == .system {
                        Label("テーマ: システム", systemImage: "checkmark")
                    } else {
                        Text("テーマ: システム")
                    }
                }
                Button {
                    appAppearance = .light
                } label: {
                    if appAppearance == .light {
                        Label("テーマ: ライト", systemImage: "checkmark")
                    } else {
                        Text("テーマ: ライト")
                    }
                }
                Button {
                    appAppearance = .dark
                } label: {
                    if appAppearance == .dark {
                        Label("テーマ: ダーク", systemImage: "checkmark")
                    } else {
                        Text("テーマ: ダーク")
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(selectedCalendar?.name ?? "カレンダー")
                        .font(.headline)
                    Image(systemName: "chevron.down")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .foregroundColor(.primary)
            }

            Spacer(minLength: 0)

            Button(action: { isShowingAddSheet = true }) {
                Image(systemName: "plus")
                    .font(.headline)
                    .frame(width: 36, height: 36)
                    .background(Color.gray.opacity(0.12))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }
}
