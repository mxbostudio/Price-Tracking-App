//
//  PriceGeneratorTests.swift
//  PriceTrackerTests
//
//  Unit tests for PriceGenerator
//

import XCTest
@testable import PriceTracker

/// Unit tests for the ``PriceGenerator`` class.
///
/// This test suite validates the behavior of the `PriceGenerator`, including:
/// - Proper initialization with a base price
/// - Price generation within defined bounds
/// - Price variation over time
/// - Correct rounding to 2 decimal places
///
/// The `PriceGenerator` is responsible for creating realistic price movements
/// for stocks, so these tests ensure the generated prices behave predictably
/// and stay within acceptable ranges.
///
/// ## Topics
/// ### Initialization Tests
/// - ``testPriceGeneratorInitialization()``
///
/// ### Price Behavior Tests
/// - ``testPriceStaysWithinBounds()``
/// - ``testPriceChangesOverTime()``
/// - ``testPriceRounding()``
final class PriceGeneratorTests: XCTestCase {

    // MARK: - Initialization Tests
    
    /// Tests that a price generator initializes and produces valid prices.
    ///
    /// Verifies that:
    /// - The generator can be created with a base price
    /// - The first generated price is greater than zero
    func testPriceGeneratorInitialization() {
        // Given
        let basePrice = 100.0

        // When
        let generator = PriceGenerator(basePrice: basePrice)
        let firstPrice = generator.generateNextPrice()

        // Then
        XCTAssertGreaterThan(firstPrice, 0)
    }

    // MARK: - Price Behavior Tests
    
    /// Tests that generated prices stay within the defined bounds.
    ///
    /// Verifies that across 100 price generations, all prices remain between
    /// 50% and 150% of the base price, as specified by the generator's algorithm.
    ///
    /// This ensures the price generator doesn't produce unrealistic price movements
    /// that could break the simulation.
    func testPriceStaysWithinBounds() {
        // Given
        let basePrice = 100.0
        let generator = PriceGenerator(basePrice: basePrice)
        let minPrice = basePrice * 0.5
        let maxPrice = basePrice * 1.5

        // When & Then
        for _ in 0..<100 {
            let price = generator.generateNextPrice()
            XCTAssertGreaterThanOrEqual(price, minPrice)
            XCTAssertLessThanOrEqual(price, maxPrice)
        }
    }
    
    /// Tests that prices vary over multiple generations.
    ///
    /// Verifies that the price generator produces different values over time
    /// rather than returning the same price repeatedly. This is crucial for
    /// simulating realistic market behavior.
    ///
    /// - Note: While statistically possible for three consecutive prices to be
    ///   identical due to randomness, it's extremely unlikely with 2% volatility.
    func testPriceChangesOverTime() {
        // Given
        let basePrice = 100.0
        let generator = PriceGenerator(basePrice: basePrice)

        // When
        let price1 = generator.generateNextPrice()
        let price2 = generator.generateNextPrice()
        let price3 = generator.generateNextPrice()

        // Then
        // At least one price should be different
        let allSame = (price1 == price2) && (price2 == price3)
        XCTAssertFalse(allSame, "Prices should vary over time")
    }
    
    /// Tests that generated prices are rounded to 2 decimal places.
    ///
    /// Verifies that prices conform to standard currency formatting with
    /// exactly 2 decimal places, as expected for USD pricing.
    ///
    /// This ensures consistency in price display throughout the application.
    func testPriceRounding() {
        // Given
        let basePrice = 100.0
        let generator = PriceGenerator(basePrice: basePrice)

        // When
        let price = generator.generateNextPrice()

        // Then
        // Check that price is rounded to 2 decimal places
        let rounded = round(price * 100) / 100
        XCTAssertEqual(price, rounded, accuracy: 0.001)
    }
}
