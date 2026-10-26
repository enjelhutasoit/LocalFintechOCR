//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import LocalFintechOCRCore

final class OCRConfusionTableTests: XCTestCase {

    private let asciiDigits: Set<Unicode.Scalar> = Set("0123456789".unicodeScalars)
    private let asciiLetters: Set<Unicode.Scalar> = Set(
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz".unicodeScalars
    )

    func testDefaultToDigitMapsCommonLookalikes() {
        let expected: [Unicode.Scalar: Unicode.Scalar] = [
            "O": "0", "o": "0", "I": "1", "l": "1", "|": "1",
            "Z": "2", "S": "5", "s": "5", "B": "8"
        ]
        XCTAssertEqual(OCRConfusionTable.default.toDigit, expected)
    }

    func testDefaultToLetterMapsCommonLookalikes() {
        let expected: [Unicode.Scalar: Unicode.Scalar] = [
            "0": "O", "1": "I", "3": "E", "4": "A", "5": "S", "8": "B"
        ]
        XCTAssertEqual(OCRConfusionTable.default.toLetter, expected)
    }

    // MARK: - Invariants that guarantee idempotence

    func testToDigitValuesAreDigitsAndKeysAreNotDigits() {
        for (key, value) in OCRConfusionTable.default.toDigit {
            XCTAssertTrue(asciiDigits.contains(value), "value \(value) must be a digit")
            XCTAssertFalse(asciiDigits.contains(key), "key \(key) must not be a digit")
        }
    }

    func testToLetterValuesAreLettersAndKeysAreNotLetters() {
        for (key, value) in OCRConfusionTable.default.toLetter {
            XCTAssertTrue(asciiLetters.contains(value), "value \(value) must be a letter")
            XCTAssertFalse(asciiLetters.contains(key), "key \(key) must not be a letter")
        }
    }

    // MARK: - Construction

    func testCustomTableKeepsGivenRules() {
        let toDigit: [Unicode.Scalar: Unicode.Scalar] = ["X": "7"]
        let toLetter: [Unicode.Scalar: Unicode.Scalar] = ["7": "X"]
        let table = OCRConfusionTable(toDigit: toDigit, toLetter: toLetter)

        XCTAssertEqual(table.toDigit, toDigit)
        XCTAssertEqual(table.toLetter, toLetter)
    }

    func testTableIsEquatable() {
        XCTAssertEqual(OCRConfusionTable.default, OCRConfusionTable.default)
        XCTAssertNotEqual(OCRConfusionTable.default, OCRConfusionTable(toDigit: [:], toLetter: [:]))
    }
}
