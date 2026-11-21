# Atlas — agentic travel app (SwiftUI prototype)

A working iOS prototype of Atlas: plan trips by chatting with an agent, or pick dates on an optional calendar that hands its dates back to the agent.

## Run it

1. Requires **Xcode 16 or later** and an **iOS 17+** simulator or device.
2. Open `Atlas.xcodeproj`.
3. Pick an iPhone simulator and press **Run** (⌘R).
4. To run on your own iPhone: select the **Atlas** target → *Signing & Capabilities* → choose your Team, and change the bundle identifier (`com.example.atlas`) to one you own.

## Flow

| Screen | File | What works |
|---|---|---|
| Home | `HomeView.swift` | Type a trip, **Pick dates** (calendar sheet), **I'm flexible**, ideas, price-drop shortcut, upcoming trip after booking |
| Atlas chat | `ChatView.swift` | Live planning steps, parsed constraints, follow-ups ("cheaper?", "add a bag", "morning", "stopover"), quick replies, calendar button in the chat bar |
| Calendar sheet | `CalendarSheet.swift` | Ask Atlas ↔ Calendar switch, month paging, range selection, fares per day, Atlas date tip with Apply, exact / ±1 / ±3 days, sends dates back into the chat |
| Results | `ResultsView.swift` | Filters (best, cheapest, shortest legs, fun), cards open details, chat bar |
| Split ticket | `DetailViews.swift` | Two tickets, self-transfer note, Atlas Protect toggle |
| Fun route | `DetailViews.swift` | Route map, stopover picker, hotel offer |
| Review & book | `ReviewView.swift` | Autopilot toggles, slide to book (with haptic), confirmation |

`AppState.swift` holds all state and the scripted agent logic. `Theme.swift` holds the red & gold palette: change the values there to re-theme the app.

## Notes

- Fares, airlines and times are sample data generated per date; nothing is booked or charged.
- Atlas's replies are keyword-scripted. Swap `AppState.reply(to:)` for a call to your model or backend to make it real.
- Voice input shows a placeholder message.
