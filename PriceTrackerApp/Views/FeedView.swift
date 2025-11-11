//
//  FeedView.swift
//  PriceTracker
//
//  Main feed screen displaying real-time stock prices
//

import SwiftUI

/// The main feed view displaying a list of stocks with real-time price updates.
///
/// `FeedView` presents a scrollable list of stock rows, each showing current prices,
/// price changes, and visual feedback for real-time updates. The view includes a
/// toolbar with connection status indicator and start/stop controls.
///
/// The view responds to real-time price updates from the view model and provides
/// visual feedback through flash animations when prices change. Users can tap
/// individual stock rows to navigate to detailed information.
///
/// ## Topics
/// ### View Composition
/// - ``stockList``
/// - ``connectionIndicator``
/// - ``toggleButton``
///
/// ### Helper Properties
/// - ``connectionColor``
/// - ``connectionText``
struct FeedView: View {
    
    /// The view model managing the stock feed state and updates.
    ///
    /// This view model is injected through the SwiftUI environment.
    @EnvironmentObject var viewModel: StockFeedViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                // Stock List
                stockList

                // Navigation destination
                NavigationLink(
                    destination: StockDetailView(stock: viewModel.selectedStock ?? Stock.sampleStocks[0]),
                    isActive: $viewModel.shouldNavigateToDetail
                ) {
                    EmptyView()
                }
                .hidden()
            }
            .navigationTitle("Stock Tracker")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    connectionIndicator
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    toggleButton
                }
            }
        }
    }

    // MARK: - Stock List

    /// The scrollable list of stock rows.
    ///
    /// This view presents stocks in a lazy vertical stack for efficient rendering
    /// of large lists. Each stock is displayed in a ``StockRowView`` with tap
    /// gesture support for navigation.
    private var stockList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.stocks) { stock in
                    Button(action: {
                        viewModel.selectStock(stock)
                    }) {
                        StockRowView(
                            stock: stock,
                            isFlashing: viewModel.isFlashing(stock.symbol)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }

    // MARK: - Top Bar Components

    /// The connection status indicator displayed in the leading toolbar position.
    ///
    /// Shows a colored circle and text label indicating the current WebSocket
    /// connection state (connected, disconnected, or connecting).
    private var connectionIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(connectionColor)
                .frame(width: 8, height: 8)

            Text(connectionStatusLabel)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .fixedSize()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(connectionStatusLabel)
    }

    /// The start/stop button displayed in the trailing toolbar position.
    ///
    /// Toggles the price feed on or off. The button changes color and label
    /// based on the current running state.
    private var toggleButton: some View {
        Button(action: {
            viewModel.toggleFeed()
        }) {
            Text(viewModel.isRunning ? "Stop" : "Start")
                .fontWeight(.semibold)
        }
        .buttonStyle(.borderedProminent)
        .tint(viewModel.isRunning ? .red : .green)
    }

    // MARK: - Helpers

    /// The color for the connection status indicator.
    ///
    /// - Returns: Green for connected, red for disconnected, or orange for connecting.
    private var connectionColor: Color {
        switch viewModel.connectionState {
        case .connected:
            return .green
        case .disconnected:
            return .red
        case .connecting:
            return .orange
        }
    }

    /// The text label for the connection status indicator.
    ///
    /// - Returns: A user-friendly status message matching the current connection state.
    private var connectionText: String {
        switch viewModel.connectionState {
        case .connected:
            return "Connected"
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting..."
        }
    }

    /// A compact status label for the connection indicator in the toolbar.
    ///
    /// - Returns: A short, single-word status that fits well in the navigation bar.
    private var connectionStatusLabel: String {
        switch viewModel.connectionState {
        case .connected:
            return "Live"
        case .disconnected:
            return "Offline"
        case .connecting:
            return "Connecting"
        }
    }
}

// MARK: - Stock Row View

/// A reusable view component displaying a single stock's information.
///
/// `StockRowView` presents stock information in a card-like format with:
/// - Stock symbol and company name on the left
/// - Current price and change information on the right
/// - Visual feedback through flash animations and color-coded price changes
/// - Directional arrows indicating price movement
///
/// The view automatically adapts its appearance based on whether the price
/// is increasing, decreasing, or unchanged, and can display a flash animation
/// when requested.
///
/// ## Topics
/// ### Properties
/// - ``stock``
/// - ``isFlashing``
///
/// ### Helper Properties
/// - ``changeIcon``
/// - ``changeColor``
/// - ``backgroundColor``
struct StockRowView: View {
    
    /// The stock to display.
    let stock: Stock
    
    /// A Boolean value indicating whether to show a flash animation.
    ///
    /// When `true`, the row displays a border and background tint matching
    /// the price change direction.
    let isFlashing: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Symbol
            VStack(alignment: .leading, spacing: 4) {
                Text(stock.symbol)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text(stock.companyName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Price & Change
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(stock.price, specifier: "%.2f")")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    Image(systemName: changeIcon)
                        .font(.caption)

                    Text("\(abs(stock.priceChange), specifier: "%.2f")")
                        .font(.caption)

                    Text("(\(abs(stock.priceChangePercentage), specifier: "%.2f")%)")
                        .font(.caption2)
                }
                .foregroundColor(changeColor)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isFlashing ? changeColor.opacity(0.5) : Color.clear, lineWidth: 2)
        )
        .animation(.easeInOut(duration: 0.3), value: isFlashing)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(stock.symbol) \(stock.companyName) $\(stock.price, specifier: "%.2f")")
    }

    // MARK: - Helper Properties
    
    /// The SF Symbol name for the price change indicator.
    ///
    /// - Returns: An up arrow for increases, down arrow for decreases,
    ///   or a minus symbol for no change.
    private var changeIcon: String {
        if stock.isIncreasing {
            return "arrow.up"
        } else if stock.isDecreasing {
            return "arrow.down"
        } else {
            return "minus"
        }
    }

    /// The color for price change indicators.
    ///
    /// - Returns: Green for increases, red for decreases, or secondary for no change.
    private var changeColor: Color {
        if stock.isIncreasing {
            return .green
        } else if stock.isDecreasing {
            return .red
        } else {
            return .secondary
        }
    }

    /// The background color for the stock row.
    ///
    /// When flashing, the background is tinted with the change color.
    /// Otherwise, it uses the standard grouped background color.
    ///
    /// - Returns: A tinted color when flashing; otherwise, the standard background.
    private var backgroundColor: Color {
        if isFlashing {
            return changeColor.opacity(0.15)
        } else {
            return Color(UIColor.secondarySystemGroupedBackground)
        }
    }
}

// MARK: - Preview

/// SwiftUI preview provider for ``FeedView``.
struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
            .environmentObject(StockFeedViewModel())
    }
}
