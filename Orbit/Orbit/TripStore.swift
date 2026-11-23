import SwiftUI
import Observation

/// App state + the trip agent. The agent here is rule-based with sample inventory so the
/// prototype runs offline; swap `instruct(_:)` and the option builders for real AI + travel APIs.
@MainActor
@Observable
final class TripStore {
    var path: [Route] = []

    var origin: Airport?
    var originMethod: OriginMethod = .detecting
    /// What location services found, so a manual change can be undone.
    var detectedOrigin: Airport?
    var detectedMethod: OriginMethod = .detecting
    var showOriginPicker = false

    var mode: BookingMode = .flights
    var query = ""
    var dest: Airport?
    var stage: Stage = .idle
    var work = 0

    var flightId = "f1"
    var hotelId = "h1"
    var carId = "c1"
    var nights = 6
    var business = false
    var nonstopOnly = false
    var extras: Set<String> = []

    var lastUser = ""
    var agentSays = ""
    var chatText = ""
    var bookingRef = ""

    var customDep: Date?
    var showCalendar = false

    @ObservationIgnored let globe = GlobeModel()
    @ObservationIgnored private let location = LocationService()
    @ObservationIgnored private var tasks: [Task<Void, Never>] = []

    // MARK: Location

    func startLocation() {
        location.onResult = { [weak self] airport, method in
            guard let self else { return }
            self.detectedOrigin = airport
            self.detectedMethod = method
            if self.originMethod == .manual { return }   // user already chose a start
            self.origin = airport
            self.originMethod = method
            self.globe.origin = airport
            self.globe.spinTo(lat: airport.lat, lon: airport.lon, duration: 1.8)
        }
        location.start()
    }

    var originCaption: String {
        switch originMethod {
        case .detecting: return "From"
        case .location: return "Nearest airport"
        case .timezone: return "Nearest airport · est."
        case .manual: return "Starting from"
        }
    }

    var originLabel: String {
        if let o = origin { return "\(o.code) · \(o.city)" }
        return "Locating you…"
    }

    /// Change the starting airport. Re-plans the current trip from the new start.
    func setOrigin(_ airport: Airport, manual: Bool = true) {
        origin = airport
        originMethod = manual ? .manual : detectedMethod
        globe.origin = airport
        if let d = dest {
            if d.code == airport.code { goHome() } else { selectDest(d) }
        } else {
            globe.spinTo(lat: airport.lat, lon: airport.lon, duration: 1.6)
        }
    }

    func resetOrigin() {
        if let a = detectedOrigin { setOrigin(a, manual: false) }
    }

    // MARK: Dates

    var depDate: Date {
        if let d = customDep { return d }
        let cal = Calendar.current
        var d = cal.date(byAdding: .day, value: 21, to: cal.startOfDay(for: Date())) ?? Date()
        while cal.component(.weekday, from: d) != 5 { // Thursday
            d = cal.date(byAdding: .day, value: 1, to: d) ?? d
        }
        return d
    }

    var retDate: Date { Calendar.current.date(byAdding: .day, value: nights, to: depDate) ?? depDate }
    var dateRange: String { Fmt.day(depDate) + " – " + Fmt.day(retDate) }

    func applyDates(start: Date, end: Date) {
        let cal = Calendar.current
        let n = cal.dateComponents([.day], from: cal.startOfDay(for: start), to: cal.startOfDay(for: end)).day ?? 6
        customDep = cal.startOfDay(for: start)
        nights = max(1, n)
        if dest != nil {
            lastUser = ""
            agentSays = "Locked in \(dateRange). I re-priced everything for those dates."
        }
    }

    func clearDates() {
        customDep = nil
        nights = 6
        if dest != nil {
            lastUser = ""
            agentSays = "Back on autopilot — I'll pick the dates that work best."
        }
    }

    // MARK: Inventory (sample data)

