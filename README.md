# Price Tracking App

Real‑time price tracker iOS coding challenge — a SwiftUI app that displays live price updates for multiple stock symbols and supports a symbol details screen via NavigationStack.

See full requirements: https://github.com/mxbostudio/Price-Tracking-App/blob/main/requirements.md

## Overview

This project demonstrates a SwiftUI-based stock price feed that:
- Tracks live price updates for 25+ symbols.
- Streams updates via a single WebSocket connection (echo server).
- Uses Combine for reactive data flow.
- Implements a feed screen and a symbol details screen using NavigationStack.
- Follows MVVM / unidirectional data flow with immutable UI state.

## Core Features

- Live price feed for at least 25 stock symbols (scrollable list).
- WebSocket echo integration (wss://ws.postman-echo.com/raw).
  - Every ~2 seconds per symbol: generate random price, send to WebSocket, receive echo, update UI.
- Feed screen:
  - List/LazyVStack of symbols, showing symbol, current price, and change indicator (green ↑ / red ↓).
  - Sorted by price (highest first).
  - Connection status indicator (🟢 / 🔴) on the left of the top bar.
  - Start / Stop toggle on the right of the top bar.
- Symbol details screen:
  - Title with symbol, current price with ↑/↓ indicator, and a simple description.

## Architecture & Technical Notes

- UI: 100% SwiftUI.
- Pattern: MVVM or Unidirectional Data Flow.
- Navigation: NavigationStack with two destinations:
  - Feed (root)
  - Symbol details
- Concurrency & Streams: Combine handles WebSocket streams and updates.
- State management:
  - ObservableObject and @Published for view models.
  - @StateObject / @ObservedObject for view lifecycle.
  - @EnvironmentObject or injected state for shared state between screens.
- WebSocket management:
  - Single WebSocket manager shared across the app to avoid duplicate connections.
  - Broadcasts updates to subscribers via Combine publishers.

## Bonus / Optional Enhancements

- Brief price flash animation (green/red for 1s on increase/decrease).
- Unit and SwiftUI UI tests for view models and UI flows.
- Light and dark themes support.
- Deep link: `stocks://symbol/{symbol}` to open a details view.

## Getting Started (development notes)

1. Open the Xcode workspace / project.
2. Ensure deployment target is set to iOS 15+ (NavigationStack and latest Combine features).
3. Build and run on simulator or device.
4. The app connects to the echo WebSocket to simulate a real-time feed. For local/offline development, a mock WebSocket provider can be used.

## Project Structure (suggested)

- App/
  - App entry (NavigationStack)
- Sources/
  - Models/ (Symbol, PriceUpdate)
  - Network/ (WebSocketManager, WebSocketProvider)
  - ViewModels/ (FeedViewModel, SymbolViewModel)
  - Views/ (FeedView, SymbolDetailView, Shared UI components)
- Tests/
  - Unit tests for view models and network layer
  - UI tests for navigation and feed behavior

## Running Tests

- Use Xcode Test action (Cmd+U) for unit and UI tests.
- Prefer deterministic mocks for networking in tests (inject a mock WebSocket provider).

## Contributing

Contributions, issues, and feature requests are welcome. Please follow common contribution practices:
- Fork the repo
- Create a feature branch
- Open a pull request with a clear description and incremental commits

## License

MIT — see LICENSE.md

## Author / Contact

MXBO STUDIO — https://github.com/mxbostudio
