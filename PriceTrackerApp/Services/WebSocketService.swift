//
//  WebSocketService.swift
//  PriceTracker
//
//  WebSocket service for real-time price updates using Combine
//

import Foundation
import Combine

/// Represents the current state of the WebSocket connection.
///
/// Use this enumeration to track and respond to connection state changes
/// in the user interface.
enum ConnectionState {
    /// The WebSocket connection is active and ready to send/receive data.
    case connected
    
    /// The WebSocket connection is closed or not yet established.
    case disconnected
    
    /// The WebSocket is in the process of establishing a connection.
    case connecting
}

/// A structure representing a stock price update received from the WebSocket.
///
/// Price updates are sent and received as JSON-encoded messages through the
/// WebSocket connection. Each update includes the stock symbol, new price,
/// and timestamp of when the update was generated.
struct PriceUpdate: Codable {
    /// The ticker symbol for the stock (e.g., "AAPL", "GOOG").
    let symbol: String
    
    /// The new price value in USD.
    let price: Double
    
    /// The timestamp when this price update was generated.
    let timestamp: Date
}

/// A service that manages WebSocket connections for real-time stock price updates.
///
/// `WebSocketService` handles the lifecycle of a WebSocket connection, including
/// connecting, disconnecting, sending price updates, and receiving echoed messages.
/// It uses Combine to publish price updates and connection state changes to subscribers.
///
/// The service connects to a WebSocket echo server and simulates real-time price
/// updates by sending periodic messages that are echoed back.
///
/// ## Topics
/// ### Connection State
/// - ``connectionState``
/// - ``lastError``
/// - ``connect(symbols:)``
/// - ``disconnect()``
///
/// ### Price Updates
/// - ``priceUpdatePublisher``
/// - ``startPriceUpdates()``
/// - ``stopPriceUpdates()``
///
/// ### Example Usage
/// ```swift
/// let service = WebSocketService()
/// service.connect(symbols: ["AAPL", "GOOG", "MSFT"])
/// service.startPriceUpdates()
///
/// // Subscribe to updates
/// service.priceUpdatePublisher
///     .sink { priceUpdate in
///         print("Received update for \(priceUpdate.symbol): $\(priceUpdate.price)")
///     }
///     .store(in: &cancellables)
/// ```
class WebSocketService: NSObject, ObservableObject {
    
    /// The current state of the WebSocket connection.
    ///
    /// Observe this property to update UI elements based on connection status.
    @Published private(set) var connectionState: ConnectionState = .disconnected
    
    /// The most recent error message, if any.
    ///
    /// This property is set when connection or communication errors occur.
    /// It's cleared when a successful connection is established.
    @Published private(set) var lastError: String?

    /// The active WebSocket task managing the connection.
    private var webSocketTask: URLSessionWebSocketTask?
    
    /// Timer used to periodically generate and send price updates.
    private var updateTimer: Timer?
    
    /// The list of stock symbols being tracked.
    private var symbols: [String] = []
    
    /// Storage for Combine subscriptions.
    private var cancellables = Set<AnyCancellable>()

    /// A publisher that emits price updates as they are received.
    ///
    /// Subscribe to this publisher to receive real-time price updates for tracked stocks.
    /// Updates are published on the main queue.
    let priceUpdatePublisher = PassthroughSubject<PriceUpdate, Never>()

    /// The WebSocket server URL.
    ///
    /// Currently configured to use Postman's echo server for testing purposes.
    private let webSocketURL = URL(string: "wss://ws.postman-echo.com/raw")!

    // MARK: - Connection Management

    /// Establishes a WebSocket connection for the specified stock symbols.
    ///
    /// This method creates a new WebSocket task and begins the connection process.
    /// Once connected, you can call ``startPriceUpdates()`` to begin receiving
    /// simulated price updates.
    ///
    /// - Parameter symbols: An array of stock ticker symbols to track (e.g., ["AAPL", "GOOG"]).
    ///
    /// - Note: If already connected or connecting, this method returns without action.
    func connect(symbols: [String]) {
        guard connectionState != .connected && connectionState != .connecting else { return }

        self.symbols = symbols
        connectionState = .connecting

        let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        webSocketTask = session.webSocketTask(with: webSocketURL)
        webSocketTask?.resume()

        receiveMessage()
    }

    /// Closes the WebSocket connection and stops all price updates.
    ///
    /// This method gracefully closes the WebSocket connection, stops the update timer,
    /// and updates the connection state to disconnected.
    func disconnect() {
        stopPriceUpdates()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        connectionState = .disconnected
    }