    func flights(nonstop: Bool? = nil) -> [FlightOption] {
        guard let o = origin, let d = dest else { return [] }
        let km = Geo.km(o, d)
        let base = km / 830 + 0.55
        let fare = ((95 + km * 0.072) / 5).rounded() * 5
        let dow = Calendar.current.component(.weekday, from: depDate) // 1 = Sunday
        let dayMult: Double = (dow == 6 || dow == 1) ? 1.08 : (dow == 3 || dow == 4) ? 0.94 : 1
        let mult: Double = (business ? 3.1 : 1) * dayMult
        let longHaul = km > 15000

        var hub: Airport?
        var best = Double.greatestFiniteMagnitude
        for code in Airports.hubs where code != o.code && code != d.code {
            guard let h = Airports.find(code) else { continue }
            let x = Geo.km(o, h) + Geo.km(h, d)
            if x < best { best = x; hub = h }
        }

        var list = [
            FlightOption(id: "f1", carrier: "Aurora Air", departMinutes: 640,
                         hours: longHaul ? best / 830 + 2.6 : base, stops: longHaul ? 1 : 0, via: hub,
                         price: fare * mult, badge: "Agent's pick",
                         note: longHaul ? "Shortest connection" : "Best balance of time and price"),
            FlightOption(id: "f2", carrier: "Meridian Airways", departMinutes: 375,
                         hours: best / 830 + 3.1, stops: 1, via: hub,
                         price: fare * mult * 0.78, badge: "Cheapest", note: "Longer layover, lowest fare"),
            FlightOption(id: "f3", carrier: "Northstar", departMinutes: 1375,
                         hours: longHaul ? best / 830 + 2.2 : base - 0.15, stops: longHaul ? 1 : 0, via: hub,
                         price: fare * mult * 1.14, badge: "Fastest", note: "Overnight — arrive rested-ish")
        ]
        if nonstop ?? nonstopOnly { list = list.filter { $0.stops == 0 } }
        return list
    }

    func arrivalClock(_ f: FlightOption) -> String {
        let shift = ((dest?.lon ?? 0) - (origin?.lon ?? 0)) / 15 * 60
        return Fmt.clock(f.departMinutes + f.hours * 60 + shift)
    }

    var hotels: [HotelOption] {
        guard let d = dest else { return [] }
        let base = Double(120 + Fmt.hash(d.city) % 110)
        return [
            HotelOption(id: "h1", name: "Hotel Lumen", tier: "Boutique", rating: "4.6", nightly: base,
                        perk: "Walkable · breakfast included", badge: "Agent's pick",
                        colors: [Color(hex: 0x2C4A7A), Color(hex: 0xC98A3D)]),
            HotelOption(id: "h2", name: "Nomad House", tier: "Budget", rating: "4.3", nightly: (base * 0.55).rounded(),
                        perk: "Social lounge · free cancellation", badge: "Best value",
                        colors: [Color(hex: 0x1F5A55), Color(hex: 0x7AB8A4)]),
            HotelOption(id: "h3", name: "The Observatory", tier: "Luxury", rating: "4.8", nightly: (base * 1.95).rounded(),
                        perk: "Rooftop pool · late checkout", badge: "",
                        colors: [Color(hex: 0x3B2A5E), Color(hex: 0xD7A86E)])
        ]
    }

    var cars: [CarOption] {
        guard let d = dest else { return [] }
        let base = Double(36 + Fmt.hash(d.code) % 28)
        return [
            CarOption(id: "c1", name: "Compact", model: "Toyota Corolla or similar", spec: "5 seats · automatic · 2 bags",
                      daily: base, badge: "Agent's pick", tint: Theme.sky),
            CarOption(id: "c2", name: "SUV", model: "Toyota RAV4 or similar", spec: "5 seats · AWD · 4 bags",
                      daily: (base * 1.6).rounded(), badge: "", tint: Theme.text),
            CarOption(id: "c3", name: "Electric", model: "Tesla Model 3 or similar", spec: "5 seats · 300 mi range · free charging",
                      daily: (base * 1.35).rounded(), badge: "", tint: Theme.sage)
        ]
    }

