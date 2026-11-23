# Orbit — iOS prototype

A native SwiftUI iPhone app: a dotted 3D globe that starts from your nearest airport, asks only
"Where to?", spins to the destination with a soft pulsing pin, and hands off to an AI trip agent for
Flights, Stays, Cars or Packages. Includes an optional range calendar, live trip tracking and an agent chat.

## Run it
1. On a Mac, open `Orbit.xcodeproj` in **Xcode 16 or later**.
2. Pick an iPhone simulator (e.g. iPhone 16) in the toolbar and press **Run** (⌘R).
3. The standard iOS location alert appears. In the Simulator, set a location with
   **Features → Location → Custom Location…** (or Apple, which resolves to SFO).
   Choosing *Don't Allow* falls back to a time-zone estimate. Tap the “From” pill anytime to change the starting airport.

### On your own iPhone
Select the **Orbit** target → *Signing & Capabilities* → choose your **Team** (a free Apple ID works),
change the bundle identifier if Xcode asks (e.g. `com.yourname.orbit`), plug in your phone and Run.

## Light & dark mode
Orbit follows the iPhone's Light/Dark setting. To override it, open **Trips** and use the appearance menu (top right): Match iPhone, Light or Dark. Light mode is the bright daylight look; dark mode is the dusk look. Both use the dotted globe.

## Requirements
- iOS 17+ (uses the Observation framework).
- No third-party packages; works offline.

## What's sample data
Flights, prices, hotels, cars ("Atlas Rent") and the agent's replies are generated locally so the
prototype runs without accounts. Swap these in `TripStore.swift` / `AgentChatView.swift`:
- `flights()`, `hotels`, `cars`, `extrasList` → real search APIs
- `instruct(_:)` and `AgentChatView.reply(to:)` → your LLM agent

## Files
| File | What it does |
|---|---|
| `OrbitApp.swift` | App entry, navigation, starts location after launch |
| `GlobeView.swift` | Canvas-rendered globe: land dots, route arc, zoom-to-route, soft pulse, drag to rotate |
| `LocationService.swift` | Standard iOS permission + nearest airport, time-zone fallback |
| `TripStore.swift` | App state and the rule-based agent flow |
| `HomeView.swift`, `SearchPanel.swift` | Globe home, top bar, mode pills, search, optional dates |
| `OriginPicker.swift` | Change the starting airport (tap the “From” pill) |
| `AgentSheet.swift` | Agent panel: steps, options, extras, review, booking |
| `CalendarSheet.swift` | Optional range calendar |
| `TripsView.swift` | Live flight tracking, agent updates, past trips |
| `AgentChatView.swift` | Full-screen chat with destination cards ("Plan it" flies the globe there) |
| `Airports.swift`, `LandMask.swift` | Airport list and the 1.5° Earth land mask (Natural Earth) |
