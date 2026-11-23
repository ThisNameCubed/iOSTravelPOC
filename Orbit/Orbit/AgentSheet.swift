import SwiftUI

/// The agent's booking panel that rises from the bottom once a destination is chosen.
struct AgentSheet: View {
    @Environment(TripStore.self) private var store

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(Theme.handle).frame(width: 40, height: 5)
                .padding(.top, 8).padding(.bottom, 6)

            header
                .padding(.horizontal, 18).padding(.bottom, 10)

            if store.stage != .booked && store.stage != .booking {
                StepperBar().padding(.horizontal, 16).padding(.bottom, 10)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if !store.lastUser.isEmpty {
                        Text(store.lastUser)
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.text)
                            .padding(.vertical, 9).padding(.horizontal, 14)
                            .background(UnevenRoundedRectangle(topLeadingRadius: 18, bottomLeadingRadius: 18, bottomTrailingRadius: 4, topTrailingRadius: 18).fill(Theme.userBubble))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    if !store.agentSays.isEmpty {
                        Text(store.agentSays)
                            .font(.system(size: 14))
                            .lineSpacing(3)
                            .foregroundStyle(Theme.text2)
                            .padding(.vertical, 10).padding(.horizontal, 14)
                            .background(UnevenRoundedRectangle(topLeadingRadius: 18, bottomLeadingRadius: 4, bottomTrailingRadius: 18, topTrailingRadius: 18).fill(Theme.surface2))
                            .overlay(UnevenRoundedRectangle(topLeadingRadius: 18, bottomLeadingRadius: 4, bottomTrailingRadius: 18, topTrailingRadius: 18).stroke(Theme.borderSoft, lineWidth: 1))
                            .frame(maxWidth: 330, alignment: .leading)
                    }
                    stageContent
                }
                .padding(.horizontal, 16).padding(.top, 4).padding(.bottom, 12)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)

            Dock()
        }
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28, style: .continuous)
                .fill(Theme.surface)
                .shadow(color: Theme.shadow, radius: 24, y: -6)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var header: some View {
        HStack(spacing: 12) {
            AgentAvatar()
            VStack(alignment: .leading, spacing: 3) {
                Text(store.routeTitle)
                    .font(.display(17))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                Button { store.showCalendar = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar").font(.system(size: 13))
                        Text(store.tripMeta).lineLimit(1).underline(color: Theme.handle)
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.muted)
                }
                .accessibilityLabel("Change travel dates: \(store.tripMeta)")
            }
            Spacer(minLength: 0)
            HStack(spacing: 6) {
                Circle().fill(statusColor).frame(width: 7, height: 7)
                Text(statusText).font(.system(size: 12))
            }
            .foregroundStyle(statusColor)
        }
    }

    private var statusText: String { store.isWorking ? "Working" : store.stage == .booked ? "Booked" : "Ready" }
    private var statusColor: Color { store.isWorking ? Theme.accentInk : Theme.sage }

    @ViewBuilder private var stageContent: some View {
        switch store.stage {
        case .planning, .booking: WorkingList(labels: store.stage == .booking ? store.bookLabels : store.planLabels, done: store.work)
        case .flights: FlightList()
        case .stay: StayList()
        case .cars: CarList()
        case .extras: ExtrasList()
        case .review: ReviewCard()
        case .booked: BookedView()
        case .idle: EmptyView()
        }
    }
}

struct StepperBar: View {
    @Environment(TripStore.self) private var store

    var body: some View {
        let order = store.order
        let ready = store.isReady
        let current = order.firstIndex(of: store.stage) ?? -1
        HStack(spacing: 6) {
            ForEach(Array(order.enumerated()), id: \.offset) { i, s in
                let active = store.stage == s
                Button { if ready { store.goStage(s) } } label: {
                    HStack(spacing: 5) {
                        if ready && i < current { Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)) }
                        Text(s.label)
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(active ? Theme.accentInk : ready ? Theme.text3 : Theme.disabled)
                    .frame(maxWidth: .infinity).frame(height: 36)
                    .background(Capsule().fill(active ? Theme.accent.opacity(0.12) : Theme.surface2))
                    .overlay(Capsule().strokeBorder(active ? Theme.accent : Theme.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(!ready)
                .accessibilityAddTraits(active ? .isSelected : [])
            }
        }
    }
}

struct WorkingList: View {
    let labels: [String]
    let done: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(labels.enumerated()), id: \.offset) { i, label in
                HStack(spacing: 12) {
                    if i < done {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Theme.sage)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(Theme.sage.opacity(0.16)))
                    } else if i == done {
                        ProgressView().controlSize(.small).tint(Theme.accent).frame(width: 22, height: 22)
                    } else {
                        Circle().strokeBorder(Theme.border, lineWidth: 2).frame(width: 22, height: 22)
                    }
                    Text(label)
                        .font(.system(size: 14))
                        .foregroundStyle(i < done ? Theme.text3 : i == done ? Theme.text : Theme.disabled)
                }
            }
        }
        .padding(.vertical, 4)
        .animation(.easeInOut(duration: 0.25), value: done)
    }
}