    var extrasList: [ExtraOption] {
        let code = dest?.code ?? "arrivals"
        let area = dest?.area ?? "town"
        let n = Double(nights)
        switch mode {
        case .cars:
            return [
                ExtraOption(key: "cover", name: "Full coverage", why: "Zero deductible for damage or theft", price: 15 * n),
                ExtraOption(key: "driver", name: "Additional driver", why: "Share the driving", price: 12 * n),
                ExtraOption(key: "seat", name: "Child seat", why: "Installed before pick-up", price: 35),
                ExtraOption(key: "toll", name: "Toll pass", why: "Skip the cash lanes", price: 24)
            ]
        case .stays:
            return [
                ExtraOption(key: "late", name: "Late checkout", why: "Keep the room until 2 PM", price: 40),
                ExtraOption(key: "transfer", name: "Airport transfer", why: "Driver waiting at \(code)", price: 48),
                ExtraOption(key: "breakfast", name: "Breakfast daily", why: "At the hotel, every morning", price: 18 * n),
                ExtraOption(key: "tour", name: "Local food walk", why: "Evening tour in \(area)", price: 65)
            ]
        case .flights, .packages:
            return [
                ExtraOption(key: "esim", name: "eSIM · 10 GB", why: "Data from the moment you land", price: 19),
                ExtraOption(key: "transfer", name: "Airport transfer", why: "Driver waiting at \(code)", price: 48),
                ExtraOption(key: "insurance", name: "Trip protection", why: "Cancel for covered reasons, lost bags", price: 42),
                ExtraOption(key: "tour", name: "Local food walk", why: "Evening tour in \(area)", price: 65)
            ]
        }
    }

    private func defaultExtras(for mode: BookingMode) -> Set<String> {
        switch mode {
        case .flights: return ["esim"]
        case .packages: return ["esim", "transfer"]
        case .stays: return ["transfer", "breakfast"]
        case .cars: return ["cover"]
        }
    }

    var totals: Totals {
        var t = Totals()
        let n = Double(nights)
        if mode.hasRoute {
            let list = flights()
            t.flight = list.first { $0.id == flightId } ?? list.first
        }
        if mode == .stays || mode == .packages { t.hotel = hotels.first { $0.id == hotelId } }
        if mode == .cars { t.car = cars.first { $0.id == carId } }
        t.extras = extrasList.filter { extras.contains($0.key) }
        let core = (t.flight?.price ?? 0) + (t.hotel.map { $0.nightly * n } ?? 0) + (t.car.map { $0.daily * n } ?? 0)
        t.save = mode == .packages ? (core * 0.08).rounded() : 0
        t.total = core - t.save + t.extras.reduce(0) { $0 + $1.price }
        return t
    }

    var reviewLines: [ReviewLine] {
        let t = totals
        var lines: [ReviewLine] = []
        if let f = t.flight {
            lines.append(ReviewLine(kind: "Flight · \(dateRange)", text: "\(f.carrier) · \(f.stopsLabel) · round trip", price: Fmt.money(f.price)))
        }
        if let h = t.hotel {
            lines.append(ReviewLine(kind: "Stay · \(nights) nights", text: "\(h.name), \(dest?.area ?? "")", price: Fmt.money(h.nightly * Double(nights))))
        }
        if let c = t.car {
            lines.append(ReviewLine(kind: "Car · \(nights) days", text: "\(c.name) · \(c.model) · Atlas Rent", price: Fmt.money(c.daily * Double(nights))))
        }
        for x in t.extras { lines.append(ReviewLine(kind: "Extra", text: x.name, price: Fmt.money(x.price))) }
        if t.save > 0 { lines.append(ReviewLine(kind: "Package", text: "Flight + hotel bundle", price: "−" + Fmt.money(t.save))) }
        return lines
    }

    // MARK: Flow

    var order: [Stage] { mode.steps }
    var isReady: Bool { order.contains(stage) }
    var isWorking: Bool { stage == .planning || stage == .booking }

    var routeTitle: String {
        guard let o = origin, let d = dest else { return "" }
        switch mode {
        case .stays: return "Stay in \(d.city)"
        case .cars: return "Car in \(d.city)"
        default: return "\(o.code) → \(d.code) · \(d.city)"
        }
    }

    var tripMeta: String {
        switch mode {
        case .stays: return "\(dateRange) · \(nights) nights · 1 guest"
        case .cars: return "\(dateRange) · \(nights) days · pick up \(dest?.code ?? "")"
        default: return "\(dateRange) · 1 traveler · \(business ? "Business" : "Economy")"
        }
    }

