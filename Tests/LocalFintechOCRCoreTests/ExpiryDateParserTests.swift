//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import LocalFintechOCRCore

final class ExpiryDateParserTests: XCTestCase {

    private let parser = ExpiryDateParser.default

    private func formatted(_ text: String, using parser: ExpiryDateParser? = nil) -> [String] {
        (parser ?? self.parser).parse(from: text).map(\.formatted)
    }

    private func pairs(_ text: String) -> [[Int]] {
        parser.parse(from: text).map { [$0.month, $0.year] }
    }

    // MARK: - Formats

    func testParsesTwoDigitYearAsTwentyFirstCentury() {
        XCTAssertEqual(pairs("12/34"), [[12, 2034]])
        XCTAssertEqual(pairs("01/30"), [[1, 2030]])
    }

    func testParsesFourDigitYear() {
        XCTAssertEqual(pairs("12/2034"), [[12, 2034]])
        XCTAssertEqual(pairs("01/2030"), [[1, 2030]])
    }

    func testParsesWithinNoisyCardText() {
        XCTAssertEqual(formatted("BUDI SANTOSO\n4111 1111 1111 1111\nVALID THRU 12/34"), ["12/34"])
        XCTAssertEqual(formatted("VALID THRU 12/34 CVV"), ["12/34"])
    }

    func testReturnsAllCandidatesInOrderOfAppearance() {
        XCTAssertEqual(formatted("MEMBER SINCE 05/19  VALID THRU 12/34"), ["05/19", "12/34"])
    }

    // MARK: - OCR correction

    func testCorrectsLookalikeCharactersWhenMostCharactersAreRealDigits() {
        XCTAssertEqual(pairs("1l/3O"), [[11, 2030]])
        XCTAssertEqual(pairs("O5/2O3O"), [[5, 2030]])
    }

    func testRejectsCandidatesThatAreMostlyCorrectedLetters() {
        // Would correct to 05/08, but none of the characters was a real digit.
        XCTAssertEqual(pairs("OS/OB"), [])
    }

    // MARK: - Invalid values

    func testRejectsInvalidMonth() {
        for text in ["00/34", "13/34", "99/34"] {
            XCTAssertEqual(pairs(text), [], text)
        }
    }

    func testRejectsYearOutsideSupportedRange() {
        for text in ["12/1999", "12/2100"] {
            XCTAssertEqual(pairs(text), [], text)
        }
    }

    // MARK: - Shape rejection

    func testRejectsWrongDigitCounts() {
        for text in ["1/34", "12/3", "12/345", "123/45", "112/34", "12/", "/34"] {
            XCTAssertEqual(pairs(text), [], text)
        }
    }

    func testRejectsFullDatesAndAttachedLetters() {
        for text in ["01/12/34", "12/34/56", "A12/34", "12/34A", "THRU12/34"] {
            XCTAssertEqual(pairs(text), [], text)
        }
    }

    func testRejectsOtherSeparators() {
        for text in ["12-34", "12.34", "12 34", "1234"] {
            XCTAssertEqual(pairs(text), [], text)
        }
    }

    func testReturnsEmptyForTextWithoutCandidates() {
        for text in ["", " ", "\n", "MANDIRI", "VALID THRU", "\u{1F642}"] {
            XCTAssertEqual(pairs(text), [], "text '\(text)'")
        }
    }

    // MARK: - Hostile input

    func testIgnoresNonASCIIDigits() {
        XCTAssertEqual(pairs("\u{0661}\u{0662}/\u{0663}\u{0664}"), [])
        XCTAssertEqual(pairs("\u{FF11}\u{FF12}/\u{FF13}\u{FF14}"), [])
    }

    func testHandlesVeryLongInputWithoutCrashing() {
        XCTAssertEqual(pairs(String(repeating: "/", count: 1_000_000)), [])
        XCTAssertEqual(pairs(String(repeating: "1", count: 1_000_000)), [])
        XCTAssertEqual(pairs(String(repeating: "12/", count: 100_000)), [])
    }

    // MARK: - Extensibility

    func testEmptyTableOnlyParsesRealDigits() {
        let strict = ExpiryDateParser(table: OCRConfusionTable(toDigit: [:], toLetter: [:]))
        XCTAssertEqual(formatted("12/34", using: strict), ["12/34"])
        XCTAssertEqual(formatted("1l/3O", using: strict), [])
    }

    func testIsSendable() {
        let value: any Sendable = ExpiryDateParser.default
        XCTAssertNotNil(value)
    }
}
