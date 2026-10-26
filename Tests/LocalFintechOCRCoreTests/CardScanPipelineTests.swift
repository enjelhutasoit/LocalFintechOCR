//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import LocalFintechOCRCore

final class CardScanPipelineTests: XCTestCase {

    private let pipeline = CardScanPipeline.default

    private func success(
        _ text: String,
        using pipeline: CardScanPipeline? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> CardScanResult {
        try (pipeline ?? self.pipeline).scan(text).get()
    }

    private func failure(_ text: String, using pipeline: CardScanPipeline? = nil) -> CardScanError? {
        if case .failure(let error) = (pipeline ?? self.pipeline).scan(text) { return error }
        return nil
    }

    // MARK: - Happy path

    func testScansCompleteCardText() throws {
        let text = "BANK MANDIRI\n4111 1111 1111 1111\nBUDI SANTOSO\nVALID THRU 12/34"
        let result = try success(text)

        XCTAssertEqual(result.cardNumber.digits, "4111111111111111")
        XCTAssertEqual(result.network, .visa)
        XCTAssertEqual(result.expiry?.month, 12)
        XCTAssertEqual(result.expiry?.year, 2034)
        XCTAssertEqual(result.bank?.bank.name, "MANDIRI")
        XCTAssertEqual(result.bank?.distance, 0)
    }

    func testRepairsOCRErrorsAcrossAllFields() throws {
        let text = "M4ND1R1\n4111 1111 1111 111l\nVALID THRU 1l/3O"
        let result = try success(text)

        XCTAssertEqual(result.cardNumber.digits, "4111111111111111")
        XCTAssertEqual(result.expiry?.month, 11)
        XCTAssertEqual(result.expiry?.year, 2030)
        XCTAssertEqual(result.bank?.bank.name, "MANDIRI")
    }

    func testHandlesWindowsAndOldMacLineEndings() throws {
        let text = "BANK MANDIRI\r\n4111 1111 1111 1111\r\nVALID THRU 12/34"
        XCTAssertEqual(try success(text).bank?.bank.name, "MANDIRI")
        XCTAssertEqual(try success(text.replacingOccurrences(of: "\r\n", with: "\r")).bank?.bank.name, "MANDIRI")
    }

    // MARK: - Optional fields

    func testCardNumberAloneIsEnough() throws {
        let result = try success("4111 1111 1111 1111")
        XCTAssertEqual(result.cardNumber.digits, "4111111111111111")
        XCTAssertEqual(result.network, .visa)
        XCTAssertNil(result.expiry)
        XCTAssertNil(result.bank)
    }

    func testUnsupportedNetworkYieldsUnknownButStillSucceeds() throws {
        let result = try success("3782 8224 6310 005")
        XCTAssertEqual(result.network, .unknown)
        XCTAssertEqual(result.cardNumber.digits, "378282246310005")
    }

    func testMastercardNetworkIsDetected() throws {
        XCTAssertEqual(try success("5555 5555 5555 4444").network, .mastercard)
    }

    // MARK: - Expiry selection

    func testChoosesLatestExpiryWhenSeveralDatesArePresent() throws {
        let first = "MEMBER SINCE 05/19\n4111 1111 1111 1111\nVALID THRU 12/34"
        let second = "VALID THRU 12/34\n4111 1111 1111 1111\nMEMBER SINCE 05/19"
        XCTAssertEqual(try success(first).expiry?.formatted, "12/34")
        XCTAssertEqual(try success(second).expiry?.formatted, "12/34")
    }

    func testLatestExpiryComparesYearBeforeMonth() throws {
        let text = "4111 1111 1111 1111\n11/30 01/31"
        XCTAssertEqual(try success(text).expiry?.formatted, "01/31")
    }

    // MARK: - Bank selection

    func testSmallestDistanceAcrossLinesWins() throws {
        let custom = CardScanPipeline(bankMatcher: BankNameMatcher(banks: [Bank(name: "MANDIRI")]))
        let result = try success("MANDRI\n4111 1111 1111 1111\nMANDIRI", using: custom)
        XCTAssertEqual(result.bank?.distance, 0)
    }

    func testEqualDistanceIsResolvedByEarlierLine() throws {
        let custom = CardScanPipeline(
            bankMatcher: BankNameMatcher(banks: [Bank(name: "ALPHA"), Bank(name: "ALPHB")])
        )
        let result = try success("ALPHB\nALPHA\n4111 1111 1111 1111", using: custom)
        XCTAssertEqual(result.bank?.bank.name, "ALPHB")
    }

    func testUnrecognizedBankTextYieldsNilBank() throws {
        let result = try success("QQQQQQQQ\n4111 1111 1111 1111")
        XCTAssertNil(result.bank)
    }

    // MARK: - Failures

    func testEmptyAndWhitespaceOnlyInputFailsWithEmptyInput() {
        for text in ["", " ", "\n", "\r\n", "\t  \n  "] {
            XCTAssertEqual(failure(text), .emptyInput, "text '\(text)'")
        }
    }

    func testTextWithoutValidCardNumberFailsWithNotFound() {
        let inputs = [
            "BUDI SANTOSO\nVALID THRU 12/34",
            "4111 1111 1111 1112",
            "MANDIRI",
            "OOOO OOOO OOOO OOOO",
            "\u{1F642}"
        ]
        for text in inputs {
            XCTAssertEqual(failure(text), .cardNumberNotFound, "text '\(text)'")
        }
    }

    func testDifferentCardNumbersFailAsAmbiguous() {
        let text = "4111 1111 1111 1111\n5555 5555 5555 4444"
        XCTAssertEqual(failure(text), .ambiguousCardNumbers)
    }

    func testSameCardNumberRepeatedIsNotAmbiguous() throws {
        let text = "4111 1111 1111 1111\n4111-1111-1111-1111\n4111111111111111"
        XCTAssertEqual(try success(text).cardNumber.digits, "4111111111111111")
    }

    // MARK: - Determinism

    func testSameInputAlwaysProducesTheSameResult() throws {
        let text = "BANK MANDIRI\n4111 1111 1111 1111\nVALID THRU 12/34"
        XCTAssertEqual(try success(text), try success(text))
    }

    // MARK: - Injection (extensibility)

    func testInjectedEmptyBankCatalogYieldsNilBank() throws {
        let custom = CardScanPipeline(bankMatcher: BankNameMatcher(banks: []))
        XCTAssertNil(try success("BANK MANDIRI\n4111 1111 1111 1111", using: custom).bank)
    }

    func testInjectedEmptyNetworkRulesYieldUnknownNetwork() throws {
        let custom = CardScanPipeline(networkDetector: CardNetworkDetector(rules: []))
        XCTAssertEqual(try success("4111 1111 1111 1111", using: custom).network, .unknown)
    }

    func testInjectedStrictExtractorDisablesOCRRepairForCardNumber() {
        let strict = CardScanPipeline(
            extractor: CardNumberExtractor(table: OCRConfusionTable(toDigit: [:], toLetter: [:]))
        )
        XCTAssertEqual(failure("4111 1111 1111 111l", using: strict), .cardNumberNotFound)
    }

    // MARK: - Hostile input

    func testHandlesVeryLargeInputsWithoutCrashing() {
        XCTAssertEqual(failure(String(repeating: "Q", count: 1_000_000)), .cardNumberNotFound)
        XCTAssertEqual(failure(String(repeating: "0", count: 1_000_000)), .cardNumberNotFound)
        XCTAssertEqual(failure(String(repeating: "\n", count: 1_000_000)), .emptyInput)
        XCTAssertEqual(failure(String(repeating: "MANDIRI\n", count: 100_000)), .cardNumberNotFound)
    }

    func testNonASCIIDigitsAreNotTreatedAsCardNumbers() {
        XCTAssertEqual(failure(String(repeating: "\u{0660}", count: 16)), .cardNumberNotFound)
    }

    func testPipelineIsSendable() {
        let value: any Sendable = CardScanPipeline.default
        XCTAssertNotNil(value)
    }
}
