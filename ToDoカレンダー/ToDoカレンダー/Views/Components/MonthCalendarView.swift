import SwiftUI

struct MonthCalendarView: View {
    @ObservedObject var viewModel: CalendarViewModel

    let daysOfWeek: [String]
    let swipeThreshold: CGFloat

    let targetCalendar: AppCalendar?
    let showAllCalendars: Bool

    let onDayTapped: (Date) -> Void

    private static let collapsedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy年M月d日(EEE)"
        return formatter
    }()

    var body: some View {
        VStack(spacing: viewModel.isCalendarCollapsed ? 8 : 15) {
            header

            if viewModel.isCalendarCollapsed {
                collapsedRow
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            if !viewModel.isCalendarCollapsed {
                daysOfWeekRow

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible()), count: 7),
                    spacing: 10
                ) {
                    ForEach(0..<viewModel.currentMonth.startOffset(), id: \.self) { _ in
                        Text("")
                    }

                    ForEach(viewModel.currentMonth.getAllDays(), id: \.self) { date in
                        if let calendar = targetCalendar {
                            DayCellView(
                                date: date,
                                isSelected: Calendar.current.isDate(
                                    date, inSameDayAs: viewModel.selectedDate),
                                targetCalendar: calendar,
                                showAllCalendars: showAllCalendars
                            )
                            .onTapGesture { onDayTapped(date) }
                        }
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding()
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onEnded { value in
                    let horizontal = value.translation.width
                    let vertical = value.translation.height

                    guard abs(horizontal) > abs(vertical) * 1.2 else { return }
                    guard abs(horizontal) > swipeThreshold else { return }

                    if horizontal < 0 {
                        viewModel.changeMonth(by: 1)
                    } else {
                        viewModel.changeMonth(by: -1)
                    }
                }
        )
    }

    private var header: some View {
        HStack {
            Button(action: { viewModel.changeMonth(by: -1) }) {
                Image(systemName: "chevron.left")
            }

            Spacer()

            Button(action: { viewModel.goToToday() }) {
                Text(viewModel.currentMonth.formatMonth())
                    .font(.title2.bold())
            }
            .buttonStyle(.plain)

            Spacer()

            HStack(spacing: 12) {
                Button(action: { viewModel.changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.isCalendarCollapsed.toggle()
                    }
                } label: {
                    Image(systemName: viewModel.isCalendarCollapsed ? "chevron.down" : "chevron.up")
                        .font(.subheadline.weight(.semibold))
                        .padding(6)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(viewModel.isCalendarCollapsed ? "カレンダーを開く" : "カレンダーを畳む")
            }
        }
        .padding(.horizontal)
    }

    private var collapsedRow: some View {
        HStack {
            Text(Self.collapsedDateFormatter.string(from: viewModel.selectedDate))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
                .textCase(nil)

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.isCalendarCollapsed = false
            }
        }
    }

    private var daysOfWeekRow: some View {
        HStack {
            ForEach(daysOfWeek, id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}
