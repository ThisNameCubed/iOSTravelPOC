import SwiftUI

struct ResultsView: View {
    @Environment(AppState.self) private var state
    @FocusState private var focused: Bool
    @State private var draft = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 10) {
                    AgentOrb(size: 22)
                    Text("3 strong options. My pick saves $\(state.options[0].savings) and keeps every leg under 9 hours.")
                        .font(.system(size: 14, weight: .medium))
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.redTint, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(state.filters.indices, id: \.self) { i in
                            Button { withAnimation(.snappy) { state.filter = i } } label: {
                                Chip(text: state.filters[i], style: state.filter == i ? .red : .plain)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.horizontal, -16)

                ForEach(state.filteredOptions) { option in
                    Button { state.open(option) } label: { ResultCard(option: option) }
                        .buttonStyle(PressStyle())
                }

                Text("Sample fares for the prototype")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.soft)
                    .frame(maxWidth: .infinity)
            }
            .padding(16)
        }
        .background(Theme.bg)
        .safeAreaInset(edge: .bottom) {
            Composer(text: $draft, placeholder: "“Cheaper a day earlier?”", focus: $focused,
                     onCalendar: { state.openCalendar(.results) },
                     onSend: {
                         let text = draft
                         draft = ""
                         state.send(text)
                     })
            .padding(.vertical, 8)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    Text("SFO → \(state.destination.name)").font(.system(size: 17, weight: .bold))
                    Text("\(state.rangeText) · 1 adult · ≤ $\(state.budget)")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.muted)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { state.openCalendar(.results) } label: { Image(systemName: "calendar") }
                    .accessibilityLabel("Change dates")
            }
        }
        .toolbarBackground(Theme.bg, for: .navigationBar)
    }
}

struct ResultCard: View {
    let option: FlightOption

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                badge
                Spacer()
                Text("$\(option.price)").font(.system(size: 26, weight: .bold)).tracking(-0.6)
            }
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.departTime).font(.system(size: 18, weight: .bold))
                    Text("SFO").font(.system(size: 12)).foregroundStyle(Theme.muted)
                }
                RouteLine(caption: option.middle,
                          stopColor: option.kind == .fastest ? nil : option.kind == .fun ? Theme.goldDark : Theme.red)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(option.arriveTime).font(.system(size: 18, weight: .bold))
                    Text(option.arrivalLabel).font(.system(size: 12)).foregroundStyle(Theme.muted)
                }
            }
            Divider().overlay(Theme.line)
            FlowLayout(spacing: 6) {
                ForEach(option.tags, id: \.self) { tag in
                    Tag(text: tag, style: tag.hasPrefix("Split") ? .green : tag == "Stopover" ? .gold : .grey)
                }
            }
            Text("Why: \(option.why)")
                .font(.system(size: 12))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.leading)
        }
        .foregroundStyle(Theme.ink)
        .padding(16)
        .card(radius: 22, stroke: option.kind == .pick ? Theme.red : Theme.line, lineWidth: option.kind == .pick ? 1.5 : 1)
    }

    @ViewBuilder private var badge: some View {
        switch option.kind {
        case .pick:
            HStack(spacing: 5) {
                Spark().fill(.white).frame(width: 10, height: 10)
                Text("ATLAS PICK")
            }
            .font(.system(size: 11, weight: .bold))
            .tracking(0.5)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Theme.red, in: Capsule())
        case .fun:
            Tag(text: "FUN ROUTE", style: .gold)
        case .fastest:
            Tag(text: "FASTEST", style: .grey)
        }
    }
}
