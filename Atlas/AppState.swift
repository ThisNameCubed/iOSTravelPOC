import SwiftUI
import Observation

// MARK: - Calendar helpers

let gregorian: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = .current
    return c
}()

func makeDay(_ y: Int, _ m: Int, _ d: Int) -> Date {
    gregorian.date(from: DateComponents(year: y, month: m, day: d)) ?? Date()
}

func addDays(_ n: Int, to date: Date) -> Date {
    gregorian.date(byAdding: .day, value: n, to: date) ?? date
}

func shortDate(_ d: Date) -> String { d.formatted(.dateTime.month(.abbreviated).day()) }
func weekdayName(_ d: Date) -> String { d.formatted(.dateTime.weekday(.abbreviated)) }

/// Deterministic sample fare for a departure date, so the prototype feels consistent.
func fare(on date: Date, base: Int) -> Int {
    let c = gregorian.dateComponents([.year, .month, .day, .weekday], from: date)
    let y = Double(c.year ?? 2027), m = Double((c.month ?? 1) - 1), d = Double(c.day ?? 1)
    let x = sin(y * 7 + m * 31 + d * 12.9898) * 43758.5453
    let r = x - floor(x)
    let weekday = (c.weekday ?? 1) - 1 // 0 = Sunday
    var f = Double(base) * 0.7 + r * Double(base) * 0.22
    if weekday == 5 || weekday == 6 { f += 60 }
    if weekday == 2 || weekday == 3 { f -= 30 }
    return Int(f.rounded())
}

// MARK: - Models

struct Destination: Hashable {
    let key: String, name: String, code: String, stopCode: String, stopName: String
    let base: Int

    static let all: [Destination] = [
        Destination(key: "tokyo", name: "Tokyo", code: "NRT", stopCode: "HNL", stopName: "Honolulu", base: 900),
        Destination(key: "lisbon", name: "Lisbon", code: "LIS", stopCode: "JFK", stopName: "New York", base: 780),
        Destination(key: "bali", name: "Bali", code: "DPS", stopCode: "TPE", stopName: "Taipei", base: 1050),
        Destination(key: "sydney", name: "Sydney", code: "SYD", stopCode: "NAN", stopName: "Fiji", base: 1180),
        Destination(key: "paris", name: "Paris", code: "CDG", stopCode: "KEF", stopName: "Reykjavík", base: 820),
        Destination(key: "seoul", name: "Seoul", code: "ICN", stopCode: "HNL", stopName: "Honolulu", base: 860)
    ]
}

enum OptionKind: String, Hashable { case pick, fun, fastest }

struct FlightOption: Identifiable, Hashable {
    let kind: OptionKind
    let price: Int
    let oneTicket: Int
    let departTime: String
    let arriveTime: String
    let arrivalLabel: String
    let middle: String
    let maxLeg: Double
    let tags: [String]
    let why: String
    var id: String { kind.rawValue }

    var title: String {
        switch kind {
        case .pick: return "Atlas pick"
        case .fun: return "Fun route"
        case .fastest: return "Fastest"
        }
    }
    var savings: Int { oneTicket - price }
}

struct Stopover: Hashable { let city: String, length: String, extra: Int }

struct BookedTrip { let kind: OptionKind, name: String, code: String, stop: String, dates: String }

enum Route: Hashable { case chat, results, split, fun, review, booked }
enum CalendarSource { case home, chat, results }

enum ChatKind { case user, agent, steps, understood }

enum ChatAction: Hashable {
    case seeOptions, keepDates, openFun
    case applyShift(Date)

