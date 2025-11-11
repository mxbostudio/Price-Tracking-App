//
//  StockFeedViewModel.swift
//  PriceTracker
//
//  ViewModel managing the stock feed, WebSocket connection, and real-time updates
//

import Foundation
import Combine
import SwiftUI

/// The main view model for managing the stock feed and real-time price updates.
///
/// `StockFeedViewModel` serves as the central coordinator for the app, managing:
/// - A collection of stocks and their real-time prices
/// - WebSocket connection state and lifecycle
/// - Price update subscriptions and processing
/// - Visual feedback through flash animations
/// - Navigation to stock detail views
///
/// This view model is injected into the SwiftUI environment and shared across all views,
/// ensuring consistent state management throughout the app.
///
/// ## Topics
/// ### Stock Management
/// - ``stocks``
/// - ``selectedStock``
/// - ``selectStock(_:)``
///
/// ### Connection State
/// - ``connectionState``
/// - ``isRunning``
/// - ``toggleFeed()``
/// - ``startFeed()``
/// - ``stopFeed()``
///
/// ### Visual Feedback
/// - ``flashingStocks``
/// - ``isFlashing(_:)``
///
/// ### Navigation
/// - ``shouldNavigateToDetail``
/// - ``handleDeepLink(symbol:)``
///
/// ## Example Usage
/// ```swift
/// let viewModel = StockFeedViewModel()
/// viewModel.startFeed()
///
/// // Subscribe to stock changes
/// viewModel.$stocks
///     .sink { stocks in
///         print("Stock count: \(stocks.count)")
///     }
/// ```
class StockFeedViewModel: ObservableObject {
    
    /// The array of stocks currently being tracked.
    ///
    /// This array is automatically updated with real-time price changes from the WebSocket service.
    /// Stocks are ordered by most recently updated, with the latest update appearing at the top.
    /// When a stock receives a price update, it smoothly animates to the top of the list.
    @Published private(set) var stocks: [Stock] = []
    
    /// The current state of the WebSocket connection.
    ///
    /// Use this property to display connection status in the UI.
    @Published private(set) var connectionState: ConnectionState = .disconnected
    
    /// A Boolean value indicating whether the price feed is actively running.
    ///
    /// When `true`, the app is connected to the WebSocket and receiving price updates.
    @Published private(set) var isRunning: Bool = false
    
    /// The currently selected stock for detail view navigation.
    ///
    /// Set this property when the user taps a stock row to view its details.
    @Published var selectedStock: Stock?
    
    /// A Boolean value controlling navigation to the detail view.
    ///
    /// Set to `true` to trigger navigation to ``StockDetailView``.
    @Published var shouldNavigateToDetail: Bool = false
    
    /// A set of stock symbols that are currently showing flash animations.
    ///
    /// When a stock's price changes, its symbol is added to this set for 1 second
    /// to trigger a visual flash effect in the UI.
    @Published private(set) var flashingStocks: Set<String> = []

    /// The WebSocket service managing the connection and price updates.
    private let webSocketService = WebSocketService()
    
    /// Storage for Combine subscriptions.
    private var cancellables = Set<AnyCancellable>()
    
    /// Price generators for each stock, providing realistic price movements.
    private var priceGenerators: [String: PriceGenerator] = [:]

    /// Creates a new stock feed view model.
    ///
    /// The initializer sets up the stock list with sample data and configures
    /// subscriptions to the WebSocket service.
    init() {
        setupStocks()
        setupWebSocketSubscriptions()
    }

    // MARK: - Setup

    /// Initializes the stock list with sample data and creates price generators.
    ///
    /// This method loads the sample stocks and creates a ``PriceGenerator`` for each one
    /// to ensure realistic price movements over time.
    private func setupStocks() {
        stocks = Stock.sampleStocks

        // Create price generators for each stock with their initial price
        for stock in stocks {
            priceGenerators[stock.symbol] = PriceGenerator(basePrice: stock.price)
        }
    }