struct FlightList: View {
    @Environment(TripStore.self) private var store

    var body: some View {
        let selected = store.totals.flight?.id
        VStack(spacing: 10) {
            ForEach(store.flights()) { f in
                Button { store.flightId = f.id } label: {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("\(f.carrier) · \(store.business ? "Business" : "Economy")")
                                .font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.soft)
                            Spacer()
                            Badge(text: f.badge)
                        }
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(Fmt.clock(f.departMinutes)).font(.display(20)).foregroundStyle(Theme.text)
                                Text(store.origin?.code ?? "").font(.system(size: 12)).foregroundStyle(Theme.muted)
                            }
                            VStack(spacing: 3) {
                                Text(Fmt.hm(f.hours)).font(.system(size: 12)).foregroundStyle(Theme.muted)
                                Rectangle().fill(Theme.handle).frame(height: 1)
                                Text(f.stopsLabel).font(.system(size: 12)).foregroundStyle(f.stops > 0 ? Theme.muted : Theme.sage)
                            }
                            .frame(maxWidth: .infinity)
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(store.arrivalClock(f)).font(.display(20)).foregroundStyle(Theme.text)
                                Text(store.dest?.code ?? "").font(.system(size: 12)).foregroundStyle(Theme.muted)
                            }
                        }
                        HStack(alignment: .firstTextBaseline) {
                            Text(f.note).font(.system(size: 12)).foregroundStyle(Theme.muted)
                            Spacer()
                            Text(Fmt.money(f.price)).font(.display(18)).foregroundStyle(Theme.text)
                        }
                    }
                    .optionCard(selected: f.id == selected)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(f.id == selected ? .isSelected : [])
            }
        }
    }
}

struct StayList: View {
    @Environment(TripStore.self) private var store

    var body: some View {
        @Bindable var store = store
        VStack(spacing: 10) {
            HStack {
                Text("Nights").font(.system(size: 14)).foregroundStyle(Theme.soft)
                Spacer()
                Stepper(value: $store.nights, in: 1...30) {
                    Text("\(store.nights)").font(.display(18)).foregroundStyle(Theme.text)
                }
                .fixedSize()
            }
            .padding(.horizontal, 4)

            ForEach(store.hotels) { h in
                Button { store.hotelId = h.id } label: {
                    HStack(alignment: .top, spacing: 12) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(colors: h.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 76, height: 84)
                            .overlay(alignment: .bottomLeading) {
                                Text(h.tier).font(.system(size: 12)).foregroundStyle(.white.opacity(0.85)).padding(6)
                            }
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(h.name).font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.text)
                                Spacer()
                                Badge(text: h.badge)
                            }
                            Text("\(store.dest?.area ?? "") · ★ \(h.rating)").font(.system(size: 13)).foregroundStyle(Theme.muted)
                            Text(h.perk).font(.system(size: 12)).foregroundStyle(Theme.muted)
                            Spacer(minLength: 4)
                            HStack(alignment: .firstTextBaseline) {
                                Text("\(Fmt.money(h.nightly)) / night").font(.system(size: 12)).foregroundStyle(Theme.muted)
                                Spacer()
                                Text(Fmt.money(h.nightly * Double(store.nights))).font(.display(16)).foregroundStyle(Theme.text)
                            }
                        }
                    }
                    .optionCard(selected: h.id == store.hotelId)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(h.id == store.hotelId ? .isSelected : [])
            }
        }
    }
}

struct CarList: View {
    @Environment(TripStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Atlas Rent · pick up at \(store.dest?.code ?? "") · \(store.nights) days")
                .font(.system(size: 13)).foregroundStyle(Theme.muted).padding(.horizontal, 4)
            ForEach(store.cars) { c in
                Button { store.carId = c.id } label: {
                    HStack(spacing: 12) {
                        Image(systemName: c.id == "c3" ? "bolt.car" : "car.side")
                            .font(.system(size: 26))
                            .foregroundStyle(c.tint)
                            .frame(width: 64, height: 64)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Theme.chip))
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(c.name).font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.text)
                                Spacer()
                                Badge(text: c.badge)
                            }
                            Text(c.model).font(.system(size: 13)).foregroundStyle(Theme.muted)
                            Text(c.spec).font(.system(size: 12)).foregroundStyle(Theme.muted)
                            HStack(alignment: .firstTextBaseline) {
                                Text("\(Fmt.money(c.daily)) / day").font(.system(size: 12)).foregroundStyle(Theme.muted)
                                Spacer()
                                Text(Fmt.money(c.daily * Double(store.nights))).font(.display(16)).foregroundStyle(Theme.text)
                            }
                            .padding(.top, 2)
                        }
                    }
                    .optionCard(selected: c.id == store.carId)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(c.id == store.carId ? .isSelected : [])
            }
        }
    }
}

