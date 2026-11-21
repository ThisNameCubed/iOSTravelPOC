import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var state
    @FocusState private var focused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Good evening, Sam")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.muted)
                    Spacer()
                    Circle()
                        .fill(Color(hex: 0xE4DFD3))
                        .frame(width: 38, height: 38)
                        .overlay(Text("S").font(.system(size: 15, weight: .semibold)))
                        .accessibilityLabel("Profile")
                }
                .padding(.top, 8)

                Text("Where to next?")
                    .font(.system(size: 32, weight: .bold))
                    .tracking(-0.8)
                    .padding(.top, 2)
                    .padding(.bottom, 18)

                starter

                Button { state.destination = Destination.all[0]; state.path = [.results] } label: {
                    HStack(spacing: 12) {
                        AgentOrb(size: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("SFO → Tokyo dropped $142").font(.system(size: 15, weight: .semibold))
                            Text("Atlas is watching 3 routes for you").font(.system(size: 12)).foregroundStyle(Theme.muted)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(Theme.soft)
                    }
                    .padding(16)
                    .card(radius: 18)
                }
                .buttonStyle(PressStyle())
                .padding(.top, 20)

                SectionLabel("Ideas")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(state.ideas, id: \.self) { idea in
                            Button { state.query = idea; focused = true } label: { Chip(text: idea) }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.horizontal, -20)

                SectionLabel("Upcoming")
                upcoming
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.bg)
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: state.focusRequest) {
            if state.calendarSource == .home { focused = true }
        }
    }

    // One card holds every way to start: type to Atlas, pick dates, or go flexible.
    private var starter: some View {
        @Bindable var state = state
        return VStack(spacing: 14) {
            HStack(spacing: 10) {
                AgentOrb(size: 28)
                TextField("Tokyo in March, under $900…", text: $state.query)
                    .font(.system(size: 17))
                    .focused($focused)
                    .submitLabel(.go)
                    .onSubmit { state.startPlanning() }
                Button { state.showToast("Voice input isn't part of this prototype") } label: {
                    Image(systemName: "mic")
                        .foregroundStyle(Theme.muted)
                        .frame(width: 36, height: 36)
                        .background(Theme.bg, in: Circle())
                }
                .accessibilityLabel("Voice input")
            }
            Divider().overlay(Theme.line)
            HStack(spacing: 8) {
                OptionTile(title: state.datesSet ? state.rangeText : "Pick dates",
                           subtitle: state.datesSet ? "Tap to change" : "Open calendar",
                           background: Theme.bg, selected: state.datesSet) {
                    Image(systemName: "calendar").font(.system(size: 18)).foregroundStyle(Theme.ink)
                } action: { state.openCalendar(.home) }

                OptionTile(title: "I'm flexible", subtitle: "Atlas picks dates",
                           background: Theme.redTint, selected: state.flexible) {
                    Spark().fill(Theme.red).frame(width: 16, height: 16)
                } action: { state.toggleFlexible() }
            }
            PrimaryButton(title: "Plan my trip", icon: "arrow.right", height: 46) {
                focused = false
                state.startPlanning()
            }
        }
        .padding(16)
        .card(radius: 24)
        .shadow(color: .black.opacity(0.07), radius: 18, y: 10)
    }

    @ViewBuilder private var upcoming: some View {
        if let trip = state.booked {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(trip.name).font(.system(size: 17, weight: .bold))
                    Text(trip.dates).font(.system(size: 13)).foregroundStyle(Theme.muted)
                    Spacer()
                    Tag(text: trip.kind == .fun ? "Stopover" : "Booked", style: trip.kind == .fun ? .gold : .green)
                }
                HStack(spacing: 8) {
                    Text("SFO")
                    dashes
                    if trip.kind != .fastest {
                        Circle().fill(Theme.goldDark).frame(width: 8, height: 8)
                        Text(trip.kind == .fun ? "\(trip.stop) · 2 nights" : trip.stop).foregroundStyle(Theme.goldDark)
                        dashes
                    }
                    Text(trip.code)
                }
                .font(.system(size: 12, weight: .semibold))
            }
            .padding(18)
            .card()
        } else {
            Text("No trips yet. Plan one above and it will show up here.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .card()
        }
    }

    private var dashes: some View {
        Line()
            .stroke(Theme.line, style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [2, 4]))
            .frame(height: 2)
    }
}

struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return p
    }
}

struct VLine: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return p
    }
}

struct OptionTile<Icon: View>: View {
    let title: String
    let subtitle: String
    let background: Color
    let selected: Bool
    @ViewBuilder let icon: () -> Icon
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                icon()
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.ink).lineLimit(1)
                    Text(subtitle).font(.system(size: 11.5)).foregroundStyle(Theme.muted).lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(height: 56)
            .background(background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(selected ? Theme.red : .clear, lineWidth: 1.5))
        }
        .buttonStyle(PressStyle())
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