    /// Sets up Combine subscriptions to the WebSocket service.
    ///
    /// This method subscribes to connection state changes and price updates from
    /// the WebSocket service, ensuring the view model stays in sync with the service.
    private func setupWebSocketSubscriptions() {
        // Subscribe to connection state changes
        webSocketService.$connectionState
            .receive(on: DispatchQueue.main)
            .assign(to: &$connectionState)

        // Subscribe to price updates
        webSocketService.priceUpdatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] priceUpdate in
                self?.handlePriceUpdate(priceUpdate)
            }
            .store(in: &cancellables)
    }

    // MARK: - Connection Control

    /// Toggles the price feed on or off.
    ///
    /// If the feed is currently running, this method stops it.
    /// If the feed is stopped, this method starts it.
    func toggleFeed() {
        if isRunning {
            stopFeed()
        } else {
            startFeed()
        }
    }

    /// Starts the price feed by connecting to the WebSocket service.
    ///
    /// This method initiates the WebSocket connection with all tracked stock symbols
    /// and begins receiving real-time price updates after a brief connection delay.
    ///
    /// - Note: If the feed is already running, this method returns without action.
    func startFeed() {
        guard !isRunning else { return }

        let symbols = stocks.map { $0.symbol }
        webSocketService.connect(symbols: symbols)

        // Wait for connection before starting updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            if self?.connectionState == .connected {
                self?.webSocketService.startPriceUpdates()
                self?.isRunning = true
            }
        }
    }

    /// Stops the price feed and disconnects from the WebSocket service.
    ///
    /// This method stops receiving price updates and closes the WebSocket connection.
    ///
    /// - Note: If the feed is not running, this method returns without action.
    func stopFeed() {
        guard isRunning else { return }

        webSocketService.stopPriceUpdates()
        webSocketService.disconnect()
        isRunning = false
    }

    // MARK: - Price Update Handling

    /// Processes an incoming price update from the WebSocket service.
    ///
    /// This method updates the corresponding stock's price using its price generator
    /// for realistic movement, triggers a flash animation, and moves the updated stock
    /// to the top of the list with a smooth animation.
    ///
    /// The stock is moved to the top (index 0) to make it immediately visible,
    /// helping users notice which stocks are actively updating.
    ///
    /// - Parameter priceUpdate: The price update received from the WebSocket.
    ///
    /// - Note: All updates happen on the main thread via Combine's `receive(on:)`,
    ///         ensuring thread safety and preventing race conditions.
    private func handlePriceUpdate(_ priceUpdate: PriceUpdate) {
        guard let index = stocks.firstIndex(where: { $0.symbol == priceUpdate.symbol }) else {
            return
        }

        var stock = stocks[index]

        // Generate a realistic price change instead of using completely random prices
        if let generator = priceGenerators[stock.symbol] {
            let newPrice = generator.generateNextPrice()
            stock.updatePrice(newPrice)
        } else {
            stock.updatePrice(priceUpdate.price)
        }

        // Move the updated stock to the top of the list with animation
        // This makes the update immediately visible and provides visual feedback
        withAnimation(.easeInOut(duration: 0.5)) {
            stocks.remove(at: index)
            stocks.insert(stock, at: 0)
        }

        // Trigger flash animation
        triggerFlash(for: stock.symbol)
    }

    // MARK: - Flash Animation

    /// Triggers a flash animation for the specified stock symbol.
    ///
    /// The stock symbol is added to ``flashingStocks`` and automatically removed
    /// after 1 second, creating a brief visual flash effect in the UI.
    ///
    /// - Parameter symbol: The ticker symbol of the stock to flash.
    private func triggerFlash(for symbol: String) {
        flashingStocks.insert(symbol)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.flashingStocks.remove(symbol)
        }
    }

    /// Returns whether a stock is currently displaying a flash animation.
    ///
    /// - Parameter symbol: The ticker symbol to check.
    /// - Returns: `true` if the stock is currently flashing; otherwise, `false`.
    func isFlashing(_ symbol: String) -> Bool {
        flashingStocks.contains(symbol)
    }

    // MARK: - Navigation

    /// Selects a stock and triggers navigation to its detail view.
    ///
    /// - Parameter stock: The stock to select and display in detail.
    func selectStock(_ stock: Stock) {
        selectedStock = stock
        shouldNavigateToDetail = true
    }

    // MARK: - Deep Linking

    /// Handles a deep link by navigating to the specified stock symbol.
    ///
    /// This method searches for a stock matching the provided symbol and,
    /// if found, selects it to trigger navigation to the detail view.
    ///
    /// - Parameter symbol: The ticker symbol from the deep link (e.g., "AAPL").
    func handleDeepLink(symbol: String) {
        if let stock = stocks.first(where: { $0.symbol == symbol }) {
            selectStock(stock)
        }
    }

    // MARK: - Cleanup

    /// Cleans up resources when the view model is deallocated.
    ///
    /// This ensures the price feed is stopped and the WebSocket connection is closed.
    deinit {
        stopFeed()
    }
}

