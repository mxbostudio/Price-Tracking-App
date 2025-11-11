//
//  Stock.swift
//  PriceTracker
//
//  Model representing a stock with real-time price data
//

import Foundation

/// A model representing a stock security with real-time pricing information.
///
/// `Stock` encapsulates all the information needed to display and track a stock,
/// including its current price, historical price data, and company information.
/// The model automatically calculates price changes and percentage changes based
/// on the current and previous prices.
///
/// ## Topics
/// ### Identifiers
/// - ``id``
/// - ``symbol``
///
/// ### Pricing Information
/// - ``price``
/// - ``previousPrice``
/// - ``lastUpdated``
/// - ``updatePrice(_:)``
///
/// ### Price Analysis
/// - ``priceChange``
/// - ``priceChangePercentage``
/// - ``isIncreasing``
/// - ``isDecreasing``
///
/// ### Company Information
/// - ``companyName``
/// - ``description``
struct Stock: Identifiable, Codable {
    
    /// A unique identifier for the stock.
    let id: UUID
    
    /// The ticker symbol for the stock (e.g., "AAPL", "GOOG").
    let symbol: String
    
    /// The current price of the stock in USD.
    var price: Double
    
    /// The previous price of the stock before the last update.
    ///
    /// This value is used to calculate price changes and determine price movement direction.
    var previousPrice: Double
    
    /// The timestamp of the last price update.
    var lastUpdated: Date
    
    /// The full company name (e.g., "Apple Inc.").
    let companyName: String
    
    /// A description of the company's business and operations.
    let description: String

    // MARK: - Computed Properties
    
    /// The absolute price change since the previous update.
    ///
    /// - Returns: A positive value if the price increased, negative if it decreased,
    ///   or zero if the price remained unchanged.
    var priceChange: Double {
        price - previousPrice
    }

    /// The percentage change in price since the previous update.
    ///
    /// - Returns: The percentage change as a value between -100 and potentially unlimited positive values.
    ///   Returns 0 if the previous price was 0 to avoid division by zero.
    var priceChangePercentage: Double {
        guard previousPrice > 0 else { return 0 }
        return (priceChange / previousPrice) * 100
    }

    /// A Boolean value indicating whether the stock price has increased.
    ///
    /// - Returns: `true` if the current price is higher than the previous price; otherwise, `false`.
    var isIncreasing: Bool {
        price > previousPrice
    }

    /// A Boolean value indicating whether the stock price has decreased.
    ///
    /// - Returns: `true` if the current price is lower than the previous price; otherwise, `false`.
    var isDecreasing: Bool {
        price < previousPrice
    }

    // MARK: - Initialization
    
    /// Creates a new stock with the specified information.
    ///
    /// - Parameters:
    ///   - symbol: The ticker symbol for the stock (e.g., "AAPL").
    ///   - price: The initial price of the stock in USD.
    ///   - companyName: The full name of the company.
    ///   - description: A description of the company's business.
    ///
    /// - Note: The `previousPrice` is automatically set to match the initial `price`,
    ///   and `lastUpdated` is set to the current date and time.
    init(symbol: String, price: Double, companyName: String, description: String) {
        self.id = UUID()
        self.symbol = symbol
        self.price = price
        self.previousPrice = price
        self.lastUpdated = Date()
        self.companyName = companyName
        self.description = description
    }

    // MARK: - Price Updates
    
    /// Updates the stock price with a new value.
    ///
    /// This method stores the current price as the previous price before updating
    /// to the new price, allowing for price change calculations. The `lastUpdated`
    /// timestamp is also refreshed.
    ///
    /// - Parameter newPrice: The new price value in USD.
    ///
    /// ## Example
    /// ```swift
    /// var stock = Stock(symbol: "AAPL", price: 150.0, companyName: "Apple Inc.", description: "...")
    /// stock.updatePrice(155.0)
    /// print(stock.priceChange) // Prints: 5.0
    /// ```
    mutating func updatePrice(_ newPrice: Double) {
        self.previousPrice = self.price
        self.price = newPrice
        self.lastUpdated = Date()
    }
}

// MARK: - Sample Stock Data

/// An extension providing sample stock data for testing and previews.
extension Stock {
    