    // MARK: - Price Updates

    /// Starts generating and sending periodic price updates.
    ///
    /// This method creates a timer that sends simulated price updates every 2 seconds.
    /// The updates are sent through the WebSocket and echoed back, then published
    /// via ``priceUpdatePublisher``.
    ///
    /// - Important: The connection must be in the ``ConnectionState/connected`` state
    ///   before calling this method.
    func startPriceUpdates() {
        guard connectionState == .connected else { return }

        stopPriceUpdates()

        // Send price updates every 2 seconds
        updateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.sendRandomPriceUpdate()
        }

        // Send initial update immediately
        sendRandomPriceUpdate()
    }

    /// Stops the automatic generation of price updates.
    ///
    /// Call this method to pause price updates without disconnecting from the WebSocket.
    func stopPriceUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    /// Generates and sends a random price update through the WebSocket.
    ///
    /// This method selects a random stock symbol and generates a random price,
    /// then encodes it as JSON and sends it through the WebSocket connection.
    private func sendRandomPriceUpdate() {
        guard connectionState == .connected, !symbols.isEmpty else { return }

        // Pick a random symbol
        let symbol = symbols.randomElement()!

        // Generate random price between $10 and $1000
        let basePrice = Double.random(in: 10...1000)
        let price = round(basePrice * 100) / 100

        let priceUpdate = PriceUpdate(symbol: symbol, price: price, timestamp: Date())

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(priceUpdate)

            if let jsonString = String(data: data, encoding: .utf8) {
                let message = URLSessionWebSocketTask.Message.string(jsonString)
                webSocketTask?.send(message) { [weak self] error in
                    if let error = error {
                        print("WebSocket send error: \(error.localizedDescription)")
                        self?.lastError = error.localizedDescription
                    }
                }
            }
        } catch {
            print("Encoding error: \(error.localizedDescription)")
            lastError = error.localizedDescription
        }
    }

    // MARK: - Receive Messages

    /// Begins listening for incoming WebSocket messages.
    ///
    /// This method sets up a continuous listening loop that processes messages
    /// as they arrive and automatically calls itself recursively to continue listening.
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message)
                self?.receiveMessage() // Continue listening
            case .failure(let error):
                print("WebSocket receive error: \(error.localizedDescription)")
                self?.lastError = error.localizedDescription
                self?.connectionState = .disconnected
            }
        }
    }

    /// Processes an incoming WebSocket message.
    ///
    /// This method decodes JSON messages into ``PriceUpdate`` instances and
    /// publishes them through ``priceUpdatePublisher``.
    ///
    /// - Parameter message: The WebSocket message to process.
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            // Decode the echoed message
            guard let data = text.data(using: .utf8) else { return }

            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let priceUpdate = try decoder.decode(PriceUpdate.self, from: data)

                // Publish the price update
                DispatchQueue.main.async {
                    self.priceUpdatePublisher.send(priceUpdate)
                }
            } catch {
                print("Decoding error: \(error.localizedDescription)")
            }

        case .data(let data):
            print("Received binary data: \(data.count) bytes")

        @unknown default:
            break
        }
    }
}

// MARK: - URLSessionWebSocketDelegate

/// Extension conforming to `URLSessionWebSocketDelegate` to handle connection lifecycle events.
extension WebSocketService: URLSessionWebSocketDelegate {
    
    /// Called when the WebSocket connection is successfully established.
    ///
    /// - Parameters:
    ///   - session: The URL session managing the WebSocket.
    ///   - webSocketTask: The WebSocket task that opened.
    ///   - protocol: The negotiated WebSocket sub-protocol, if any.
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        DispatchQueue.main.async {
            self.connectionState = .connected
            self.lastError = nil
            print("WebSocket connected")
        }
    }

    /// Called when the WebSocket connection is closed.
    ///
    /// - Parameters:
    ///   - session: The URL session managing the WebSocket.
    ///   - webSocketTask: The WebSocket task that closed.
    ///   - closeCode: The code indicating why the connection closed.
    ///   - reason: Additional data providing context for the closure, if available.
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        DispatchQueue.main.async {
            self.connectionState = .disconnected
            print("WebSocket disconnected")
        }
    }

    /// Called when a task completes, either successfully or with an error.
    ///
    /// - Parameters:
    ///   - session: The URL session managing the task.
    ///   - task: The task that completed.
    ///   - error: An error object indicating why the task failed, or `nil` if successful.
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.connectionState = .disconnected
                self.lastError = error.localizedDescription
                print("WebSocket error: \(error.localizedDescription)")
            }
        }
    }
}
