//
//  StockDetailView.swift
//  PriceTracker
//
//  Detail screen showing individual stock information
//

import SwiftUI

/// A detailed view displaying comprehensive information about a single stock.
///
/// `StockDetailView` presents in-depth stock information including:
/// - Large, prominent price display
/// - Price change amount and percentage
/// - Last updated timestamp
/// - Company information and description
///
/// The view automatically tracks real-time price updates from the view model,
/// ensuring the displayed information stays current even while viewing the detail screen.
///
/// ## Topics
/// ### Properties
/// - ``stock``
/// - ``liveStock``
///
/// ### View Components
/// - ``priceCard``
/// - ``companyInfoSection``
///
/// ### Helper Properties
/// - ``changeIcon``
/// - ``changeColor``
/// - ``formattedTime``
struct StockDetailView: View {
    
    /// The view model managing the stock feed and live updates.
    ///
    /// This is injected through the SwiftUI environment to access live stock data.
    @EnvironmentObject var viewModel: StockFeedViewModel
    
    /// The stock to display details for.
    ///
    /// This represents the initial stock data used for navigation.
    let stock: Stock

    /// The live stock data with real-time updates.
    ///
    /// This computed property finds and returns the current stock data from the view model,
    /// ensuring the view displays up-to-date prices even as they change.
    ///
    /// - Returns: The live stock from the view model, or the original stock if not found.
    private var liveStock: Stock {
        viewModel.stocks.first(where: { $0.symbol == stock.symbol }) ?? stock
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Price Card
                priceCard

                // Company Info
                companyInfoSection

                Spacer()
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle(liveStock.symbol)
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Price Card

    /// A card displaying the current price and change information.
    ///
    /// This view presents the stock price in large, bold text with accompanying
    /// change indicators, percentage, and last updated timestamp.
    private var priceCard: some View {
        VStack(spacing: 16) {
            // Current Price
            HStack {
                Text("$\(liveStock.price, specifier: "%.2f")")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Spacer()
            }

            // Price Change
            HStack(spacing: 8) {
                Image(systemName: changeIcon)
                    .font(.title3)

                Text("$\(abs(liveStock.priceChange), specifier: "%.2f")")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("(\(abs(liveStock.priceChangePercentage), specifier: "%.2f")%)")
                    .font(.body)
                    .fontWeight(.medium)

                Spacer()

                Text("Today")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .foregroundColor(changeColor)

            // Last Updated
            HStack {
                Text("Last updated: \(formattedTime)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Company Info Section

    /// A section displaying company information and description.
    ///
    /// This view presents the company name and a detailed description
    /// of the company's business and operations.
    private var companyInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About")
                .font(.title2)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)

            VStack(alignment: .leading, spacing: 12) {
                InfoRow(title: "Company", value: liveStock.companyName)

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text(liveStock.description)
                        .font(.body)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Helpers

    /// The SF Symbol name for the price change indicator icon.
    ///
    /// - Returns: A filled circle with up arrow for increases, down arrow for decreases,
    ///   or minus symbol for no change.
    private var changeIcon: String {
        if liveStock.isIncreasing {
            return "arrow.up.circle.fill"
        } else if liveStock.isDecreasing {
            return "arrow.down.circle.fill"
        } else {
            return "minus.circle.fill"
        }
    }

    /// The color for price change indicators.
    ///
    /// - Returns: Green for increases, red for decreases, or secondary for no change.
    private var changeColor: Color {
        if liveStock.isIncreasing {
            return .green
        } else if liveStock.isDecreasing {
            return .red
        } else {
            return .secondary
        }
    }

    /// A formatted string representing the last update time.
    ///
    /// - Returns: A medium-style time string (e.g., "3:45:30 PM").
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: liveStock.lastUpdated)
    }
}

// MARK: - Info Row

/// A reusable row view displaying a title-value pair.
///
/// `InfoRow` presents information in a horizontal layout with a title on the left
/// and its corresponding value on the right. The value text supports multi-line
/// display with trailing alignment.
///
/// ## Topics
/// ### Properties
/// - ``title``
/// - ``value``
struct InfoRow: View {
    
    /// The title label for the information row.
    let title: String
    
    /// The value to display for this information row.
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Preview

/// SwiftUI preview provider for ``StockDetailView``.
struct StockDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            StockDetailView(stock: Stock.sampleStocks[0])
                .environmentObject(StockFeedViewModel())
        }
    }
}
