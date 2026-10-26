//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import LocalFintechOCRCore

final class CardNumberExtractorTests: XCTestCase {

    private let extractor = CardNumberExtractor.default

    private func digits(_ text: String, using extractor: CardNumberExtractor? = nil) -> [String] {
        (extractor ?? self.extractor).extract(from: text).map(\.digits)
    }

    // MARK: - Formats

    func testExtractsPlainSpacedAndDashedNumbers() {
        XCTAssertEqual(digits("4111111111111111"), ["4111111111111111"])
        XCTAssertEqual(digits("4111 1111 1111 1111"), ["4111111111111111"])
        XCTAssertEqual(digits("4111-1111-1111-1111"), ["4111111111111111"])
        XCTAssertEqual(digits("4111-1111 1111-1111"), ["4111111111111111"])
    }

    func testExtractsNumberSurroundedByNoise() {
        let text = "BUDI SANTOSO\n4111 1111 1111 1111\nVALID THRU 12/34"
        XCTAssertEqual(digits(text), ["4111111111111111"])
    }

    func testReturnsResultsAsCardNumbers() throws {
        let results = extractor.extract(from: "4111 1111 1111 1111")
        let expected = try XCTUnwrap(CardNumber(digits: "4111111111111111"))
        XCTAssertEqual(results, [expected])
    }

    func testExtractsMultipleNumbersInOrderOfAppearance() {
        XCTAssertEqual(
            digits("4111 1111 1111 1111\n5555 5555 5555 4444"),
            ["4111111111111111", "5555555555554444"]
        )
        XCTAssertEqual(
            digits("5555555555554444; 4111111111111111"),
            ["5555555555554444", "4111111111111111"]
        )
    }

    // MARK: - OCR correction

    func testCorrectsLookalikeCharactersBeforeValidation() {
        XCTAssertEqual(digits("4111 1111 1111 111l"), ["4111111111111111"])
        XCTAssertEqual(digits("S555 5555 5555 4444"), ["5555555555554444"])
        XCTAssertEqual(digits("4OOO 0000 0000 0002"), ["4000000000000002"])
    }

    // MARK: - Length policy (13...19)

    func testAcceptsLengthBoundaries() {
        XCTAssertEqual(digits("4222 2222 2222 2"), ["4222222222222"])                 // 13
        XCTAssertEqual(digits("4000 0000 0000 0000 006"), ["4000000000000000006"])    // 19
    }

    func testRejectsTooShortAndTooLongEvenWhenLuhnValid() {
        XCTAssertEqual(digits("4000 0000 0002"), [])                // 12 digits, Luhn-valid
        XCTAssertEqual(digits("4000 0000 0000 0000 0002"), [])      // 20 digits, Luhn-valid
    }

    // MARK: - Rejection

    func testRejectsInvalidChecksum() {
        XCTAssertEqual(digits("4111 1111 1111 1112"), [])
    }

    func testRejectsCandidatesAttachedToLetters() {
        XCTAssertEqual(digits("A4111111111111111"), [])
        XCTAssertEqual(digits("4111111111111111A"), [])
        XCTAssertEqual(digits("REF4111111111111111"), [])
    }

    func testRejectsTextThatOnlyBecomesNumericAfterCorrection() {
        // Corrects to 16 zeros, which has a valid Luhn checksum but is not a card.
        XCTAssertEqual(digits("OOOO OOOO OOOO OOOO"), [])
    }

    func testReturnsEmptyForTextWithoutCandidates() {
        for text in ["", " ", "\n", "VALID THRU 12/34", "MANDIRI", "12/34", "\u{1F642}"] {
            XCTAssertEqual(digits(text), [], "text '\(text)'")
        }
    }

    // MARK: - Hostile input

    func testIgnoresNonASCIIDigits() {
        XCTAssertEqual(digits(String(repeating: "\u{0660}", count: 16)), [])
        XCTAssertEqual(digits(String(repeating: "\u{FF10}", count: 16)), [])
    }

    func testHandlesVeryLongInputWithoutCrashing() {
        XCTAssertEqual(digits(String(repeating: "0", count: 1_000_000)), [])
        XCTAssertEqual(digits(String(repeating: "O", count: 1_000_000)), [])
        XCTAssertEqual(digits(String(repeating: "4111 ", count: 100_000)), [])
    }

    // MARK: - Extensibility

    func testEmptyTableOnlyExtractsRealDigits() {
        let strict = CardNumberExtractor(table: OCRConfusionTable(toDigit: [:], toLetter: [:]))
        XCTAssertEqual(digits("4111 1111 1111 1111", using: strict), ["4111111111111111"])
        XCTAssertEqual(digits("4111 1111 1111 111l", using: strict), [])
    }

    func testIsSendable() {
        let value: any Sendable = CardNumberExtractor.default
        XCTAssertNotNil(value)
    }
}