    /// A collection of sample stocks representing major companies.
    ///
    /// This array contains pre-configured stock instances for 25 major companies
    /// across various sectors, including technology, finance, retail, and healthcare.
    /// The sample data is useful for testing, SwiftUI previews, and development purposes.
    ///
    /// - Note: The prices in this sample data are static and for demonstration purposes only.
    ///   Real-time prices are provided through the WebSocket service during runtime.
    static let sampleStocks: [Stock] = [
        Stock(symbol: "AAPL", price: 178.50, companyName: "Apple Inc.", description: "Apple Inc. designs, manufactures, and markets smartphones, personal computers, tablets, wearables, and accessories worldwide."),
        Stock(symbol: "GOOG", price: 140.25, companyName: "Alphabet Inc.", description: "Alphabet Inc. offers various products and platforms in the United States, Europe, the Middle East, Africa, the Asia-Pacific, Canada, and Latin America."),
        Stock(symbol: "MSFT", price: 378.90, companyName: "Microsoft Corporation", description: "Microsoft Corporation develops, licenses, and supports software, services, devices, and solutions worldwide."),
        Stock(symbol: "AMZN", price: 145.80, companyName: "Amazon.com Inc.", description: "Amazon.com, Inc. engages in the retail sale of consumer products and subscriptions in North America and internationally."),
        Stock(symbol: "TSLA", price: 242.15, companyName: "Tesla Inc.", description: "Tesla, Inc. designs, develops, manufactures, leases, and sells electric vehicles, and energy generation and storage systems."),
        Stock(symbol: "NVDA", price: 495.20, companyName: "NVIDIA Corporation", description: "NVIDIA Corporation provides graphics, and compute and networking solutions in the United States, Taiwan, China, and internationally."),
        Stock(symbol: "META", price: 325.40, companyName: "Meta Platforms Inc.", description: "Meta Platforms, Inc. engages in the development of products that enable people to connect and share with friends and family through mobile devices."),
        Stock(symbol: "BRK.B", price: 362.75, companyName: "Berkshire Hathaway Inc.", description: "Berkshire Hathaway Inc., through its subsidiaries, engages in the insurance, freight rail transportation, and utility businesses worldwide."),
        Stock(symbol: "JPM", price: 155.30, companyName: "JPMorgan Chase & Co.", description: "JPMorgan Chase & Co. operates as a financial services company worldwide."),
        Stock(symbol: "V", price: 265.85, companyName: "Visa Inc.", description: "Visa Inc. operates as a payments technology company worldwide."),
        Stock(symbol: "JNJ", price: 156.90, companyName: "Johnson & Johnson", description: "Johnson & Johnson researches, develops, manufactures, and sells various products in the healthcare field worldwide."),
        Stock(symbol: "WMT", price: 168.20, companyName: "Walmart Inc.", description: "Walmart Inc. engages in the operation of retail, wholesale, and other units worldwide."),
        Stock(symbol: "PG", price: 162.45, companyName: "Procter & Gamble Co.", description: "The Procter & Gamble Company provides branded consumer packaged goods to consumers in North America, Europe, the Asia Pacific, Greater China, Latin America, India, the Middle East, and Africa."),
        Stock(symbol: "MA", price: 425.60, companyName: "Mastercard Inc.", description: "Mastercard Incorporated, a technology company, provides transaction processing and other payment-related products and services in the United States and internationally."),
        Stock(symbol: "NFLX", price: 485.75, companyName: "Netflix Inc.", description: "Netflix, Inc. provides entertainment services. It offers TV series, films, and games across various genres and languages."),
        Stock(symbol: "DIS", price: 95.30, companyName: "Walt Disney Co.", description: "The Walt Disney Company operates as an entertainment company worldwide."),
        Stock(symbol: "PYPL", price: 62.45, companyName: "PayPal Holdings Inc.", description: "PayPal Holdings, Inc. operates a technology platform that enables digital payments on behalf of merchants and consumers worldwide."),
        Stock(symbol: "INTC", price: 43.80, companyName: "Intel Corporation", description: "Intel Corporation engages in the design, manufacture, and sale of computer products and technologies worldwide."),
        Stock(symbol: "CSCO", price: 51.25, companyName: "Cisco Systems Inc.", description: "Cisco Systems, Inc. designs, manufactures, and sells Internet Protocol based networking and other products related to the communications and information technology industry."),
        Stock(symbol: "AMD", price: 115.90, companyName: "Advanced Micro Devices Inc.", description: "Advanced Micro Devices, Inc. operates as a semiconductor company worldwide."),
        Stock(symbol: "CRM", price: 220.35, companyName: "Salesforce Inc.", description: "Salesforce, Inc. provides Customer Relationship Management (CRM) technology that brings companies and customers together worldwide."),
        Stock(symbol: "ORCL", price: 118.75, companyName: "Oracle Corporation", description: "Oracle Corporation offers products and services that address enterprise information technology environments worldwide."),
        Stock(symbol: "ADBE", price: 545.80, companyName: "Adobe Inc.", description: "Adobe Inc. operates as a diversified software company worldwide."),
        Stock(symbol: "NKE", price: 108.65, companyName: "Nike Inc.", description: "NIKE, Inc., together with its subsidiaries, designs, develops, markets, and sells athletic footwear, apparel, equipment, accessories, and services worldwide."),
        Stock(symbol: "COST", price: 635.90, companyName: "Costco Wholesale Corporation", description: "Costco Wholesale Corporation, together with its subsidiaries, engages in the operation of membership warehouses in the United States, Puerto Rico, Canada, the United Kingdom, Mexico, Japan, Korea, Australia, Spain, France, Iceland, China, and Taiwan.")
    ]
}
