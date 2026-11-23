import Foundation

struct Airport: Identifiable, Hashable {
    let code: String
    let city: String
    let country: String
    let lat: Double
    let lon: Double
    /// Neighborhood the agent suggests staying in.
    let area: String
    var id: String { code }

    init(_ code: String, _ city: String, _ country: String, _ lat: Double, _ lon: Double, _ area: String) {
        self.code = code; self.city = city; self.country = country
        self.lat = lat; self.lon = lon; self.area = area
    }
}

enum Airports {
    // Prototype set of major airports. Swap for a full airport database later.
    static let all: [Airport] = [
        Airport("LAX", "Los Angeles", "United States", 33.94, -118.41, "Santa Monica"),
        Airport("SFO", "San Francisco", "United States", 37.62, -122.38, "Union Square"),
        Airport("SEA", "Seattle", "United States", 47.45, -122.31, "Capitol Hill"),
        Airport("PDX", "Portland", "United States", 45.59, -122.60, "Pearl District"),
        Airport("SAN", "San Diego", "United States", 32.73, -117.19, "Gaslamp Quarter"),
        Airport("LAS", "Las Vegas", "United States", 36.08, -115.15, "The Strip"),
        Airport("PHX", "Phoenix", "United States", 33.43, -112.01, "Old Town Scottsdale"),
        Airport("DEN", "Denver", "United States", 39.86, -104.67, "LoDo"),
        Airport("DFW", "Dallas", "United States", 32.90, -97.04, "Uptown"),
        Airport("IAH", "Houston", "United States", 29.98, -95.34, "Montrose"),
        Airport("ORD", "Chicago", "United States", 41.98, -87.90, "River North"),
        Airport("ATL", "Atlanta", "United States", 33.64, -84.43, "Midtown"),
        Airport("MIA", "Miami", "United States", 25.79, -80.29, "South Beach"),
        Airport("JFK", "New York", "United States", 40.64, -73.78, "SoHo"),
        Airport("BOS", "Boston", "United States", 42.36, -71.01, "Back Bay"),
        Airport("IAD", "Washington, D.C.", "United States", 38.95, -77.46, "Georgetown"),
        Airport("YYZ", "Toronto", "Canada", 43.68, -79.63, "Queen West"),
        Airport("YVR", "Vancouver", "Canada", 49.19, -123.18, "Gastown"),
        Airport("MEX", "Mexico City", "Mexico", 19.44, -99.07, "Roma Norte"),
        Airport("CUN", "Cancún", "Mexico", 21.04, -86.87, "Hotel Zone"),
        Airport("HNL", "Honolulu", "United States", 21.32, -157.92, "Waikiki"),
        Airport("ANC", "Anchorage", "United States", 61.17, -149.99, "Downtown"),
        Airport("GRU", "São Paulo", "Brazil", -23.43, -46.47, "Jardins"),
        Airport("EZE", "Buenos Aires", "Argentina", -34.82, -58.54, "Palermo"),
        Airport("LIM", "Lima", "Peru", -12.02, -77.11, "Miraflores"),
        Airport("BOG", "Bogotá", "Colombia", 4.70, -74.15, "Chapinero"),
        Airport("SCL", "Santiago", "Chile", -33.39, -70.79, "Lastarria"),
        Airport("LHR", "London", "United Kingdom", 51.47, -0.45, "Shoreditch"),
        Airport("CDG", "Paris", "France", 49.01, 2.55, "Le Marais"),
        Airport("AMS", "Amsterdam", "Netherlands", 52.31, 4.76, "Jordaan"),
        Airport("FRA", "Frankfurt", "Germany", 50.04, 8.56, "Sachsenhausen"),
        Airport("MAD", "Madrid", "Spain", 40.49, -3.57, "Malasaña"),
        Airport("BCN", "Barcelona", "Spain", 41.30, 2.08, "El Born"),
        Airport("FCO", "Rome", "Italy", 41.80, 12.25, "Trastevere"),
        Airport("LIS", "Lisbon", "Portugal", 38.77, -9.13, "Chiado"),
        Airport("DUB", "Dublin", "Ireland", 53.43, -6.27, "Temple Bar"),
        Airport("ZRH", "Zurich", "Switzerland", 47.46, 8.55, "Altstadt"),
        Airport("CPH", "Copenhagen", "Denmark", 55.62, 12.65, "Nørrebro"),
        Airport("ATH", "Athens", "Greece", 37.94, 23.94, "Plaka"),
        Airport("IST", "Istanbul", "Türkiye", 41.26, 28.74, "Beyoğlu"),
        Airport("KEF", "Reykjavík", "Iceland", 63.98, -22.61, "Old Harbour"),
        Airport("DXB", "Dubai", "United Arab Emirates", 25.25, 55.36, "Dubai Marina"),
        Airport("DOH", "Doha", "Qatar", 25.27, 51.61, "West Bay"),
        Airport("CAI", "Cairo", "Egypt", 30.12, 31.41, "Zamalek"),
        Airport("CPT", "Cape Town", "South Africa", -33.97, 18.60, "V&A Waterfront"),
        Airport("JNB", "Johannesburg", "South Africa", -26.14, 28.25, "Rosebank"),
        Airport("NBO", "Nairobi", "Kenya", -1.32, 36.93, "Westlands"),
        Airport("RAK", "Marrakesh", "Morocco", 31.61, -8.04, "the Medina"),
        Airport("DEL", "Delhi", "India", 28.56, 77.10, "Hauz Khas"),
        Airport("BOM", "Mumbai", "India", 19.09, 72.87, "Bandra"),
        Airport("BKK", "Bangkok", "Thailand", 13.69, 100.75, "Sukhumvit"),
        Airport("SIN", "Singapore", "Singapore", 1.36, 103.99, "Tiong Bahru"),
        Airport("KUL", "Kuala Lumpur", "Malaysia", 2.75, 101.71, "Bukit Bintang"),
        Airport("DPS", "Bali", "Indonesia", -8.75, 115.17, "Ubud"),
        Airport("HKG", "Hong Kong", "Hong Kong", 22.31, 113.91, "Central"),
        Airport("ICN", "Seoul", "South Korea", 37.46, 126.44, "Myeongdong"),
        Airport("HND", "Tokyo", "Japan", 35.55, 139.78, "Shibuya"),
        Airport("KIX", "Osaka", "Japan", 34.43, 135.24, "Namba"),
        Airport("PEK", "Beijing", "China", 40.08, 116.58, "Sanlitun"),
        Airport("PVG", "Shanghai", "China", 31.14, 121.81, "the Bund"),
        Airport("TPE", "Taipei", "Taiwan", 25.08, 121.23, "Da'an"),
        Airport("MNL", "Manila", "Philippines", 14.51, 121.02, "Makati"),
        Airport("SYD", "Sydney", "Australia", -33.94, 151.18, "Surry Hills"),
        Airport("MEL", "Melbourne", "Australia", -37.67, 144.84, "Fitzroy"),
        Airport("AKL", "Auckland", "New Zealand", -37.01, 174.79, "Ponsonby"),
        Airport("NAN", "Nadi", "Fiji", -17.76, 177.44, "Denarau"),
        Airport("PPT", "Papeete", "French Polynesia", -17.55, -149.61, "the waterfront"),
        Airport("MLE", "Malé", "Maldives", 4.19, 73.53, "North Malé Atoll"),
    ]

