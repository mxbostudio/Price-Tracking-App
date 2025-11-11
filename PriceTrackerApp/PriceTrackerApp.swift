//
//  PriceTrackerApp.swift
//  PriceTracker
//
//  Real-Time Price Tracker App
//

import SwiftUI

/// The main entry point for the Price Tracker application.
///
/// `PriceTrackerApp` manages the application lifecycle and provides a centralized
/// view model for the stock feed. It also handles deep linking to allow navigation
/// directly to specific stock symbols.
///
/// ## Deep Link Support
/// The app supports the following URL scheme:
/// ```
/// stocks://symbol/{SYMBOL}
/// ```
/// Where `{SYMBOL}` is the stock ticker symbol (e.g., AAPL, GOOG).
///
/// ## Topics
/// ### App Structure
/// - ``feedViewModel``
/// - ``handleDeepLink(_:)``
@main
struct PriceTrackerApp: App {
    
    /// The shared view model that manages the stock feed and WebSocket connection.
    ///
    /// This view model is injected into the environment and shared across all views
    /// in the app, ensuring consistent state management and real-time updates.
    @StateObject private var feedViewModel = StockFeedViewModel()

    var body: some Scene {
        WindowGroup {
            FeedView()
                .environmentObject(feedViewModel)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }

    // MARK: - Deep Linking
    
    /// Handles incoming deep link URLs to navigate to specific stocks.
    ///
    /// This method validates the URL scheme and extracts the stock symbol,
    /// then delegates to the view model to handle the navigation.
    ///
    /// - Parameter url: The URL to process. Expected format: `stocks://symbol/{SYMBOL}`
    ///
    /// ## Example URLs
    /// - `stocks://symbol/AAPL` - Opens Apple Inc. stock detail
    /// - `stocks://symbol/TSLA` - Opens Tesla Inc. stock detail
    ///
    /// - Note: The symbol is automatically converted to uppercase for consistency.
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "stocks",
              url.host == "symbol",
              let symbol = url.pathComponents.dropFirst().first else {
            return
        }

        feedViewModel.handleDeepLink(symbol: symbol.uppercased())
    }
}
