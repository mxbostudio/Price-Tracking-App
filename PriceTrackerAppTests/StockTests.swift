//
//  StockTests.swift
//  PriceTrackerTests
//
//  Unit tests for Stock model
//

import XCTest
@testable import PriceTracker

/// Unit tests for the ``Stock`` model.
///
/// This test suite validates the behavior of the `Stock` model, including:
/// - Initialization with correct default values
/// - Price update functionality
/// - Computed properties for price changes and percentages
/// - Price movement indicators (increasing/decreasing)
/// - Sample stock data integrity
///
/// ## Topics
/// ### Initialization Tests
/// - ``testStockInitialization()``
///
/// ### Price Update Tests
/// - ``testPriceUpdate()``
/// - ``testPriceChangePercentage()``
///
/// ### Price Movement Tests
/// - ``testIsIncreasing()``
/// - ``testIsDecreasing()``
///
/// ### Sample Data Tests
/// - ``testSampleStocksCount()``
/// - ``testSampleStocksAreUnique()``
final class StockTests: XCTestCase {

    // MARK: - Initialization Tests
    
    /// Tests that a stock is properly initialized with the correct values.
    ///
    /// Verifies that:
    /// - All provided properties are correctly assigned
    /// - The `previousPrice` is set equal to the initial `price`
    /// - The initial `priceChange` is 0.0 since no update has occurred
    func testStockInitialization() {
        // Given
        let symbol = "AAPL"
        let price = 150.0
        let companyName = "Apple Inc."
        let description = "Technology company"

        // When
        let stock = Stock(symbol: symbol, price: price, companyName: companyName, description: description)

        // Then
        XCTAssertEqual(stock.symbol, symbol)
        XCTAssertEqual(stock.price, price)
        XCTAssertEqual(stock.previousPrice, price)
        XCTAssertEqual(stock.companyName, companyName)
        XCTAssertEqual(stock.description, description)
        XCTAssertEqual(stock.priceChange, 0.0)
    }

    // MARK: - Price Update Tests
    
    /// Tests that updating a stock's price correctly stores the previous price.
    ///
    /// Verifies that:
    /// - The new price is correctly assigned
    /// - The previous price is preserved
    /// - The price change is calculated correctly
    func testPriceUpdate() {
        // Given
        var stock = Stock(symbol: "AAPL", price: 150.0, companyName: "Apple Inc.", description: "Tech")
        let newPrice = 155.0

        // When
        stock.updatePrice(newPrice)

        // Then
        XCTAssertEqual(stock.price, newPrice)
        XCTAssertEqual(stock.previousPrice, 150.0)
        XCTAssertEqual(stock.priceChange, 5.0)
    }
    
    /// Tests that the price change percentage is calculated correctly.
    ///
    /// Verifies that a 10% price increase from 100.0 to 110.0 results
    /// in a `priceChangePercentage` of 10.0.
    func testPriceChangePercentage() {
        // Given
        var stock = Stock(symbol: "AAPL", price: 100.0, companyName: "Apple Inc.", description: "Tech")

        // When
        stock.updatePrice(110.0)

        // Then
        XCTAssertEqual(stock.priceChangePercentage, 10.0, accuracy: 0.01)
    }

    // MARK: - Price Movement Tests
    
    /// Tests that the `isIncreasing` property correctly identifies price increases.
    ///
    /// Verifies that:
    /// - `isIncreasing` returns `true` when price goes up
    /// - `isDecreasing` returns `false` when price goes up
    func testIsIncreasing() {
        // Given
        var stock = Stock(symbol: "AAPL", price: 100.0, companyName: "Apple Inc.", description: "Tech")

        // When
        stock.updatePrice(105.0)

        // Then
        XCTAssertTrue(stock.isIncreasing)
        XCTAssertFalse(stock.isDecreasing)
    }
    
    /// Tests that the `isDecreasing` property correctly identifies price decreases.
    ///
    /// Verifies that:
    /// - `isDecreasing` returns `true` when price goes down
    /// - `isIncreasing` returns `false` when price goes down
    func testIsDecreasing() {
        // Given
        var stock = Stock(symbol: "AAPL", price: 100.0, companyName: "Apple Inc.", description: "Tech")

        // When
        stock.updatePrice(95.0)

        // Then
        XCTAssertTrue(stock.isDecreasing)
        XCTAssertFalse(stock.isIncreasing)
    }

    // MARK: - Sample Data Tests
    
    /// Tests that the sample stocks array contains the expected number of stocks.
    ///
    /// Verifies that exactly 25 sample stocks are provided for testing and previews.
    func testSampleStocksCount() {
        // Given & When
        let sampleStocks = Stock.sampleStocks

        // Then
        XCTAssertEqual(sampleStocks.count, 25, "Should have 25 sample stocks")
    }
    
    /// Tests that all sample stock symbols are unique.
    ///
    /// Verifies that there are no duplicate ticker symbols in the sample data,
    /// ensuring data integrity for testing and development purposes.
    func testSampleStocksAreUnique() {
        // Given & When
        let sampleStocks = Stock.sampleStocks
        let symbols = sampleStocks.map { $0.symbol }
        let uniqueSymbols = Set(symbols)

        // Then
        XCTAssertEqual(symbols.count, uniqueSymbols.count, "All stock symbols should be unique")
    }
}
