import SwiftUI

// MARK: - Split-ticket plan

struct SplitTicketView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        @Bindable var state = state
        let option = state.options[0]
        let d = state.destination
        let first = Int((Double(option.price) * 0.36).rounded())

        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("$\(option.price)").font(.system(size: 48, weight: .bold)).tracking(-1.6)
                        Text("vs. $\(option.oneTicket) as one ticket").foregroundStyle(Theme.muted)
                    }
                    Spacer()
                    Text("You save $\(option.savings)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Theme.greenTint, in: Capsule())
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 4)

                TicketCard(number: 1, from: "SFO", to: d.stopCode,
                           departs: "\(shortDate(state.start)) · 08:10", arrives: "11:05",
                           duration: "5h 55m", price: first, carrier: "Carrier A · Flight 11 · Economy + 1 bag")

                HStack(alignment: .top, spacing: 10) {
                    AgentOrb(size: 22)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Self-transfer in \(d.stopCode) · 4h 20m").font(.system(size: 13, weight: .semibold))
                        Text("I padded this. 2h30 is the safe minimum with a bag re-check.")
                            .font(.system(size: 12.5))
                            .foregroundStyle(Theme.muted)
                    }
                }
                .padding(12)
                .background(Theme.redTint, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.leading, 44)
                .overlay(alignment: .leading) {
                    VLine()
                        .stroke(Theme.red, style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [2, 5]))
                        .frame(width: 2)
                        .padding(.leading, 20)
                        .padding(.vertical, -12)
                }

                TicketCard(number: 2, from: d.stopCode, to: d.code,
                           departs: "\(shortDate(state.start)) · 15:30",
                           arrives: "\(shortDate(addDays(1, to: state.start))) · 19:20",
                           duration: "8h 50m", price: option.price - first,
                           carrier: "Carrier B · Flight 1 · Standard + 1 bag")

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Atlas Protect").font(.system(size: 16, weight: .semibold))
                        Text("If leg 1 is delayed, I'll rebook leg 2 automatically at no cost to you.")
                            .font(.system(size: 12.5))
                            .foregroundStyle(Color(hex: 0xF6D3D0))
                    }
                    Spacer()
                    Toggle("Atlas Protect", isOn: $state.protectOn)
                        .labelsHidden()
                        .tint(Theme.gold)
                }
                .foregroundStyle(.white)
                .padding(16)
                .background(LinearGradient(colors: [Theme.red, Color(hex: 0x8E1118)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.top, 4)

                Text(state.protectOn ? "Two separate bookings, covered by Protect."
                                     : "Without Protect, a missed connection on leg 2 is not covered.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.muted)
                    .padding(.horizontal, 4)
            }
            .padding(16)
        }
        .background(Theme.bg)
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: "Book both tickets · $\(option.price)") { state.choose(.pick) }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Theme.bg)
        }
        .navigationTitle("Split-ticket plan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.bg, for: .navigationBar)
    }
}

struct TicketCard: View {
    let number: Int
    let from: String, to: String
    let departs: String, arrives: String
    let duration: String
    let price: Int
    let carrier: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("TICKET \(number)").font(.system(size: 11, weight: .bold)).tracking(0.6).foregroundStyle(Theme.muted)
                Spacer()
                Text("$\(price)").font(.system(size: 15, weight: .bold))
            }
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(from).font(.system(size: 22, weight: .bold))
                    Text(departs).font(.system(size: 12)).foregroundStyle(Theme.muted)
                }
                RouteLine(caption: duration, stopColor: nil)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(to).font(.system(size: 22, weight: .bold))
                    Text(arrives).font(.system(size: 12)).foregroundStyle(Theme.muted)
                }
            }
            Text(carrier).font(.system(size: 12)).foregroundStyle(Theme.soft)
        }
        .padding(16)
        .card()
    }
}

// MARK: - Fun route (stopover as a mini-trip)