    var label: String {
        switch self {
        case .seeOptions: return "See options"
        case .keepDates: return "Keep my dates"
        case .openFun: return "See fun route"
        case .applyShift: return "Apply"
        }
    }
    var isPrimary: Bool {
        switch self {
        case .keepDates: return false
        default: return true
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let kind: ChatKind
    var text: String = ""
    var actions: [ChatAction] = []
}

// MARK: - App state

@MainActor
@Observable
final class AppState {
    // Navigation
    var path: [Route] = []
    var showCalendar = false
    var calendarSource: CalendarSource = .home
    var focusRequest = 0
    var toast: String? = nil

    // Trip request
    var query = ""
    var destination = Destination.all[0]
    var budget = 900
    var start = makeDay(2027, 3, 12)
    var end = makeDay(2027, 3, 24)
    var datesSet = false
    var flexible = false
    var flexDays = 0
    var constraints: [String] = []

    // Calendar sheet
    var displayedMonth = makeDay(2027, 3, 1)
    var pickingEnd = false

    // Chat
    var messages: [ChatMessage] = []
    var isTyping = false
    var stepsDone = 0
    var planned = false
    var quickReplies: [String] = []

    // Results and booking
    var filter = 0
    var protectOn = true
    var stopIndex = 0
    var hotelAnswer: Bool? = nil
    var choice: FlightOption? = nil
    var autopilot: [Bool] = [true, true, true, false]
    var booked: BookedTrip? = nil

    let filters = ["Best balance", "Cheapest", "Shortest legs", "Fun"]
    let ideas = ["Split-ticket to Bali", "Break up a 16h flight to Sydney", "Weekend in Lisbon under $600"]

    // MARK: Derived values

    var rangeText: String {
        let sameMonth = gregorian.component(.month, from: start) == gregorian.component(.month, from: end)
        return sameMonth
            ? "\(shortDate(start)) – \(gregorian.component(.day, from: end))"
            : "\(shortDate(start)) – \(shortDate(end))"
    }

    var nights: Int { gregorian.dateComponents([.day], from: start, to: end).day ?? 0 }

    var stopovers: [Stopover] {
        [Stopover(city: destination.stopName, length: "2 nights", extra: 56),
         Stopover(city: "Seoul", length: "1 night", extra: 12),
         Stopover(city: "Vancouver", length: "22h layover", extra: 0)]
    }

    var options: [FlightOption] {
        let d = destination
        let b = fare(on: start, base: d.base) + Int((Double(d.base) * 0.04).rounded())
        let one = Int((Double(b) * 1.31 / 10).rounded()) * 10
        return [
            FlightOption(kind: .pick, price: b, oneTicket: one, departTime: "08:10", arriveTime: "15:40",
                         arrivalLabel: "\(d.code) · +1", middle: "\(d.stopCode) 4h20", maxLeg: 8.8,
                         tags: ["Split · save $\(one - b)", "Legs 5h55 · 8h50"],
                         why: "No leg over 9h, 4h buffer for the self-transfer."),
            FlightOption(kind: .fun, price: b + stopovers[stopIndex].extra, oneTicket: one,
                         departTime: shortDate(start), arriveTime: shortDate(addDays(2, to: start)),
                         arrivalLabel: d.code, middle: "2 nights \(d.stopCode)", maxLeg: 8.8,
                         tags: ["Stopover"], why: "Beach stopover in \(d.stopName) for +$56 vs. my pick."),
            FlightOption(kind: .fastest, price: one, oneTicket: one, departTime: "11:20", arriveTime: "15:25",
                         arrivalLabel: "\(d.code) · +1", middle: "Nonstop · 11h05", maxLeg: 11.1,
                         tags: ["Nonstop"], why: "One ticket, longest single leg.")
        ]
    }

    var filteredOptions: [FlightOption] {
        switch filter {
        case 1: return options.sorted { $0.price < $1.price }
        case 2: return options.sorted { $0.maxLeg < $1.maxLeg }
        case 3: return options.filter { $0.kind == .fun }
        default: return options
        }
    }

    var understood: [String] {
        let dates = flexible
            ? "Flexible · \(start.formatted(.dateTime.month(.wide)))"
            : rangeText + (flexDays > 0 ? " ±\(flexDays)d" : "")
        return ["SFO → \(destination.code)", dates, "≤ $\(budget)", "Max leg 12h", "1 adult"] + constraints
    }

    var stepLabels: [String] {
        ["Scanned 1,284 itineraries · 46 airlines",
         "Found 3 stopovers within 6h of SFO",
         "Tested 212 split-ticket combinations",
         "Checking self-transfer buffers at \(destination.stopCode)",
         "Ranking by price × time × fun"]
    }

    /// Cheapest departure within ±3 days of the current start date.
    var bestShift: (date: Date, save: Int)? {
        let current = fare(on: start, base: destination.base)
        var best: (date: Date, save: Int)?
        for k in -3...3 where k != 0 {
            let d = addDays(k, to: start)
            let f = fare(on: d, base: destination.base)
            if f < current, f < current - (best?.save ?? 0) { best = (d, current - f) }
        }
        return best
    }

    // MARK: Navigation

    func goToChat() {
        if let i = path.firstIndex(of: .chat) {
            path = Array(path.prefix(i + 1))
        } else {
            path = [.chat]
        }
    }

    func showToast(_ text: String) {
        toast = text
        Task {
            try? await Task.sleep(for: .seconds(2.2))
            if toast == text { toast = nil }
        }
    }

    func goHome() {
        path = []
        planned = false
        query = ""
        messages = []
        constraints = []
    }

    // MARK: Home

    func toggleFlexible() {
        flexible.toggle()
        if flexible {
            datesSet = false
            showToast("Atlas will find the best dates")
        }
    }

    func startPlanning() {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let text = q.isEmpty
            ? (flexible ? "Somewhere warm in March, flexible dates, under $900"
                        : "Tokyo in March for ~10 days. Under $900, nothing over 12h in the air.")
            : q
        parse(text)
        plan(text + (datesSet ? " · \(rangeText)" : ""))
    }

    private func parse(_ text: String) {
        let l = text.lowercased()
        if let d = Destination.all.first(where: { l.contains($0.key) }) { destination = d }
        if let r = l.range(of: #"\$ ?(\d{3,5})"#, options: .regularExpression) {
            let digits = l[r].filter(\.isNumber)
            if let v = Int(digits) { budget = v }
        }
        if !datesSet {
            let months = gregorian.monthSymbols.map { $0.lowercased() }
            if let i = months.firstIndex(where: { l.contains($0) }) {
                let month = i + 1
                let year = month < 11 ? 2027 : 2026
                start = makeDay(year, month, 12)
                end = makeDay(year, month, 24)
            }
        }
    }

    // MARK: Atlas chat

    func plan(_ text: String) {
        planned = true
        messages = []
        stepsDone = 0
        quickReplies = ["+ Morning flights only", "+ 1 checked bag", "Pick on calendar"]
        goToChat()
        messages.append(ChatMessage(kind: .user, text: text))
        Task {
            await typing(0.7)
            messages.append(ChatMessage(kind: .agent, text: "On it. Here's what I'm checking:"))
            messages.append(ChatMessage(kind: .steps))
            messages.append(ChatMessage(kind: .understood))
            for i in 1...stepLabels.count {
                try? await Task.sleep(for: .milliseconds(650))
                withAnimation(.easeOut(duration: 0.2)) { stepsDone = i }
            }
            let o = options[0]
            messages.append(ChatMessage(
                kind: .agent,
                text: "**3 strong options.** My pick is **$\(o.price)**: two short legs via \(destination.stopName), saving $\(o.savings) over one ticket.",
                actions: [.seeOptions]))
        }
    }

    private func typing(_ seconds: Double) async {
        isTyping = true
        try? await Task.sleep(for: .seconds(seconds))
        isTyping = false
    }

    func send(_ raw: String) {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        if !planned {
            parse(text)
            plan(text)
            return
        }
        goToChat()
        messages.append(ChatMessage(kind: .user, text: text))
        reply(to: text)
    }

    func tapQuickReply(_ reply: String) {
        quickReplies.removeAll { $0 == reply }
        if reply.lowercased().contains("calendar") {
            openCalendar(.chat)
        } else {
            send(reply.replacingOccurrences(of: "+ ", with: ""))
        }
    }

    private func reply(to text: String) {
        let l = text.lowercased()
        func has(_ words: [String]) -> Bool { words.contains { l.contains($0) } }

        if has(["calendar", "date", "when"]) {
            Task {
                await typing(0.4)
                messages.append(ChatMessage(kind: .agent, text: "Opening the calendar. Your dates will come back here."))
                openCalendar(.chat)
            }
            return
        }
        Task {
            await typing(0.75)
            if has(["cheap", "earl", "save", "less"]) {
                if let s = bestShift {
                    messages.append(ChatMessage(
                        kind: .agent,
                        text: "Leaving **\(weekdayName(s.date)), \(shortDate(s.date))** saves **$\(s.save)**, same route.",
                        actions: [.applyShift(s.date), .keepDates]))
                } else {
                    messages.append(ChatMessage(
                        kind: .agent,
                        text: "Your dates are already the cheapest within 3 days. Want me to try a stopover instead?",
                        actions: [.openFun]))
                }
            } else if has(["morning"]) {
                constraints.append("Mornings")
                messages.append(ChatMessage(kind: .agent, text: "Done: departures before noon only. My pick still works, it leaves at 08:10.", actions: [.seeOptions]))
            } else if has(["bag"]) {
                constraints.append("1 bag")
                messages.append(ChatMessage(kind: .agent, text: "Added 1 checked bag. Prices now include it; my pick is unchanged.", actions: [.seeOptions]))
            } else if has(["stop", "fun", "layover", "beach"]) {
                messages.append(ChatMessage(kind: .agent, text: "A \(destination.stopName) stopover adds 2 nights for +$56 and keeps every leg under 9h.", actions: [.openFun]))
            } else {
                constraints.append(text.count > 18 ? String(text.prefix(18)) + "…" : text)
                messages.append(ChatMessage(kind: .agent, text: "Got it, I'll factor that in. Options are updated.", actions: [.seeOptions]))
            }
        }
    }

    func perform(_ action: ChatAction) {
        switch action {
        case .seeOptions, .keepDates:
            path.append(.results)
        case .openFun:
            path.append(.fun)
        case .applyShift(let date):
            shift(to: date)
            messages.append(ChatMessage(kind: .agent, text: "Moved to **\(rangeText)**. Options updated.", actions: [.seeOptions]))
        }
    }

    func shift(to date: Date) {
        let length = nights
        start = date
        end = addDays(max(length, 1), to: date)
        datesSet = true
    }

    // MARK: Calendar sheet

    func openCalendar(_ source: CalendarSource) {
        calendarSource = source
        pickingEnd = false
        let c = gregorian.dateComponents([.year, .month], from: start)
        displayedMonth = gregorian.date(from: c) ?? start
        showCalendar = true
    }

    func moveMonth(_ delta: Int) {
        displayedMonth = gregorian.date(byAdding: .month, value: delta, to: displayedMonth) ?? displayedMonth
    }

    func tapDay(_ day: Date) {
        if !pickingEnd {
            let length = max(nights, 1)
            start = day
            end = addDays(length, to: day)
            pickingEnd = true
        } else if day <= start {
            start = day
        } else {
            end = day
            pickingEnd = false
        }
    }

    func askAtlasFromSheet() {
        showCalendar = false
        if calendarSource == .results { goToChat() }
        Task {
            try? await Task.sleep(for: .milliseconds(400))
            focusRequest += 1
        }
    }

    func sendDates() {
        datesSet = true
        flexible = false
        showCalendar = false
        let flexNote = flexDays > 0 ? " (±\(flexDays) days)" : ""
        switch calendarSource {
        case .home:
            let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
            if q.isEmpty {
                showToast("Dates set. Now tell Atlas where to.")
            } else {
                Task {
                    try? await Task.sleep(for: .milliseconds(350))
                    parse(q)
                    plan(q + " · \(rangeText)")
                }
            }
        case .results:
            showToast("Updated for \(rangeText)")
        case .chat:
            messages.append(ChatMessage(kind: .user, text: "Let's do \(rangeText)\(flexNote)."))
            Task {
                await typing(0.6)
                messages.append(ChatMessage(
                    kind: .agent,
                    text: "Locked in **\(rangeText)**, \(nights) nights. I re-ranked everything for these dates.",
                    actions: [.seeOptions]))
            }
        }
    }

    // MARK: Results, detail and booking

    func open(_ option: FlightOption) {
        switch option.kind {
        case .pick: path.append(.split)
        case .fun: path.append(.fun)
        case .fastest: choose(.fastest)
        }
    }

    func choose(_ kind: OptionKind) {
        choice = options.first { $0.kind == kind }
        path.append(.review)
    }

    var hotelCost: Int { choice?.kind == .fun && hotelAnswer == true ? 328 : 0 }
    var total: Int { (choice?.price ?? 0) + hotelCost }

    func book() {
        guard let c = choice else { return }
        booked = BookedTrip(kind: c.kind, name: destination.name, code: destination.code,
                            stop: c.kind == .fun ? stopovers[stopIndex].city : destination.stopCode,
                            dates: rangeText)
        path.append(.booked)
    }
}
