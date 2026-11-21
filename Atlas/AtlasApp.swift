import SwiftUI

@main
struct AtlasApp: App {
    @State private var state = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(state)
                .preferredColorScheme(.light)
        }
    }
}

struct RootView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        @Bindable var state = state
        NavigationStack(path: $state.path) {
            HomeView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .chat: ChatView()
                    case .results: ResultsView()
                    case .split: SplitTicketView()
                    case .fun: FunRouteView()
                    case .review: ReviewView()
                    case .booked: BookedView()
                    }
                }
        }
        .tint(Theme.ink)
        .sheet(isPresented: $state.showCalendar) {
            CalendarSheet()
                .environment(state)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
        }
        .overlay(alignment: .bottom) {
            if let toast = state.toast {
                Text(toast)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Theme.ink, in: Capsule())
                    .padding(.bottom, 110)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.25), value: state.toast)
    }
}
