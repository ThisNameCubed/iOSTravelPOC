import SwiftUI

/// Optional calendar. Slides up over home, the chat or results; dates flow back to Atlas.
struct CalendarSheet: View {
    @Environment(AppState.self) private var state
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    private struct Cell: Identifiable {
        let id: Int
        let date: Date?
    }

    private var cells: [Cell] {
        let month = state.displayedMonth
        let firstWeekday = gregorian.component(.weekday, from: month) - 1
        let days = gregorian.range(of: .day, in: .month, for: month)?.count ?? 30
        let blanks = (0..<firstWeekday).map { Cell(id: -1 - $0, date: nil) }
        let dates = (0..<days).map { Cell(id: $0, date: addDays($0, to: month)) }
        return blanks + dates
    }

    private var cheapThreshold: Int {
        let fares = cells.compactMap(\.date).map { fare(on: $0, base: state.destination.base) }.sorted()
        return fares.isEmpty ? 0 : fares[fares.count / 4]
    }

    var body: some View {
        VStack(spacing: 0) {
            modeToggle
                .padding(.top, 24)

            HStack {
                Text(state.displayedMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.system(size: 19, weight: .bold))
                Spacer()
                monthButton("chevron.left", label: "Previous month") { state.moveMonth(-1) }
                monthButton("chevron.right", label: "Next month") { state.moveMonth(1) }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 8)

            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"].indices, id: \.self) { i in
                    Text(["S", "M", "T", "W", "T", "F", "S"][i])
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.soft)
                        .frame(height: 24)
                }
                ForEach(cells) { cell in
                    if let date = cell.date {
                        DayCell(date: date, threshold: cheapThreshold)
                    } else {
                        Color.clear.frame(height: 52)
                    }
                }
            }
            .padding(.horizontal, 12)

            HStack(spacing: 14) {
                legend(Theme.green, "Lowest fares")
                legend(Theme.gold, "Atlas suggestion")
                Spacer()
                Text("Round trip").foregroundStyle(Theme.soft)
            }
            .font(.system(size: 12))
            .foregroundStyle(Theme.muted)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)

            hint

            HStack(spacing: 8) {
                ForEach([0, 1, 3], id: \.self) { value in
                    Button { state.flexDays = value } label: {
                        Chip(text: value == 0 ? "Exact dates" : "± \(value) day\(value == 1 ? "" : "s")",
                             style: state.flexDays == value ? .selected : .plain, height: 32)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Spacer(minLength: 12)

            PrimaryButton(title: "\(state.calendarSource == .results ? "Update results" : "Send to Atlas") · \(state.rangeText)",
                          icon: nil) { state.sendDates() }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
        .background(Theme.surface)
    }

    private var modeToggle: some View {
        HStack(spacing: 0) {
            Button { state.askAtlasFromSheet() } label: {
                HStack(spacing: 8) {
                    AgentOrb(size: 20)
                    Text("Ask Atlas")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.muted)
                .frame(maxWidth: .infinity, minHeight: 38)
            }
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                Text("Calendar")
            }
            .font(.system(size: 15, weight: .semibold))
            .frame(maxWidth: .infinity, minHeight: 38)
            .background(Theme.surface, in: Capsule())
            .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
            .accessibilityAddTraits(.isSelected)
        }
        .padding(4)
        .background(Theme.segment, in: Capsule())
        .padding(.horizontal, 16)
    }

    @ViewBuilder private var hint: some View {
        HStack(spacing: 10) {
            AgentOrb(size: 22)
            if let shift = state.bestShift {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Leave \(weekdayName(shift.date)), \(shortDate(shift.date)) to save $\(shift.save).")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Your calendar is free that day.").font(.system(size: 12)).foregroundStyle(Theme.muted)
                }
                Spacer()
                Button { state.shift(to: shift.date) } label: { Chip(text: "Apply", style: .red, height: 32) }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text("These are the cheapest dates nearby.").font(.system(size: 13, weight: .semibold))
                    Text("Your calendar is free the whole trip.").font(.system(size: 12)).foregroundStyle(Theme.muted)
                }
                Spacer()
            }
        }
        .padding(12)
        .background(Theme.redTint, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, 16)
    }

    private func legend(_ color: Color, _ text: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(text)
        }
    }

    private func monthButton(_ icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 36, height: 36)
                .overlay(Circle().stroke(Theme.line))
        }
        .accessibilityLabel(label)
    }
}

struct DayCell: View {
    @Environment(AppState.self) private var state
    let date: Date
    let threshold: Int

    var body: some View {
        let price = fare(on: date, base: state.destination.base)
        let isStart = gregorian.isDate(date, inSameDayAs: state.start)
        let isEnd = gregorian.isDate(date, inSameDayAs: state.end)
        let isEdge = isStart || isEnd
        let inRange = date >= state.start && date <= state.end
        let cheap = price <= threshold
        let past = date < gregorian.startOfDay(for: Date())
        let isTip = state.bestShift.map { gregorian.isDate($0.date, inSameDayAs: date) } ?? false

        Button { state.tapDay(date) } label: {
            ZStack {
                if inRange {
                    UnevenRoundedRectangle(topLeadingRadius: isStart ? 24 : 0, bottomLeadingRadius: isStart ? 24 : 0,
                                           bottomTrailingRadius: isEnd ? 24 : 0, topTrailingRadius: isEnd ? 24 : 0)
                        .fill(Theme.redTint)
                        .padding(.vertical, 3)
                }
                if isEdge {
                    Circle().fill(Theme.red).frame(width: 44, height: 44)
                }
                VStack(spacing: 1) {
                    Text("\(gregorian.component(.day, from: date))")
                        .font(.system(size: 15, weight: isEdge ? .semibold : .medium))
                        .foregroundStyle(isEdge ? .white : Theme.ink)
                    Text("$\(price)")
                        .font(.system(size: 9.5, weight: cheap ? .semibold : .regular))
                        .foregroundStyle(isEdge ? .white : cheap ? Theme.green : Theme.soft)
                }
                if isTip {
                    Circle()
                        .fill(Theme.gold)
                        .frame(width: 8, height: 8)
                        .overlay(Circle().stroke(.white, lineWidth: 1.5))
                        .offset(x: 14, y: -17)
                }
            }
            .frame(height: 52)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(past)
        .opacity(past ? 0.3 : 1)
        .accessibilityLabel("\(date.formatted(date: .complete, time: .omitted)), $\(price)")
        .accessibilityAddTraits(isEdge ? .isSelected : [])
    }
}
