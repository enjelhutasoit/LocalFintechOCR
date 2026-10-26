//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import LocalFintechOCRCore

final class CardNetworkDetectorTests: XCTestCase {

    private let detector = CardNetworkDetector.default

    /// All PANs below are public/synthetic test numbers with a valid Luhn checksum.
    private func network(_ pan: String, using detector: CardNetworkDetector? = nil) -> CardNetwork {
        guard let card = CardNumber(digits: pan) else {
            XCTFail("Fixture must be Luhn-valid: \(pan)")
            return .unknown
        }
        return (detector ?? self.detector).detect(card)
    }

    // MARK: - Detection

    func testDetectsKnownNetworks() {
        let cases: [(pan: String, expected: CardNetwork)] = [
            ("4111111111111111", .visa),            // 16
            ("4222222222222", .visa),               // 13
            ("4000000000000000006", .visa),         // 19
            ("5555555555554444", .mastercard),
            ("2223003122003222", .mastercard),      // 2-series
            ("3530111333300000", .jcb),
            ("6200000000000005", .unionPay),
            ("1946000000000005", .gpn)
        ]
        for item in cases {
            XCTAssertEqual(network(item.pan), item.expected, item.pan)
        }
    }

    // MARK: - Range boundaries

    func testMastercardBoundaries() {
        XCTAssertEqual(network("5100000000000008"), .mastercard)
        XCTAssertEqual(network("5500000000000004"), .mastercard)
        XCTAssertEqual(network("5000000000000009"), .unknown)
        XCTAssertEqual(network("5600000000000003"), .unknown)
        XCTAssertEqual(network("2221000000000009"), .mastercard)
        XCTAssertEqual(network("2720000000000005"), .mastercard)
        XCTAssertEqual(network("2220000000000000"), .unknown)
        XCTAssertEqual(network("2721000000000004"), .unknown)
    }

    func testJCBBoundaries() {
        XCTAssertEqual(network("3528000000000007"), .jcb)
        XCTAssertEqual(network("3589000000000003"), .jcb)
        XCTAssertEqual(network("3527000000000008"), .unknown)
        XCTAssertEqual(network("3590000000000000"), .unknown)
    }

    // MARK: - Unknown

    func testReturnsUnknownForUnsupportedNetworks() {
        let unsupported = [
            "378282246310005",   // Amex
            "6011111111111117",  // Discover
            "30569309025904"     // Diners
        ]
        for pan in unsupported {
            XCTAssertEqual(network(pan), .unknown, pan)
        }
    }

    func testReturnsUnknownWhenPrefixMatchesButLengthDoesNot() {
        // Visa prefix, Luhn-valid, 12 digits (Visa allows 13, 16, 19).
        XCTAssertEqual(network("400000000002"), .unknown)
    }

    // MARK: - Extensibility

    func testEmptyRulesAlwaysReturnUnknown() {
        let empty = CardNetworkDetector(rules: [])
        XCTAssertEqual(network("4111111111111111", using: empty), .unknown)
    }

    func testCustomRulesReplaceDefaults() {
        let custom = CardNetworkDetector(rules: [
            CardNetworkRule(
                network: .gpn,
                binRanges: [BINRange(digitCount: 1, range: 4...4)],
                lengths: [16]
            )
        ])
        XCTAssertEqual(network("4111111111111111", using: custom), .gpn)
        XCTAssertEqual(network("4222222222222", using: custom), .unknown)
        XCTAssertEqual(network("5555555555554444", using: custom), .unknown)
    }

    func testFirstMatchingRuleWins() {
        let overlapping = CardNetworkDetector(rules: [
            CardNetworkRule(network: .jcb, binRanges: [BINRange(digitCount: 1, range: 4...4)], lengths: [16]),
            CardNetworkRule(network: .visa, binRanges: [BINRange(digitCount: 1, range: 4...4)], lengths: [16])
        ])
        XCTAssertEqual(network("4111111111111111", using: overlapping), .jcb)
    }

    func testIsSendable() {
        let value: any Sendable = CardNetworkDetector.default
        XCTAssertNotNil(value)
    }
}
