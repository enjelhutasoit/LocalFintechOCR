//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import LocalFintechOCR

final class LocalFintechOCRConfigurationTests: XCTestCase {

    func testDefaultUsesTheDefaultsOfEveryComponent() {
        let config = LocalFintechOCRConfiguration.default
        XCTAssertEqual(config.confusionTable, OCRConfusionTable.default)
        XCTAssertEqual(config.banks, Bank.defaults)
        XCTAssertEqual(config.networkRules, CardNetworkRule.defaults)
    }

    func testDefaultInitializerEqualsDefaultInstance() {
        XCTAssertEqual(LocalFintechOCRConfiguration(), LocalFintechOCRConfiguration.default)
    }

    func testInitKeepsGivenValues() {
        let table = OCRConfusionTable(toDigit: ["X": "7"], toLetter: ["7": "X"])
        let banks = [Bank(name: "ALPHA")]
        let rules = [CardNetworkRule(network: .gpn, binRanges: [BINRange(digitCount: 1, range: 4...4)], lengths: [16])]

        let config = LocalFintechOCRConfiguration(
            confusionTable: table,
            banks: banks,
            networkRules: rules,
            bankMaxDistancePerMille: 100,
            rowTolerance: 0.5
        )

        XCTAssertEqual(config.confusionTable, table)
        XCTAssertEqual(config.banks, banks)
        XCTAssertEqual(config.networkRules, rules)
        XCTAssertEqual(config.bankMaxDistancePerMille, 100)
        XCTAssertEqual(config.rowTolerance, 0.5)
    }

    func testConfigurationIsMutableAndEquatable() {
        var config = LocalFintechOCRConfiguration.default
        config.banks = []
        XCTAssertNotEqual(config, LocalFintechOCRConfiguration.default)
        XCTAssertEqual(config.banks, [])
    }

    func testIsSendable() {
        let value: any Sendable = LocalFintechOCRConfiguration.default
        XCTAssertNotNil(value)
    }
}
