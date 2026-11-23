import SwiftUI

/// Change the starting airport: search any airport, pick a nearby one, or go back to the detected one.
struct OriginPicker: View {
    @Environment(TripStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @FocusState private var focused: Bool

    private var results: [Airport] {
        let q = query.trimmingCharacters(in: .whitespaces)
        if !q.isEmpty { return Airports.search(q, excluding: nil) }
        // Nearby: closest to wherever we detected the user (or the current start).
        guard let ref = store.detectedOrigin ?? store.origin else { return Array(Airports.all.prefix(8)) }
        return Airports.all
            .sorted { Geo.km(ref, $0) < Geo.km(ref, $1) }
            .prefix(8)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Starting airport")
                .font(.display(20))
                .foregroundStyle(Theme.text)
                .padding(.top, 24)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundStyle(Theme.muted)
                TextField("", text: $query, prompt: Text("City or airport code").foregroundColor(Theme.faint))
                    .foregroundStyle(Theme.text)
                    .focused($focused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .onSubmit { if let a = results.first { choose(a) } }
                    .accessibilityLabel("Search airports")
            }
            .padding(.horizontal, 16).frame(height: 48)
            .background(Capsule().fill(Theme.surface2))
            .overlay(Capsule().strokeBorder(focused ? Theme.accent : Theme.border, lineWidth: 1))

            if let detected = store.detectedOrigin, store.originMethod == .manual {
                Button { store.resetOrigin(); dismiss() } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.sage)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Theme.sage.opacity(0.15)))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Use my nearest airport").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.text)
                            Text("\(detected.code) · \(detected.city)").font(.system(size: 13)).foregroundStyle(Theme.muted)
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Text(query.isEmpty ? "NEARBY" : "AIRPORTS")
                .font(.system(size: 12, weight: .medium)).tracking(0.8)
                .foregroundStyle(Theme.muted)

            ScrollView {
                VStack(spacing: 2) {
                    ForEach(results) { a in
                        let current = a.code == store.origin?.code
                        Button { choose(a) } label: {
                            HStack(spacing: 12) {
                                Text(a.code)
                                    .font(.display(14))
                                    .foregroundStyle(current ? Theme.sage : Theme.accentInk)
                                    .frame(width: 52, height: 40)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Theme.chip))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(a.city).font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.text)
                                    Text(a.country).font(.system(size: 13)).foregroundStyle(Theme.muted)
                                }
                                Spacer()
                                if current {
                                    Image(systemName: "checkmark").font(.system(size: 14, weight: .bold)).foregroundStyle(Theme.sage)
                                } else if let ref = store.detectedOrigin, query.isEmpty {
                                    Text(Geo.miles(Geo.km(ref, a))).font(.system(size: 13)).foregroundStyle(Theme.muted)
                                }
                            }
                            .frame(minHeight: 56)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(current ? .isSelected : [])
                    }
                    if results.isEmpty {
                        Text("No airport matches “\(query)”.")
                            .font(.system(size: 14)).foregroundStyle(Theme.muted)
                            .padding(.vertical, 14)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 20)
    }

    private func choose(_ a: Airport) {
        if a.code != store.origin?.code { store.setOrigin(a) }
        dismiss()
    }
}
