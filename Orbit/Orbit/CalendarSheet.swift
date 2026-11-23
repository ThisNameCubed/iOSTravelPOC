import SwiftUI

/// Optional range calendar. The agent picks dates by default; this lets people choose their own.
struct CalendarSheet: View {
    @Environment(TripStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var start: Date?
    @State private var end: Date?
    @State private var monthOffset = 0

    private let cal = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(start.map(Fmt.day) ?? "Departure")  →  \(end.map(Fmt.day) ?? "Return")")
                    .font(.display(19))
                    .foregroundStyle(Theme.text)
                Spacer()
                Text(nightsText).font(.system(size: 13)).foregroundStyle(Theme.muted)
            }
            .padding(.top, 22)

            HStack {
                Button { monthOffset -= 1 } label: {
                    Image(systemName: "chevron.left").frame(width: 44, height: 44)
                }
                .disabled(monthOffset <= 0)
                .foregroundStyle(monthOffset <= 0 ? Theme.disabled : Theme.text)
                .accessibilityLabel("Previous month")
                Spacer()
                Text(month.formatted(.dateTime.month(.wide).year()))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.text)
                Spacer()
                Button { monthOffset = min(11, monthOffset + 1) } label: {
                    Image(systemName: "chevron.right").frame(width: 44, height: 44)
                }
                .foregroundStyle(Theme.text)
                .accessibilityLabel("Next month")
            }

            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(Array(["S", "M", "T", "W", "T", "F", "S"].enumerated()), id: \.offset) { _, d in
                    Text(d).font(.system(size: 12)).foregroundStyle(Theme.faint).padding(.bottom, 6)
                }
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    dayCell(day)
                }
            }

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                Button {
                    store.clearDates()
                    dismiss()
                } label: {
                    Text("Let agent choose")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.text3)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .overlay(Capsule().strokeBorder(Theme.border, lineWidth: 1))
                }
                Button {
                    if let s = start, let e = end {
                        store.applyDates(start: s, end: e)
                        dismiss()
                    }
                } label: {
                    Text("Use these dates")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.onPrimary)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(Capsule().fill(Theme.primaryGradient))
                        .opacity(end == nil ? 0.4 : 1)
                }
                .disabled(end == nil)
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 20)
        .onAppear {
            start = cal.startOfDay(for: store.depDate)
            end = cal.startOfDay(for: store.retDate)
            let now = cal.dateComponents([.year, .month], from: Date())
            let dep = cal.dateComponents([.year, .month], from: store.depDate)
            monthOffset = max(0, ((dep.year ?? 0) - (now.year ?? 0)) * 12 + (dep.month ?? 0) - (now.month ?? 0))
        }
    }

    private var nightsText: String {
        guard let s = start, let e = end else { return "Pick a return day" }
        let n = cal.dateComponents([.day], from: s, to: e).day ?? 0
        return n == 1 ? "1 night" : "\(n) nights"
    }

    private var month: Date {
        let first = cal.date(from: cal.dateComponents([.year, .month], from: Date())) ?? Date()
        return cal.date(byAdding: .month, value: monthOffset, to: first) ?? first
    }

    /// Sunday-first grid; nil = padding cell.
    private var days: [Date?] {
        let first = month
        let lead = cal.component(.weekday, from: first) - 1
        let count = cal.range(of: .day, in: .month, for: first)?.count ?? 30
        var out: [Date?] = Array(repeating: nil, count: lead)
        for d in 0..<count { out.append(cal.date(byAdding: .day, value: d, to: first)) }
        while out.count % 7 != 0 { out.append(nil) }
        return out
    }

    @ViewBuilder
    private func dayCell(_ day: Date?) -> some View {
        if let day {
            let today = cal.startOfDay(for: Date())
            let past = day < today
            let isStart = start.map { cal.isDate($0, inSameDayAs: day) } ?? false
            let isEnd = end.map { cal.isDate($0, inSameDayAs: day) } ?? false
            let inRange: Bool = {
                guard let s = start, let e = end else { return false }
                return day > s && day < e
            }()
            let band = (inRange || (isStart && end != nil) || isEnd)

            Button { pick(day) } label: {
                Text("\(cal.component(.day, from: day))")
                    .font(.system(size: 15, weight: isStart || isEnd ? .semibold : .regular))
                    .foregroundStyle(isStart || isEnd ? Theme.onAccent : past ? Theme.disabled : inRange ? Theme.accentInk : Theme.text)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(isStart || isEnd ? Theme.accent : .clear))
            }
            .buttonStyle(.plain)
            .disabled(past)
            .frame(maxWidth: .infinity).frame(height: 44)
            .background(alignment: isStart ? .trailing : isEnd ? .leading : .center) {
                if band {
                    Rectangle()
                        .fill(Theme.accent.opacity(0.13))
                        .frame(maxWidth: (isStart || isEnd) ? .infinity : .infinity)
                        .padding(isStart ? .leading : isEnd ? .trailing : [], 22)
                }
            }
            .accessibilityLabel(day.formatted(date: .complete, time: .omitted))
            .accessibilityAddTraits(isStart || isEnd ? .isSelected : [])
        } else {
            Color.clear.frame(height: 44)
        }
    }

    private func pick(_ day: Date) {
        if start == nil || end != nil || day <= (start ?? day) {
            start = day
            end = nil
        } else {
            end = day
        }
    }
}