    static let byTimeZone: [String: String] = [
        "America/Los_Angeles": "LAX",
        "America/Vancouver": "YVR",
        "America/Denver": "DEN",
        "America/Phoenix": "PHX",
        "America/Chicago": "ORD",
        "America/New_York": "JFK",
        "America/Toronto": "YYZ",
        "America/Mexico_City": "MEX",
        "America/Sao_Paulo": "GRU",
        "America/Argentina/Buenos_Aires": "EZE",
        "Pacific/Honolulu": "HNL",
        "America/Anchorage": "ANC",
        "Europe/London": "LHR",
        "Europe/Paris": "CDG",
        "Europe/Berlin": "FRA",
        "Europe/Madrid": "MAD",
        "Europe/Rome": "FCO",
        "Europe/Lisbon": "LIS",
        "Europe/Amsterdam": "AMS",
        "Europe/Dublin": "DUB",
        "Europe/Istanbul": "IST",
        "Asia/Dubai": "DXB",
        "Asia/Kolkata": "DEL",
        "Asia/Singapore": "SIN",
        "Asia/Bangkok": "BKK",
        "Asia/Hong_Kong": "HKG",
        "Asia/Tokyo": "HND",
        "Asia/Seoul": "ICN",
        "Asia/Shanghai": "PVG",
        "Australia/Sydney": "SYD",
        "Australia/Melbourne": "MEL",
        "Pacific/Auckland": "AKL",
        "Africa/Johannesburg": "JNB",
        "Africa/Cairo": "CAI",
        "Africa/Nairobi": "NBO"
    ]

    static let hubs = ["DXB", "DOH", "IST", "FRA", "AMS", "LHR", "ICN", "HND", "SIN", "HKG", "ORD", "DFW", "ATL", "JFK", "LAX", "SYD", "GRU", "MAD"]
    static let popular = ["HND", "LIS", "CPT", "DPS", "CDG", "MEX", "RAK", "KEF"]

    static func find(_ code: String) -> Airport? { all.first { $0.code == code } }

    static func nearest(lat: Double, lon: Double) -> Airport {
        var best = all[0]
        var bestKm = Double.greatestFiniteMagnitude
        for a in all {
            let d = Geo.km(lat, lon, a.lat, a.lon)
            if d < bestKm { bestKm = d; best = a }
        }
        return best
    }

    /// Used when location is not allowed: estimate from the device time zone.
    static func fromTimeZone() -> Airport {
        let tz = TimeZone.current
        if let code = byTimeZone[tz.identifier], let a = find(code) { return a }
        let lon = Double(tz.secondsFromGMT()) / 3600 * 15
        return nearest(lat: 38, lon: lon)
    }

    static func search(_ query: String, excluding: String?) -> [Airport] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        var list: [Airport]
        if q.isEmpty {
            list = popular.compactMap(find)
        } else {
            func rank(_ a: Airport) -> Int {
                if a.code.lowercased() == q { return 0 }
                if a.city.lowercased().hasPrefix(q) { return 1 }
                return 2
            }
            list = all.filter {
                $0.code.lowercased().hasPrefix(q) || $0.city.lowercased().contains(q) || $0.country.lowercased().hasPrefix(q)
            }
            list.sort { rank($0) < rank($1) }
            list = Array(list.prefix(6))
        }
        return list.filter { $0.code != excluding }
    }
}
