import SwiftUI

struct TripsView: View {
    @State private var tab = 0
    @AppStorage("appearance") private var appearance: Appearance = .system

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Picker("Trips", selection: $tab) {
                    Text("Upcoming").tag(0)
                    Text("Past").tag(1)
                }
                .pickerStyle(.segmented)

                if tab == 0 {
                    LiveFlightCard()
                    AgentUpdates()
                    StayCard()
                    NavigationLink(value: Route.agent) {
                        HStack(spacing: 14) {
                            Text("LIS")
                                .font(.display(13)).foregroundStyle(Theme.accentInk)
                                .frame(width: 44, height: 44)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.chip))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Lisbon · Mar 12 – 18").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.text)
                                Text("Agent is watching fares — tap to chat").font(.system(size: 13)).foregroundStyle(Theme.muted)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(Theme.muted)
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 20).fill(Theme.surface))
                        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.handle, style: StrokeStyle(lineWidth: 1, dash: [4, 4])))
                    }
                    .buttonStyle(.plain)
                } else {
                    PastTrips()
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Trips")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Theme.bg, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Appearance", selection: $appearance) {
                        ForEach(Appearance.allCases) { a in
                            Label(a.title, systemImage: a.icon).tag(a)
                        }
                    }
                } label: {
                    Image(systemName: appearance.icon)
                        .foregroundStyle(Theme.text)
                }
                .accessibilityLabel("Appearance: \(appearance.title)")
            }
        }
    }
}

/// Live in-flight card: the plane moves along the route in real time (sample flight).
struct LiveFlightCard: View {
    @State private var startedAt = Date()
    private let totalMinutes = 11.0 * 60 + 5

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.1)) { timeline in
            let elapsed = timeline.date.timeIntervalSince(startedAt)
            let p = 0.2 + (0.38 + elapsed * 0.004).truncatingRemainder(dividingBy: 0.78)
            card(progress: p)
        }
    }

    private func card(progress p: Double) -> some View {
        let left = (1 - p) * totalMinutes
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Circle().fill(Theme.sage).frame(width: 8, height: 8)
                        Text("LIVE · IN FLIGHT").font(.system(size: 12, weight: .semibold)).tracking(0.8)
                    }
                    .foregroundStyle(Theme.sage)
                    Text("Los Angeles → Tokyo").font(.display(19)).foregroundStyle(Theme.text)
                }
                Spacer()
                Text("Aurora Air\nAU 102").font(.system(size: 13)).foregroundStyle(Theme.muted).multilineTextAlignment(.trailing)
            }
            .padding(.horizontal, 16).padding(.top, 14)

            RouteMap(progress: p).frame(height: 170)

            VStack(spacing: 10) {
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.borderSoft)
                        Capsule().fill(Theme.accent).frame(width: g.size.width * p)
                    }
                }
                .frame(height: 6)
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("10:40").font(.display(18)).foregroundStyle(Theme.text)
                        Text("LAX · Departed").font(.system(size: 12)).foregroundStyle(Theme.muted)
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Text(Fmt.hm(left / 60)).font(.display(16)).foregroundStyle(Theme.accentInk)
                        Text("left · on time").font(.system(size: 12)).foregroundStyle(Theme.muted)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("15:20").font(.display(18)).foregroundStyle(Theme.text)
                        Text("HND · Gate 112").font(.system(size: 12)).foregroundStyle(Theme.muted)
                    }
                }
            }
            .padding(.horizontal, 16).padding(.bottom, 16).padding(.top, 4)
        }
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Theme.border, lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Live flight Los Angeles to Tokyo, \(Int(p * 100)) percent complete, \(Fmt.hm(left / 60)) left, on time")
    }
}

struct RouteMap: View {
    let progress: Double

    var body: some View {
        Canvas { c, size in
            let w = Double(size.width), h = Double(size.height)
            // dotted field
            var dots = Path()
            var y = 1.5
            while y < h { var x = 1.5; while x < w { dots.addEllipse(in: CGRect(x: x - 1, y: y - 1, width: 2, height: 2)); x += 9 }; y += 9 }
            c.fill(dots, with: .color(Color(hex: 0x5A7BA8).opacity(0.16)))

            let a = CGPoint(x: w * 0.11, y: h * 0.75)
            let b = CGPoint(x: w * 0.89, y: h * 0.56)
            let ctrl = CGPoint(x: w * 0.5, y: h * 0.04)
            var route = Path()
            route.move(to: a)
            route.addQuadCurve(to: b, control: ctrl)
            c.stroke(route, with: .color(Theme.route.opacity(0.35)), style: StrokeStyle(lineWidth: 1.6, dash: [5, 6]))
            c.stroke(route.trimmedPath(from: 0, to: progress), with: .color(Theme.route), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))

            c.fill(Path(ellipseIn: CGRect(x: a.x - 9, y: a.y - 9, width: 18, height: 18)), with: .color(Theme.sage.opacity(0.2)))
            c.fill(Path(ellipseIn: CGRect(x: a.x - 4.5, y: a.y - 4.5, width: 9, height: 9)), with: .color(Theme.sage))
            c.fill(Path(ellipseIn: CGRect(x: b.x - 5, y: b.y - 5, width: 10, height: 10)), with: .color(Theme.accent))
            c.draw(Text("LAX").font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.muted), at: CGPoint(x: a.x, y: a.y + 18))
            c.draw(Text("HND").font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.muted), at: CGPoint(x: b.x, y: b.y + 18))

            // plane on the quadratic curve
            let t = progress, u = 1 - t
            let px = u * u * Double(a.x) + 2 * u * t * Double(ctrl.x) + t * t * Double(b.x)
            let py = u * u * Double(a.y) + 2 * u * t * Double(ctrl.y) + t * t * Double(b.y)
            let dx = 2 * u * Double(ctrl.x - a.x) + 2 * t * Double(b.x - ctrl.x)
            let dy = 2 * u * Double(ctrl.y - a.y) + 2 * t * Double(b.y - ctrl.y)
            c.fill(Path(ellipseIn: CGRect(x: px - 14, y: py - 14, width: 28, height: 28)),
                   with: .radialGradient(Gradient(colors: [Theme.route.opacity(0.25), Theme.route.opacity(0)]),
                                         center: CGPoint(x: px, y: py), startRadius: 0, endRadius: 14))
            var plane = c
            plane.translateBy(x: px, y: py)
            plane.rotate(by: .radians(atan2(dy, dx)))
            plane.draw(Text(Image(systemName: "airplane")).font(.system(size: 15)).foregroundColor(Theme.text), at: .zero)
        }
        .accessibilityHidden(true)
    }
}

