import SwiftUI

struct DestinationCard: Identifiable {
    let code: String
    let city: String
    let tag: String
    let detail: String
    let price: String
    let colors: [Color]
    var id: String { code }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let fromUser: Bool
    let text: String
    var cards: [DestinationCard] = []
}

private enum Sets {
    static let warm = [
        DestinationCard(code: "CUN", city: "Cancún", tag: "82°F · beach", detail: "4h 25m · nonstop", price: "from $1,140", colors: [Color(hex: 0x0E6E7A), Color(hex: 0xF2C26B)]),
        DestinationCard(code: "HNL", city: "Honolulu", tag: "80°F · surf", detail: "5h 50m · nonstop", price: "from $1,380", colors: [Color(hex: 0x1F5A55), Color(hex: 0xF0A35E)]),
        DestinationCard(code: "DPS", city: "Bali", tag: "86°F · jungle", detail: "19h · 1 stop", price: "from $1,490", colors: [Color(hex: 0x2F5A2A), Color(hex: 0xD9B45A)])
    ]
    static let snow = [
        DestinationCard(code: "KEF", city: "Reykjavík", tag: "Northern lights", detail: "9h 45m · 1 stop", price: "from $1,260", colors: [Color(hex: 0x1F4A6A), Color(hex: 0x8FD0D8)]),
        DestinationCard(code: "YVR", city: "Vancouver", tag: "Ski · Whistler", detail: "2h 50m · nonstop", price: "from $890", colors: [Color(hex: 0x24435E), Color(hex: 0xC9D9E8)]),
        DestinationCard(code: "ANC", city: "Anchorage", tag: "Glaciers", detail: "5h 20m · nonstop", price: "from $1,050", colors: [Color(hex: 0x2C3D5E), Color(hex: 0x9FB8D9)])
    ]
    static let europe = [
        DestinationCard(code: "LIS", city: "Lisbon", tag: "Spring · 68°F", detail: "13h · 1 stop", price: "from $1,320", colors: [Color(hex: 0x7A3C2C), Color(hex: 0xF2C26B)]),
        DestinationCard(code: "BCN", city: "Barcelona", tag: "Food · beach", detail: "13h 30m · 1 stop", price: "from $1,410", colors: [Color(hex: 0x7A2C3C), Color(hex: 0xE0A04A)]),
        DestinationCard(code: "CDG", city: "Paris", tag: "Museums", detail: "10h 55m · nonstop", price: "from $1,480", colors: [Color(hex: 0x3B2A5E), Color(hex: 0xD7A86E)])
    ]
    static let weekend = [
        DestinationCard(code: "MEX", city: "Mexico City", tag: "Fri – Sun", detail: "3h 40m · nonstop", price: "from $620", colors: [Color(hex: 0x7A2C3C), Color(hex: 0xE0A04A)]),
        DestinationCard(code: "SFO", city: "San Francisco", tag: "Fri – Sun", detail: "1h 25m · nonstop", price: "from $540", colors: [Color(hex: 0x2C4A7A), Color(hex: 0xE08A5A)]),
        DestinationCard(code: "PDX", city: "Portland", tag: "Fri – Sun", detail: "2h 30m · nonstop", price: "from $580", colors: [Color(hex: 0x1F5A3F), Color(hex: 0xA8C97A)])
    ]
}

/// Full-screen conversation with the trip agent (sample replies; connect to an LLM later).
struct AgentChatView: View {
    @Environment(TripStore.self) private var store
    @State private var messages: [ChatMessage] = [
        ChatMessage(fromUser: false, text: "Hi — I'm your trip agent. Give me a place, a vibe or a budget and I'll handle flights, stays and the details."),
        ChatMessage(fromUser: true, text: "Somewhere warm in January, under $1,500"),
        ChatMessage(fromUser: false, text: "Three warm escapes that fit $1,500 for a week — flights and hotel included:", cards: Sets.warm)
    ]
    @State private var text = ""
    @State private var typing = false
    @FocusState private var focused: Bool

