import SwiftUI

@main
struct OrbitApp: App {
    @State private var store = TripStore()
    @AppStorage("appearance") private var appearance: Appearance = .system

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .preferredColorScheme(appearance.colorScheme)
                .tint(Theme.accent)
        }
    }
}

struct RootView: View {
    @Environment(TripStore.self) private var store

    var body: some View {
        @Bindable var store = store
        NavigationStack(path: $store.path) {
            HomeView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .trips: TripsView()
                    case .agent: AgentChatView()
                    }
                }
        }
        .task {
            // Let the globe settle for a beat, then iOS shows its standard location alert.
            try? await Task.sleep(nanoseconds: 900_000_000)
            store.startLocation()
        }
    }
}