// MARK: - Price Generator

/// Generates realistic price changes for a stock over time.
///
/// `PriceGenerator` simulates realistic stock price movements by generating
/// small percentage-based changes from the current price. It ensures prices
/// stay within reasonable bounds relative to the base price, preventing
/// unrealistic price swings.
///
/// The generator uses a configurable volatility factor to determine the
/// maximum percentage change per update, creating smooth and believable
/// price movements.
///
/// ## Topics
/// ### Configuration
/// - ``basePrice``
/// - ``volatility``
///
/// ### Price Generation
/// - ``generateNextPrice()``
///
/// ## Example
/// ```swift
/// let generator = PriceGenerator(basePrice: 150.0)
/// let newPrice = generator.generateNextPrice()
/// print("New price: $\(newPrice)")
/// ```
class PriceGenerator {
    
    /// The original base price used as a reference point.
    ///
    /// This value is used to calculate the allowed price range (50% to 150% of base price).
    private let basePrice: Double
    
    /// The current price, which evolves with each call to ``generateNextPrice()``.
    private var currentPrice: Double
    
    /// The volatility factor determining the maximum percentage change per update.
    ///
    /// A value of 0.02 represents 2% volatility, meaning prices can change
    /// by up to ±2% with each update.
    private let volatility: Double = 0.02 // 2% volatility

    /// Creates a new price generator with the specified base price.
    ///
    /// - Parameter basePrice: The initial price to use as a starting point and reference.
    init(basePrice: Double) {
        self.basePrice = basePrice
        self.currentPrice = basePrice
    }

    /// Generates the next price value based on the current price and volatility.
    ///
    /// This method applies a random percentage change to the current price,
    /// clamping the result to stay within 50% to 150% of the base price.
    /// The resulting price is rounded to 2 decimal places.
    ///
    /// - Returns: A new price value that differs from the current price by up to ±2%.
    ///
    /// ## Price Movement
    /// - Each update applies a random change between -2% and +2% of the current price
    /// - Prices are constrained to remain between 50% and 150% of the base price
    /// - Results are rounded to 2 decimal places for currency formatting
    func generateNextPrice() -> Double {
        // Generate a random percentage change between -2% and +2%
        let percentageChange = Double.random(in: -volatility...volatility)
        let change = currentPrice * percentageChange

        // Update current price
        currentPrice += change

        // Keep price within reasonable bounds (50% to 150% of base price)
        let minPrice = basePrice * 0.5
        let maxPrice = basePrice * 1.5

        currentPrice = max(minPrice, min(maxPrice, currentPrice))

        // Round to 2 decimal places
        return round(currentPrice * 100) / 100
    }
}