    private let chips = ["Weekend getaway", "Somewhere snowy", "Europe in spring", "Watch Lisbon fares"]

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today").font(.system(size: 12)).foregroundStyle(Theme.faint).frame(maxWidth: .infinity)
                        ForEach(messages) { m in
                            bubble(m).id(m.id)
                        }
                        if typing { TypingDots().id("typing") }
                    }
                    .padding(16)
                }
                .scrollIndicators(.hidden)
                .onChange(of: messages.count) {
                    if let id = messages.last?.id { withAnimation { proxy.scrollTo(id, anchor: .bottom) } }
                }
                .onChange(of: typing) {
                    if typing { withAnimation { proxy.scrollTo("typing", anchor: .bottom) } }
                }
            }

            VStack(spacing: 10) {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(chips, id: \.self) { c in
                            Button { send(c) } label: {
                                Text(c).font(.system(size: 13)).foregroundStyle(Theme.text2)
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

                HStack(spacing: 8) {
                    TextField("", text: $text, prompt: Text("Ask for a place, a vibe or a budget…").foregroundColor(Theme.faint))
                        .font(.system(size: 15)).foregroundStyle(Theme.text)
                        .focused($focused)
                        .submitLabel(.send)
                        .onSubmit { send(text) }
                        .padding(.horizontal, 16).frame(height: 46)
                        .background(Capsule().fill(Theme.surface2))
                        .overlay(Capsule().strokeBorder(Theme.border, lineWidth: 1))
                        .accessibilityLabel("Message your trip agent")
                    Button { send(text) } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Theme.onAccent)
                            .frame(width: 46, height: 46)
                            .background(Circle().fill(Theme.accent))
                    }
                    .accessibilityLabel("Send")
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 10).padding(.bottom, 8)
            .background(Theme.surface)
            .overlay(alignment: .top) { Rectangle().fill(Theme.borderSoft).frame(height: 1) }
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Trip Agent")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.bg, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
    }

    @ViewBuilder
    private func bubble(_ m: ChatMessage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if m.fromUser {
                Text(m.text)
                    .font(.system(size: 15)).foregroundStyle(Theme.text)
                    .padding(.vertical, 10).padding(.horizontal, 14)
                    .background(UnevenRoundedRectangle(topLeadingRadius: 18, bottomLeadingRadius: 18, bottomTrailingRadius: 4, topTrailingRadius: 18).fill(Theme.userBubble))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.leading, 60)
            } else {
                Text(m.text)
                    .font(.system(size: 15)).foregroundStyle(Theme.text2).lineSpacing(3)
                    .padding(.vertical, 10).padding(.horizontal, 14)
                    .background(UnevenRoundedRectangle(topLeadingRadius: 18, bottomLeadingRadius: 4, bottomTrailingRadius: 18, topTrailingRadius: 18).fill(Theme.surface2))
                    .padding(.trailing, 40)
            }
            if !m.cards.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(m.cards) { card($0) }
                    }
                    .padding(.horizontal, 16)
                }
                .scrollIndicators(.hidden)
                .padding(.horizontal, -16)
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func card(_ c: DestinationCard) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            LinearGradient(colors: c.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .frame(height: 96)
                .overlay(alignment: .topLeading) {
                    Text(c.tag).font(.system(size: 12, weight: .semibold)).foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.4)))
                        .padding(10)
                }
                .overlay(alignment: .bottomLeading) {
                    Text(c.code).font(.display(13)).foregroundStyle(.white.opacity(0.9)).padding(10)
                }
            VStack(alignment: .leading, spacing: 3) {
                Text(c.city).font(.system(size: 16, weight: .semibold)).foregroundStyle(Theme.text)
                Text(c.detail).font(.system(size: 13)).foregroundStyle(Theme.muted)
                HStack {
                    Text(c.price).font(.display(14)).foregroundStyle(Theme.text)
                    Spacer()
                    Button { planIt(c.code) } label: {
                        Text("Plan it").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.onAccent)
                            .padding(.horizontal, 12).frame(height: 34)
                            .background(Capsule().fill(Theme.accent))
                    }
                }
                .padding(.top, 8)
            }
            .padding(12)
        }
        .frame(width: 210)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Theme.border, lineWidth: 1))
    }

    /// Hand the destination to the globe: pop back and let the agent plan it.
    private func planIt(_ code: String) {
        guard let a = Airports.find(code) else { return }
        store.mode = .packages
        store.path = []
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 450_000_000)
            store.selectDest(a)
        }
    }

    private func send(_ raw: String) {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, !typing else { return }
        text = ""
        withAnimation { messages.append(ChatMessage(fromUser: true, text: t)) }
        typing = true
        let reply = Self.reply(to: t, from: store.origin?.code ?? "your airport")
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_100_000_000)
            withAnimation {
                typing = false
                messages.append(reply)
            }
        }
    }

    private static func reply(to t: String, from home: String) -> ChatMessage {
        let lo = t.lowercased()
        func has(_ w: String...) -> Bool { w.contains { lo.contains($0) } }
        if has("watch", "alert", "fare", "price") {
            return ChatMessage(fromUser: false, text: "Done. I'm watching \(home) → LIS for March 12 – 18. If the round trip drops under $900, I'll hold it and ping you to confirm.")
        }
        if has("warm", "beach", "sun", "tropical") {
            return ChatMessage(fromUser: false, text: "Here's where it's warm and easy to reach from \(home):", cards: Sets.warm)
        }
        if has("snow", "ski", "cold", "winter", "northern") {
            return ChatMessage(fromUser: false, text: "Cold-weather picks — I'd go Reykjavík for the aurora odds:", cards: Sets.snow)
        }
        if has("europe", "spring", "lisbon", "paris", "barcelona") {
            return ChatMessage(fromUser: false, text: "Europe in spring, before the summer crowds:", cards: Sets.europe)
        }
        if has("weekend", "short", "quick", "getaway") {
            return ChatMessage(fromUser: false, text: "Leave Friday after work, back Sunday night:", cards: Sets.weekend)
        }
        return ChatMessage(fromUser: false, text: "I can plan that. Want me to pick dates and a stay for you, or show a few options first?")
    }
}

struct TypingDots: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    let phase = (sin((t * 5.5) - Double(i) * 0.8) + 1) / 2
                    Circle().fill(Theme.soft)
                        .frame(width: 7, height: 7)
                        .opacity(0.3 + 0.7 * phase)
                        .offset(y: -3 * phase)
                }
            }
            .padding(.vertical, 14).padding(.horizontal, 16)
            .background(UnevenRoundedRectangle(topLeadingRadius: 18, bottomLeadingRadius: 4, bottomTrailingRadius: 18, topTrailingRadius: 18).fill(Theme.surface2))
        }
        .accessibilityLabel("Agent is typing")
    }
}