    var planLabels: [String] {
        guard let o = origin, let d = dest else { return [] }
        switch mode {
        case .stays:
            return ["Reading the neighborhoods of \(d.city)", "Choosing dates · \(dateRange)", "Comparing stays near \(d.area)",
                    "Checking cancellation terms", "Picking extras you'll likely want"]
        case .cars:
            return ["Finding rental counters at \(d.code)", "Choosing dates · \(dateRange)", "Comparing compact, SUV and electric",
                    "Checking coverage and fees", "Picking extras you'll likely need"]
        case .flights, .packages:
            return ["Starting from \(o.code), your nearest airport",
                    "Searching routes \(o.code) → \(d.code) · \(Geo.miles(Geo.km(o, d)))",
                    "Choosing dates · \(dateRange)",
                    mode == .packages ? "Bundling a stay near \(d.area)" : "Comparing fares across the week",
                    "Picking extras you'll likely need"]
        }
    }

    var bookLabels: [String] {
        let t = totals
        let first = t.flight.map { "Holding seats on \($0.carrier)" }
            ?? t.car.map { "Reserving your \($0.name.lowercased()) with Atlas Rent" } ?? "Holding your room"
        let second = t.hotel.map { "Confirming \($0.name)" } ?? (t.car != nil ? "Adding coverage and extras" : "Confirming your fare")
        return [first, second, "Sending your itinerary to Wallet"]
    }

    func suggestions() -> [Airport] { Airports.search(query, excluding: origin?.code) }

    func selectFirst() {
        if let a = suggestions().first { selectDest(a) }
    }

