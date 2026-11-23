import SwiftUI

// MARK: - Geometry & formatting helpers

enum Geo {
    static func rad(_ d: Double) -> Double { d * .pi / 180 }

    static func km(_ a: Airport, _ b: Airport) -> Double { km(a.lat, a.lon, b.lat, b.lon) }

    static func km(_ lat1: Double, _ lon1: Double, _ lat2: Double, _ lon2: Double) -> Double {
        let dLat = rad(lat2 - lat1)
        let dLon = rad(lon2 - lon1)
        let h = sin(dLat / 2) * sin(dLat / 2) + cos(rad(lat1)) * cos(rad(lat2)) * sin(dLon / 2) * sin(dLon / 2)
        return 6371 * 2 * atan2(sqrt(h), sqrt(1 - h))
    }

    /// Unit vector on the sphere (x east, y north, z toward lon 0).
    static func vec(_ lat: Double, _ lon: Double) -> SIMD3<Double> {
        let p = rad(lat), l = rad(lon)
        return SIMD3(cos(p) * sin(l), sin(p), cos(p) * cos(l))
    }

    static func miles(_ km: Double) -> String { Fmt.int(km * 0.621371) + " mi" }
}

enum Fmt {
    private static let decimal: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()

    static func int(_ v: Double) -> String { decimal.string(from: NSNumber(value: v.rounded())) ?? "\(Int(v))" }
    static func money(_ v: Double) -> String { "$" + int(v) }

    static func hm(_ hours: Double) -> String {
        var hh = Int(hours)
        var mm = Int(((hours - Double(hh)) * 60 / 5).rounded()) * 5
        if mm == 60 { hh += 1; mm = 0 }
        return String(format: "%dh %02dm", hh, mm)
    }

    static func clock(_ minutes: Double) -> String {
        var m = Int(minutes.rounded()) % 1440
        if m < 0 { m += 1440 }
        return String(format: "%02d:%02d", m / 60, m % 60)
    }

    static func day(_ d: Date) -> String {
        d.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    static func hash(_ s: String) -> Int {
        var h: UInt32 = 7
        for c in s.unicodeScalars { h = h &* 31 &+ c.value }
        return Int(h)
    }
}

// MARK: - Booking model

enum BookingMode: String, CaseIterable, Identifiable {
    case flights, stays, cars, packages
    var id: String { rawValue }

    var title: String {
        switch self {
        case .flights: return "Flights"
        case .stays: return "Stays"
        case .cars: return "Cars"
        case .packages: return "Packages"
        }
    }

    var placeholder: String {
        switch self {
        case .flights: return "Fly to — Tokyo, Lisbon, CPT"
        case .stays: return "Stay in — city or neighborhood"
        case .cars: return "Pick up in — city or airport"
        case .packages: return "Flight + hotel — where to?"
        }
    }

    var steps: [Stage] {
        switch self {
        case .flights: return [.flights, .extras, .review]
        case .stays: return [.stay, .extras, .review]
        case .cars: return [.cars, .extras, .review]
        case .packages: return [.flights, .stay, .extras, .review]
        }
    }

    var hasRoute: Bool { self == .flights || self == .packages }

    func ask(_ city: String) -> String {
        switch self {
        case .flights: return "Fly me to \(city)"
        case .stays: return "Find me a place in \(city)"
        case .cars: return "I need a car in \(city)"
        case .packages: return "Plan a trip to \(city)"
        }
    }

    var chips: [String] {
        switch self {
        case .flights: return ["Pick my own dates", "Make it cheaper", "Nonstop only", "Upgrade to business"]
        case .stays: return ["Pick my own dates", "Make it cheaper", "Somewhere nicer", "Add a night"]
        case .cars: return ["Pick my own dates", "Make it cheaper", "Bigger — SUV", "Electric"]
        case .packages: return ["Pick my own dates", "Make it cheaper", "Nonstop only", "Somewhere nicer", "Add a night"]
        }
    }
}

enum Stage: String {
    case idle, planning, flights, stay, cars, extras, review, booking, booked

    var label: String {
        switch self {
        case .flights: return "Flights"
        case .stay: return "Stay"
        case .cars: return "Car"
        case .extras: return "Extras"
        case .review: return "Review"
        default: return ""
        }
    }
}

enum OriginMethod { case detecting, location, timezone, manual }

enum Route: Hashable { case trips, agent }

struct FlightOption: Identifiable {
    let id: String
    let carrier: String
    let departMinutes: Double
    let hours: Double
    let stops: Int
    let via: Airport?
    let price: Double
    let badge: String
    let note: String

    var stopsLabel: String { stops > 0 ? "1 stop · \(via?.code ?? "")" : "Nonstop" }
}

struct HotelOption: Identifiable {
    let id: String
    let name: String
    let tier: String
    let rating: String
    let nightly: Double
    let perk: String
    let badge: String
    let colors: [Color]
}

struct CarOption: Identifiable {
    let id: String
    let name: String
    let model: String
    let spec: String
    let daily: Double
    let badge: String
    let tint: Color
}

struct ExtraOption: Identifiable {
    let key: String
    let name: String
    let why: String
    let price: Double
    var id: String { key }
}

struct Totals {
    var flight: FlightOption?
    var hotel: HotelOption?
    var car: CarOption?
    var extras: [ExtraOption] = []
    var save: Double = 0
    var total: Double = 0
}

struct ReviewLine: Identifiable {
    let id = UUID()
    let kind: String
    let text: String
    let price: String
}