struct AgentUpdates: View {
    private let items: [(title: String, time: String, body: String, color: Color, highlight: Bool)] = [
        ("Your ride is booked", "Now", "A driver will meet you at Arrivals, south exit. I'll send their name and plate when you land.", Theme.accent, true),
        ("Gate changed: 42 → 47B", "08:52", "Spotted it before the airport announced it and updated your Wallet pass.", Theme.sky, false),
        ("Checked in · Seat 23A", "Yesterday", "Window seat, as you usually pick. Boarding pass is in Wallet.", Theme.sage, false)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                AgentAvatar(size: 28)
                Text("Your agent is on it").font(.display(17)).foregroundStyle(Theme.text)
            }
            .padding(.horizontal, 4)
            ForEach(items.indices, id: \.self) { i in
                let it = items[i]
                HStack(alignment: .top, spacing: 12) {
                    Circle().fill(it.color).frame(width: 8, height: 8).padding(.top, 6)
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(it.title).font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.text)
                            Spacer()
                            Text(it.time).font(.system(size: 12)).foregroundStyle(Theme.muted)
                        }
                        Text(it.body).font(.system(size: 13)).foregroundStyle(Theme.soft).lineSpacing(2)
                    }
                }
                .padding(.horizontal, 14).padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 16).fill(Theme.surface))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(it.highlight ? Theme.accent.opacity(0.45) : Theme.borderSoft, lineWidth: 1))
            }
        }
    }
}

struct StayCard: View {
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 14)
                .fill(LinearGradient(colors: [Color(hex: 0x2C4A7A), Color(hex: 0xC98A3D)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 84, height: 84)
            VStack(alignment: .leading, spacing: 3) {
                Text("TONIGHT").font(.system(size: 12)).tracking(0.6).foregroundStyle(Theme.muted)
                Text("Hotel Lumen · Shibuya").font(.system(size: 16, weight: .semibold)).foregroundStyle(Theme.text)
                Text("Check-in from 15:00 · 6 nights").font(.system(size: 13)).foregroundStyle(Theme.soft)
                Button { } label: {
                    Text("Directions")
                        .font(.system(size: 13)).foregroundStyle(Theme.text)
                        .padding(.horizontal, 14).frame(height: 36)
                        .background(Capsule().fill(Theme.surface3))
                        .overlay(Capsule().strokeBorder(Theme.border, lineWidth: 1))
                }
                .padding(.top, 4)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 20).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.border, lineWidth: 1))
    }
}

struct PastTrips: View {
    @Environment(TripStore.self) private var store
    private let trips: [(code: String, city: String, when: String, colors: [Color])] = [
        ("MEX", "Mexico City", "Sep 2026 · 5 nights", [Color(hex: 0x7A2C3C), Color(hex: 0xE0A04A)]),
        ("KEF", "Reykjavík", "Jun 2026 · 4 nights", [Color(hex: 0x1F4A6A), Color(hex: 0x8FD0D8)]),
        ("CDG", "Paris", "Feb 2026 · 3 nights", [Color(hex: 0x3B2A5E), Color(hex: 0xD7A86E)])
    ]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(trips.indices, id: \.self) { i in
                let t = trips[i]
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(colors: t.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 64, height: 64)
                        .overlay(alignment: .bottomLeading) {
                            Text(t.code).font(.display(12)).foregroundStyle(.white.opacity(0.9)).padding(6)
                        }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(t.city).font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.text)
                        Text(t.when).font(.system(size: 13)).foregroundStyle(Theme.muted)
                    }
                    Spacer()
                    Button {
                        if let a = Airports.find(t.code) { store.path = []; store.selectDest(a) }
                    } label: {
                        Text("Go again")
                            .font(.system(size: 13)).foregroundStyle(Theme.text)
                            .padding(.horizontal, 14).frame(height: 36)
                            .background(Capsule().fill(Theme.surface3))
                            .overlay(Capsule().strokeBorder(Theme.border, lineWidth: 1))
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 20).fill(Theme.surface))
                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.border, lineWidth: 1))
            }
        }
    }
}
