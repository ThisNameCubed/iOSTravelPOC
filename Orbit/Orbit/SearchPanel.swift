import SwiftUI

/// The only question Orbit asks: where to? Plus booking type and optional dates.
struct SearchPanel: View {
    @Environment(TripStore.self) private var store
    @FocusState private var focused: Bool

    var body: some View {
        @Bindable var store = store

        VStack(alignment: .leading, spacing: 12) {
            if focused {
                suggestionList
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                Text("Where to?")
                    .font(.display(40))
                    .foregroundStyle(Theme.text)
                    .padding(.horizontal, 4)
            }

            // Booking type
            HStack(spacing: 6) {
                ForEach(BookingMode.allCases) { m in
                    let active = store.mode == m
                    Button { store.mode = m } label: {
                        Text(m.title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(active ? Theme.accentInk : Theme.soft)
                            .padding(.horizontal, 14)
                            .frame(height: 36)
                            .background(Capsule().fill(active ? Theme.accent.opacity(0.12) : Theme.surface.opacity(0.6)))
                            .overlay(Capsule().strokeBorder(active ? Theme.accent.opacity(0.6) : Theme.border.opacity(0.8), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(active ? .isSelected : [])
                }
            }
            .padding(.horizontal, 2)

            // Search field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Theme.muted)
                TextField("", text: $store.query, prompt: Text(store.mode.placeholder).foregroundColor(Theme.faint))
                    .font(.system(size: 17))
                    .foregroundStyle(Theme.text)
                    .focused($focused)
                    .submitLabel(.go)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                    .onSubmit { go() }
                    .accessibilityLabel("Destination")
                Button { store.showCalendar = true } label: {
                    Image(systemName: "calendar")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(store.customDep != nil ? Theme.accentInk : Theme.muted)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(store.customDep != nil ? Theme.accent.opacity(0.14) : .clear))
                }
                .accessibilityLabel(store.customDep != nil ? "Change dates, \(store.dateRange)" : "Choose dates on a calendar (optional)")
                Button { go() } label: {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Theme.onAccent)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Theme.accent))
                }
                .accessibilityLabel("Go")
            }
            .padding(.leading, 18).padding(.trailing, 8)
            .frame(height: 60)
            .background(Capsule().fill(Theme.surface2.opacity(0.96)))
            .overlay(Capsule().strokeBorder(focused ? Theme.accent : Theme.border, lineWidth: 1))
            .shadow(color: Theme.shadow, radius: 18, y: 8)

            if store.customDep != nil && !focused {
                HStack {
                    Button { store.showCalendar = true } label: {
                        (Text("Your dates · ").foregroundColor(Theme.soft) +
                         Text("\(store.dateRange) · \(store.nights) nights").foregroundColor(Theme.text))
                            .font(.system(size: 13))
                    }
                    Spacer()
                    Button("Let agent pick") { store.clearDates() }
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.muted)
                        .underline()
                }
                .padding(.horizontal, 18)
                .frame(minHeight: 32)
            }
        }
        .padding(.horizontal, 16)
        .animation(.spring(response: 0.4, dampingFraction: 0.9), value: focused)
    }

    private func go() {
        if store.query.trimmingCharacters(in: .whitespaces).isEmpty {
            focused = true
        } else {
            focused = false
            store.selectFirst()
        }
    }

    private var suggestionList: some View {
        let results = store.suggestions()
        return VStack(alignment: .leading, spacing: 2) {
            Text(store.query.isEmpty ? "POPULAR RIGHT NOW" : "AIRPORTS")
                .font(.system(size: 12, weight: .medium)).tracking(0.8)
                .foregroundStyle(Theme.muted)
                .padding(.horizontal, 10).padding(.top, 8).padding(.bottom, 4)
            ScrollView {
                VStack(spacing: 2) {
                    ForEach(results) { a in
                        Button {
                            focused = false
                            store.selectDest(a)
                        } label: {
                            HStack(spacing: 12) {
                                Text(a.code)
                                    .font(.display(14))
                                    .foregroundStyle(Theme.accentInk)
                                    .frame(width: 52, height: 40)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Theme.chip))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(a.city).font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.text)
                                    Text(a.country).font(.system(size: 13)).foregroundStyle(Theme.muted)
                                }
                                Spacer()
                                if let o = store.origin {
                                    Text(Geo.miles(Geo.km(o, a))).font(.system(size: 13)).foregroundStyle(Theme.muted)
                                }
                            }
                            .padding(.horizontal, 10)
                            .frame(minHeight: 56)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    if results.isEmpty {
                        Text("No airport matches “\(store.query)” yet. Try a city or a 3-letter code.")
                            .font(.system(size: 14)).foregroundStyle(Theme.muted)
                            .padding(14)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(8)
        .frame(maxHeight: 340)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Theme.surface.opacity(0.95)))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Theme.border, lineWidth: 1))
    }
}
