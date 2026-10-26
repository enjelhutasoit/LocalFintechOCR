//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import LocalFintechOCRCore

final class CardNetworkRuleTests: XCTestCase {

    // MARK: - BINRange

    func testMatchesInclusiveBoundaries() {
        let range = BINRange(digitCount: 2, range: 51...55)
        XCTAssertTrue(range.matches("5100000000000000"))
        XCTAssertTrue(range.matches("5500000000000000"))
        XCTAssertFalse(range.matches("5000000000000000"))
        XCTAssertFalse(range.matches("5600000000000000"))
    }

    func testSingleDigitAndFourDigitPrefixes() {
        XCTAssertTrue(BINRange(digitCount: 1, range: 4...4).matches("4111"))
        XCTAssertFalse(BINRange(digitCount: 1, range: 4...4).matches("5111"))
        XCTAssertTrue(BINRange(digitCount: 4, range: 2221...2720).matches("2221000000000000"))
        XCTAssertFalse(BINRange(digitCount: 4, range: 2221...2720).matches("2220000000000000"))
    }

    func testNeverMatchesWhenPrefixLengthIsUnsafe() {
        XCTAssertFalse(BINRange(digitCount: 0, range: 0...9).matches("4111111111111111"))
        XCTAssertFalse(BINRange(digitCount: -1, range: 0...9).matches("4111111111111111"))
        XCTAssertFalse(BINRange(digitCount: 10, range: 0...9_999_999_999).matches("4111111111111111"))
    }

    func testNeverMatchesWhenInputIsShorterThanPrefix() {
        XCTAssertFalse(BINRange(digitCount: 4, range: 0...9999).matches("411"))
        XCTAssertFalse(BINRange(digitCount: 1, range: 0...9).matches(""))
    }

    // MARK: - Default rules invariants

    func testDefaultRulesCoverEverySupportedNetworkExactlyOnce() {
        let networks = CardNetworkRule.defaults.map(\.network)
        XCTAssertEqual(Set(networks), [.visa, .mastercard, .jcb, .unionPay, .gpn])
        XCTAssertEqual(networks.count, Set(networks).count)
    }

    func testDefaultRulesAreWellFormed() {
        for rule in CardNetworkRule.defaults {
            XCTAssertNotEqual(rule.network, .unknown)
            XCTAssertFalse(rule.lengths.isEmpty, "\(rule.network)")
            XCTAssertFalse(rule.binRanges.isEmpty, "\(rule.network)")
            XCTAssertTrue(rule.lengths.allSatisfy { (12...19).contains($0) }, "\(rule.network)")
            for range in rule.binRanges {
                XCTAssertTrue((1...9).contains(range.digitCount), "\(rule.network)")
            }
        }
    }

    // MARK: - Value semantics

    func testRuleIsEquatableAndSendable() {
        XCTAssertEqual(CardNetworkRule.defaults, CardNetworkRule.defaults)
        let value: any Sendable = CardNetworkRule.defaults
        XCTAssertNotNil(value)
    }
}
