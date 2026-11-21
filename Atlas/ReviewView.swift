import SwiftUI

struct ReviewView: View {
    @Environment(AppState.self) private var state

    private let rows: [(String, String)] = [
        ("Watch price & rebook", "If it drops by $40+ before you fly"),
        ("Protect connections", "Auto-rebook if a leg is delayed"),
        ("Check in & pick seats", "Aisle, front half, every leg"),
        ("Suggest things to do", "A short list for your first day, sent for approval")
    ]

    var body: some View {
        @Bindable var state = state
        let choice = state.choice
        let d = state.destination
        let stop = state.stopovers[state.stopIndex]

        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(routeText(choice?.kind ?? .pick, d: d, stop: stop.city)).font(.system(size: 18, weight: .bold))
                        Spacer()
                        if let choice {
                            Tag(text: choice.title, style: choice.kind == .fun ? .gold : choice.kind == .pick ? .green : .grey)
                        }
                    }
                    Text(state.rangeText + (choice?.kind == .fun ? " · \(stop.length) in \(stop.city)" : ""))
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.muted)
                    if state.hotelCost > 0 {
                        HStack {
                            Text("Beach hotel · 2 nights")
                            Spacer()
                            Text("$\(state.hotelCost)").fontWeight(.semibold)
                        }
                        .font(.system(size: 13))
                        .padding(.top, 10)
                    }
                    Divider().overlay(Theme.line).padding(.vertical, 10)
                    HStack {
                        Text("Total").foregroundStyle(Theme.muted)
                        Spacer()
                        Text("$\(state.total)").font(.system(size: 26, weight: .bold)).tracking(-0.6)
                    }
                }
                .padding(18)
                .card(radius: 22)

                HStack(spacing: 8) {
                    AgentOrb(size: 22)
                    Text("Let Atlas handle the rest").font(.system(size: 16, weight: .semibold))
                }
                .padding(.top, 10)
                .padding(.leading, 4)

                VStack(spacing: 0) {
                    ForEach(rows.indices, id: \.self) { i in
                        if i > 0 { Divider().overlay(Theme.line).padding(.leading, 16) }
                        Toggle(isOn: $state.autopilot[i]) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(rows[i].0).font(.system(size: 15, weight: .semibold))
                                Text(rows[i].1).font(.system(size: 12)).foregroundStyle(Theme.muted)
                            }
                        }
                        .tint(Theme.red)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
                .card()

                HStack(spacing: 10) {
                    Spark().fill(Theme.red).frame(width: 16, height: 16)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Nothing is charged until you confirm.").font(.system(size: 13, weight: .semibold))
                        Text("Free cancellation for 24 hours.").font(.system(size: 13)).foregroundStyle(Theme.muted)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.redTint, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.top, 4)
            }
            .padding(16)
        }
        .background(Theme.bg)
        .safeAreaInset(edge: .bottom) {
            SlideToBook(label: "Slide to book · $\(state.total)") { state.book() }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Theme.bg)
        }
        .navigationTitle("Review trip")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.bg, for: .navigationBar)
    }

    private func routeText(_ kind: OptionKind, d: Destination, stop: String) -> String {
        switch kind {
        case .fastest: return "SFO → \(d.code)"
        case .fun: return "SFO → \(stop) → \(d.code)"
        case .pick: return "SFO → \(d.stopCode) → \(d.code)"
        }
    }
}

struct SlideToBook: View {
    let label: String
    let onComplete: () -> Void
    @State private var offset: CGFloat = 0
    @State private var completed = false

    var body: some View {
        GeometryReader { geo in
            let maxOffset = max(geo.size.width - 62, 1)
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.red)
                Capsule().fill(Theme.redDark).frame(width: offset + 56)
                Text(label)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.leading, 40)
                    .opacity(1 - Double(offset / maxOffset) * 0.6)
                Circle()
                    .fill(Theme.gold)
                    .frame(width: 50, height: 50)
                    .overlay(Image(systemName: "arrow.right").font(.system(size: 18, weight: .bold)).foregroundStyle(Theme.ink))
                    .offset(x: 6 + offset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                offset = min(max(0, value.translation.width), maxOffset)
                            }
                            .onEnded { _ in
                                if offset > maxOffset * 0.85 {
                                    withAnimation(.easeOut(duration: 0.15)) { offset = maxOffset }
                                    completed = true
                                    onComplete()
                                } else {
                                    withAnimation(.spring(duration: 0.35)) { offset = 0 }
                                }
                            }
                    )
            }
        }
        .frame(height: 62)
        .sensoryFeedback(.success, trigger: completed)
        .onDisappear { offset = 0; completed = false }
        .accessibilityElement()
        .accessibilityLabel(label)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onComplete() }
    }
}

struct BookedView: View {
    @Environment(AppState.self) private var state
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Circle()
                .fill(Theme.red)
                .frame(width: 96, height: 96)
                .overlay(Image(systemName: "checkmark").font(.system(size: 40, weight: .bold)).foregroundStyle(.white))
                .scaleEffect(appeared ? 1 : 0.3)
                .padding(.bottom, 24)
            Text("You're booked").font(.system(size: 30, weight: .bold)).tracking(-0.6)
            Text("\(state.destination.name), \(state.rangeText) · $\(state.total). Confirmation sent to your email.")
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.muted)
                .padding(.top, 8)
            Text("Atlas is watching prices and connections for you.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.muted)
                .padding(.top, 6)
            Spacer()
            PrimaryButton(title: "Back to home") { state.goHome() }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg)
        .navigationBarBackButtonHidden()
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) { appeared = true }
        }
    }
}
