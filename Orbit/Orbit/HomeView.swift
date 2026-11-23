import SwiftUI
import UIKit
import Combine

struct HomeView: View {
    @Environment(TripStore.self) private var store
    @State private var keyboardUp = false

    var body: some View {
        @Bindable var store = store
        let inTrip = store.dest != nil

        ZStack(alignment: .top) {
            Theme.bg.ignoresSafeArea()

            // Globe layer ignores the keyboard so it never jumps.
            GeometryReader { geo in
                GlobeView(model: store.globe, trip: inTrip)
                    .frame(width: geo.size.width, height: geo.size.height * (inTrip ? 0.44 : 0.86))
            }
            .ignoresSafeArea()

            // Top bar stays inside the safe area (below the status bar / Dynamic Island).
            VStack(spacing: 0) {
                TopBar()
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                Spacer(minLength: 0)
            }

            // Search: respects the home indicator and keyboard, so it sits right above either.
            if !inTrip {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    SearchPanel().padding(.bottom, 8)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Agent panel: respects the home indicator and the keyboard, so iOS lifts it above
            // the keyboard. While typing it stretches up so the conversation stays visible.
            if inTrip {
                GeometryReader { geo in
                    VStack(spacing: 0) {
                        Color.clear
                            .frame(height: keyboardUp ? 62 : geo.size.height * 0.33)
                            .allowsHitTesting(false)
                        AgentSheet()
                    }
                }
                .transition(.move(edge: .bottom))
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) { keyboardUp = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) { keyboardUp = false }
        }
        .sheet(isPresented: $store.showOriginPicker) {
            OriginPicker()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Theme.surface)
                .presentationCornerRadius(28)
        }
        .sheet(isPresented: $store.showCalendar) {
            CalendarSheet()
                .presentationDetents([.height(610)])
                .presentationDragIndicator(.visible)
                .presentationBackground(Theme.surface)
                .presentationCornerRadius(28)
        }
    }
}

struct TopBar: View {
    @Environment(TripStore.self) private var store

    var body: some View {
        HStack(spacing: 10) {
            if store.dest != nil {
                Button { store.goHome() } label: { CircleIcon(systemName: "chevron.left") }
                    .accessibilityLabel("Back to globe")
            }

            Button { store.showOriginPicker = true } label: {
                HStack(spacing: 10) {
                    Circle().fill(Theme.sage).frame(width: 10, height: 10)
                        .overlay(Circle().stroke(Theme.sage.opacity(0.2), lineWidth: 8))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(store.originCaption.uppercased())
                            .font(.system(size: 11, weight: .medium)).tracking(0.8)
                            .foregroundStyle(Theme.muted)
                        Text(store.dest == nil ? store.originLabel : (store.origin?.code ?? ""))
                            .font(.display(15))
                            .foregroundStyle(Theme.text)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.muted)
                }
                .padding(.leading, 12).padding(.trailing, 14).padding(.vertical, 7)
                .frame(minHeight: 44)
                .glassPill()
            }
            .buttonStyle(.plain)
            .disabled(store.origin == nil)
            .accessibilityLabel("Starting airport: \(store.originLabel). Change")

            Spacer(minLength: 0)

            if let d = store.dest {
                VStack(alignment: .trailing, spacing: 1) {
                    Text("TO").font(.system(size: 11, weight: .medium)).tracking(0.8).foregroundStyle(Theme.muted)
                    Text(d.code).font(.display(15)).foregroundStyle(Theme.accentInk)
                }
                .padding(.horizontal, 14).padding(.vertical, 7)
                .frame(minHeight: 44)
                .background(Capsule().fill(Theme.surface.opacity(0.78)))
                .overlay(Capsule().strokeBorder(Theme.accent.opacity(0.45), lineWidth: 1))
            } else {
                NavigationLink(value: Route.trips) {
                    CircleIcon(systemName: "airplane")
                        .overlay(alignment: .topTrailing) {
                            Circle().fill(Theme.sage).frame(width: 7, height: 7).padding(9)
                        }
                }
                .accessibilityLabel("Trips — flight in progress")
                NavigationLink(value: Route.agent) {
                    CircleIcon(systemName: "sparkles", color: Theme.accentInk)
                }
                .accessibilityLabel("Chat with your trip agent")
            }
        }
    }
}