struct ExtrasList: View {
    @Environment(TripStore.self) private var store

    var body: some View {
        VStack(spacing: 8) {
            ForEach(store.extrasList) { x in
                let on = store.extras.contains(x.key)
                Toggle(isOn: Binding(
                    get: { store.extras.contains(x.key) },
                    set: { v in if v { store.extras.insert(x.key) } else { store.extras.remove(x.key) } }
                )) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(x.name).font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.text)
                            Text(x.why).font(.system(size: 13)).foregroundStyle(Theme.muted)
                        }
                        Spacer()
                        Text(Fmt.money(x.price)).font(.display(15)).foregroundStyle(Theme.text)
                    }
                }
                .tint(Theme.accent)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 16).fill(Theme.surface2))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(on ? Theme.accent.opacity(0.5) : Theme.border, lineWidth: 1))
            }
        }
    }
}

struct ReviewCard: View {
    @Environment(TripStore.self) private var store

    var body: some View {
        VStack(spacing: 0) {
            ForEach(store.reviewLines) { line in
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(line.kind.uppercased()).font(.system(size: 12)).tracking(0.6).foregroundStyle(Theme.muted)
                        Text(line.text).font(.system(size: 14, weight: .medium)).foregroundStyle(Theme.text)
                    }
                    Spacer()
                    Text(line.price).font(.display(15)).foregroundStyle(Theme.text)
                }
                .padding(.horizontal, 14).padding(.vertical, 12)
                Divider().overlay(Theme.borderSoft)
            }
            HStack {
                Text("Trip total").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.text)
                Spacer()
                Text(Fmt.money(store.totals.total)).font(.display(20, .bold)).foregroundStyle(Theme.accentInk)
            }
            .padding(14)
            .background(Theme.surface3)
        }
        .background(Theme.surface2)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Theme.border, lineWidth: 1))
    }
}

struct BookedView: View {
    @Environment(TripStore.self) private var store

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Theme.sage)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Theme.sage.opacity(0.15)))
            Text(store.bookedTitle).font(.display(22)).foregroundStyle(Theme.text).multilineTextAlignment(.center)
            (Text("Confirmation ").foregroundColor(Theme.soft) + Text(store.bookingRef).bold().foregroundColor(Theme.text) + Text(" · \(store.dateRange)").foregroundColor(Theme.soft))
                .font(.system(size: 14))
            Text(store.bookedNote)
                .font(.system(size: 13)).foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center).frame(maxWidth: 300)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }
}

struct Badge: View {
    let text: String
    var body: some View {
        if !text.isEmpty {
            Text(text.uppercased())
                .font(.system(size: 11, weight: .semibold)).tracking(0.4)
                .foregroundStyle(Theme.accentInk)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 8).fill(Theme.accent.opacity(0.14)))
        }
    }
}

/// Chat input, quick asks and the primary action.
struct Dock: View {
    @Environment(TripStore.self) private var store

    var body: some View {
        @Bindable var store = store
        VStack(spacing: 10) {
            if store.stage == .booked {
                Button { store.goHome() } label: {
                    Text("Plan another trip")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.onAccent)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(Capsule().fill(Theme.accent))
                }
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(store.mode.chips, id: \.self) { chip in
                            Button { store.instruct(chip) } label: {
                                Text(chip)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Theme.text2)
                                    .padding(.horizontal, 14).frame(height: 36)
                                    .background(Capsule().fill(Theme.surface3))
                                    .overlay(Capsule().strokeBorder(Theme.border, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .scrollIndicators(.hidden)
                .padding(.horizontal, -16)

                HStack(spacing: 8) {
                    TextField("", text: $store.chatText, prompt: Text("Tell your agent what to change…").foregroundColor(Theme.faint))
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.text)
                        .submitLabel(.send)
                        .onSubmit { store.instruct(store.chatText) }
                        .padding(.horizontal, 16).frame(height: 44)
                        .background(Capsule().fill(Theme.surface2))
                        .overlay(Capsule().strokeBorder(Theme.border, lineWidth: 1))
                        .accessibilityLabel("Message your trip agent")
                    if store.isReady {
                        Button { store.next() } label: {
                            Text(store.stage == .review ? "Book \(Fmt.money(store.totals.total))" : "Next · \(Fmt.money(store.totals.total))")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Theme.onAccent)
                                .padding(.horizontal, 18).frame(height: 44)
                                .background(Capsule().fill(Theme.accent))
                                .fixedSize()
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(Theme.surface)
        .overlay(alignment: .top) { Rectangle().fill(Theme.borderSoft).frame(height: 1) }
    }
}