    func selectDest(_ ap: Airport) {
        guard let o = origin else { return }
        if ap.code == o.code { query = ""; return }
        cancelTasks()

        globe.dest = ap
        globe.showArc = mode.hasRoute
        let frame = globe.frameRoute(from: o, to: ap, withRoute: mode.hasRoute)
        globe.spinTo(lat: frame.lat, lon: frame.lon, duration: 2.2, zoom: frame.zoom)
        globe.arcStart = GlobeModel.now() + 1700

        query = ""
        work = 0
        flightId = "f1"; hotelId = "h1"; carId = "c1"
        if customDep == nil { nights = 6 }
        business = false
        nonstopOnly = false
        extras = defaultExtras(for: mode)
        lastUser = mode.ask(ap.city)
        agentSays = "On it — you don't need to fill in a thing."
        chatText = ""
        withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) {
            dest = ap
            stage = .planning
        }
        for k in 1...5 { schedule(700 * k) { self.work = k } }
        schedule(700 * 5 + 400) { self.goStage(self.order[0]) }
    }

    func goHome() {
        cancelTasks()
        globe.dest = nil
        globe.showArc = false
        if let o = origin { globe.spinTo(lat: o.lat, lon: o.lon, duration: 1.6, zoom: 1) }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) {
            dest = nil
            stage = .idle
        }
        work = 0; lastUser = ""; agentSays = ""
    }

    private var flightPitch: String {
        guard let f = flights().first, let d = dest else { return "" }
        let route = f.stops > 0 ? "1 stop via \(f.via?.code ?? "")" : "nonstop"
        let dates = customDep != nil ? "Using your dates" : "I picked dates three weeks out — tap them to choose your own"
        return "Here's what I'd book: \(f.carrier), \(route) to \(d.city). \(dates). Swap anything, or tell me what to change."
    }

    func goStage(_ s: Stage) {
        guard let d = dest else { return }
        let says: String
        switch s {
        case .flights: says = flightPitch
        case .stay: says = "I shortlisted three stays near \(d.area). Hotel Lumen fits most travelers — swap anytime."
        case .cars: says = "A compact from Atlas Rent, ready at the \(d.code) counter when you land — \(nights) days. Want something bigger or electric?"
        case .extras: says = "These are the add-ons I'd suggest. I turned on the ones people usually end up buying anyway."
        case .review: says = "Everything's lined up. Review it once, then I'll handle payment and the details."
        default: says = agentSays
        }
        withAnimation(.easeInOut(duration: 0.25)) {
            stage = s
            agentSays = says
        }
    }

    func next() {
        if stage == .review { book(); return }
        if let i = order.firstIndex(of: stage), i + 1 < order.count { goStage(order[i + 1]) }
    }

    func book() {
        cancelTasks()
        withAnimation { stage = .booking }
        work = 0
        lastUser = "Book it"
        agentSays = "Booking now. I'll keep everything together in one confirmation."
        for k in 1...3 { schedule(650 * k) { self.work = k } }
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        let ref = String((0..<6).map { _ in chars.randomElement()! })
        schedule(650 * 3 + 500) {
            withAnimation {
                self.stage = .booked
                self.bookingRef = ref
                self.agentSays = ""
                self.lastUser = ""
            }
        }
    }

    var bookedTitle: String {
        guard let d = dest else { return "" }
        switch mode {
        case .stays: return "Your stay in \(d.city) is set"
        case .cars: return "Your car in \(d.city) is ready"
        default: return "You're going to \(d.city)"
        }
    }

    var bookedNote: String {
        switch mode {
        case .cars: return "Show your phone at the Atlas Rent counter — I'll send the pick-up code an hour before you arrive."
        case .stays: return "I'll share check-in details the day before and handle any changes."
        default: return "I'll watch the flight, check you in 24 hours before departure and ping you if anything changes."
        }
    }

    // MARK: Agent instructions (rule-based for the prototype)

    func instruct(_ text: String) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        let lo = t.lowercased()
        chatText = ""
        func has(_ words: String...) -> Bool { words.contains { lo.contains($0) } }

        if has("date", "calendar", "when") { showCalendar = true; return }
        if has("book", "confirm", "go ahead", "looks good") { lastUser = t; goStage(.review); return }

        var msg: String
        var target: Stage?
        if has("suv", "bigger", "larger") {
            carId = "c2"; target = .cars; msg = "Switched to an SUV — room for four bags."
        } else if has("electric", " ev", "tesla") {
            carId = "c3"; target = .cars; msg = "Going electric. Charging is included with this one."
        } else if has("cheap", "budget", "less", "save") {
            business = false; flightId = "f2"; hotelId = "h2"; carId = "c1"; nonstopOnly = false
            switch mode {
            case .cars: msg = "You're on the compact — the lowest daily rate."
            case .stays: msg = "Switched to Nomad House, the best-value stay."
            default: msg = "Done — switched to the lowest options. That trims it noticeably."
            }
        } else if has("nonstop", "non-stop", "direct") {
            target = .flights
            let ns = flights(nonstop: true)
            if let first = ns.first { nonstopOnly = true; flightId = first.id; msg = "Showing nonstop flights only." }
            else { msg = "There's no nonstop on this route, so I kept the shortest one-stop options." }
        } else if has("business", "first class", "premium", "upgrade") {
            business = true; target = .flights; msg = "Upgraded to business class. Lie-flat on the long legs."
        } else if has("economy", "coach") {
            business = false; msg = "Back to economy."
        } else if has("lux", "fancy", "nicer", "splurge", "5 star") {
            hotelId = "h3"; target = .stay; msg = "Moved you to The Observatory — rooftop pool, late checkout."
        } else if has("add a night", "longer", "extra night", "one more") {
            nights = min(30, nights + 1); target = .stay; msg = "Added a night — \(nights) now."
        } else if has("shorter", "fewer", "one less") {
            nights = max(1, nights - 1); target = .stay; msg = "Trimmed to \(nights)."
        } else {
            msg = "Noted: “\(t)”. I'll factor that into the plan."
        }

        if let s = target {
            if order.contains(s) {
                stage = s
            } else if s == .flights || s == .stay {
                msg = "That's part of a different booking type — switch to Packages to bundle flights and a stay."
            }
        }
        withAnimation(.easeInOut(duration: 0.2)) {
            lastUser = t
            agentSays = msg
        }
    }

    // MARK: Timers

    private func schedule(_ ms: Int, _ action: @escaping @MainActor () -> Void) {
        let task = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(ms) * 1_000_000)
            guard !Task.isCancelled else { return }
            action()
        }
        tasks.append(task)
    }

    private func cancelTasks() {
        tasks.forEach { $0.cancel() }
        tasks.removeAll()
    }
}