struct FunRouteView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        let stops = state.stopovers
        let price = state.options[0].price + stops[state.stopIndex].extra

        ScrollView {
            VStack(spacing: 0) {
                RouteMap(stop: stops[state.stopIndex].city, code: state.destination.code)
                    .frame(height: 260)

                VStack(alignment: .leading, spacing: 0) {
                    Capsule().fill(Theme.line).frame(width: 40, height: 4).frame(maxWidth: .infinity).padding(.top, 10)
                    (Text("Turn one long haul\n") + Text("into a mini-trip.").foregroundStyle(Theme.goldDark))
                        .font(.system(size: 26, weight: .bold))
                        .tracking(-0.6)
                        .padding(.top, 18)
                    Text("Same airlines. No leg over 9 hours.")
                        .foregroundStyle(Theme.muted)
                        .padding(.top, 6)

                    HStack(spacing: 8) {
                        ForEach(stops.indices, id: \.self) { i in
                            let stop = stops[i]
                            let on = i == state.stopIndex
                            Button { withAnimation(.snappy) { state.stopIndex = i } } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(stop.city).font(.system(size: 14, weight: .bold)).lineLimit(1).minimumScaleFactor(0.8)
                                    Text(stop.length).font(.system(size: 12)).foregroundStyle(Theme.muted)
                                    Text("+$\(stop.extra)")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(on ? Theme.goldDark : Theme.ink)
                                        .padding(.top, 8)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(on ? Theme.goldTint : Theme.surface,
                                            in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(on ? Theme.goldDark : Theme.line, lineWidth: 1.5))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 18)

                    HStack(alignment: .top, spacing: 10) {
                        AgentOrb(size: 22)
                        VStack(alignment: .leading, spacing: 10) {
                            switch state.hotelAnswer {
                            case .some(true):
                                Text("Holding a beach hotel near the shuttle for **$164/night**. It's on your review screen.")
                            case .some(false):
                                Text("No problem, flights only.")
                            case .none:
                                Text("You land at 11:05. Want me to hold a beach hotel near the airport shuttle and plan a sunrise hike?")
                                HStack(spacing: 8) {
                                    Button {
                                        state.hotelAnswer = true
                                        state.showToast("Hotel held for 24 hours")
                                    } label: { Chip(text: "Yes, under $180") }
                                    Button { state.hotelAnswer = false } label: { Chip(text: "Just flights") }
                                }
                            }
                        }
                        .font(.system(size: 14.5))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .background(Theme.bg, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .background(Theme.surface,
                            in: UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28, style: .continuous))
                .offset(y: -24)
            }
        }
        .background(Theme.surface)
        .ignoresSafeArea(edges: .top)
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: "Add \(stops[state.stopIndex].city) stop · $\(price)") { state.choose(.fun) }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Theme.surface)
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

struct RouteMap: View {
    let stop: String
    let code: String

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let a = CGPoint(x: w * 0.14, y: h * 0.80)
            let b = CGPoint(x: w * 0.50, y: h * 0.66)
            let c = CGPoint(x: w * 0.86, y: h * 0.42)
            ZStack {
                LinearGradient(colors: [Theme.mapTop, Theme.bg], startPoint: .top, endPoint: .bottom)
                Canvas { ctx, size in
                    for x in stride(from: 14.0, to: size.width, by: 26) {
                        for y in stride(from: 14.0, to: size.height, by: 26) {
                            ctx.fill(Path(ellipseIn: CGRect(x: x - 1.2, y: y - 1.2, width: 2.4, height: 2.4)),
                                     with: .color(Theme.mapDot))
                        }
                    }
                }
                Path { p in
                    p.move(to: a)
                    p.addQuadCurve(to: b, control: CGPoint(x: w * 0.30, y: h * 0.42))
                }
                .stroke(Theme.goldDark, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [1, 7]))
                Path { p in
                    p.move(to: b)
                    p.addQuadCurve(to: c, control: CGPoint(x: w * 0.72, y: h * 0.12))
                }
                .stroke(Theme.ink, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [1, 7]))

                pin(at: a, label: "SFO", color: Theme.ink, size: 14)
                pin(at: b, label: stop, color: Theme.goldDark, size: 28)
                pin(at: c, label: code, color: Theme.ink, size: 14)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Route from SFO via \(stop) to \(code)")
    }

    private func pin(at point: CGPoint, label: String, color: Color, size: CGFloat) -> some View {
        VStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: size, height: size)
                .overlay(Circle().stroke(.white, lineWidth: size > 20 ? 3 : 0))
            Text(label).font(.system(size: 12, weight: .bold)).foregroundStyle(color)
        }
        .position(x: point.x, y: point.y + 10)
    }
}
