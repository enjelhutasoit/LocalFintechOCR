//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import LocalFintechOCRCore

final class OCRTextSanitizerTests: XCTestCase {

    private let sanitizer = OCRTextSanitizer.default

    // MARK: - Numeric context

    func testNumericContextCorrectsLookalikeLettersToDigits() {
        let cases: [(input: String, expected: String)] = [
            ("O", "0"), ("o", "0"),
            ("I", "1"), ("l", "1"), ("|", "1"),
            ("Z", "2"),
            ("S", "5"), ("s", "5"),
            ("B", "8"),
            ("4111 1111 1111 111l", "4111 1111 1111 1111"),
            ("4OOO-BBBB-SSSS-1ZZI", "4000-8888-5555-1221"),
            ("5555 5555 5555 444A", "5555 5555 5555 444A") // 'A' is not in the numeric table
        ]
        for testCase in cases {
            XCTAssertEqual(
                sanitizer.sanitize(testCase.input, as: .numeric),
                testCase.expected,
                "numeric '\(testCase.input)'"
            )
        }
    }

    func testNumericContextLeavesDigitsSeparatorsAndUnknownLettersUntouched() {
        let inputs = ["4111-1111 1111.1111", "AXY", "", " ", "12/34", "VALID THRU"]
        for input in inputs {
            XCTAssertEqual(sanitizer.sanitize(input, as: .numeric), input)
        }
    }

    // MARK: - Alphabetic context

    func testAlphabeticContextCorrectsLookalikeDigitsToLetters() {
        let cases: [(input: String, expected: String)] = [
            ("0", "O"), ("1", "I"), ("3", "E"), ("4", "A"), ("5", "S"), ("8", "B"),
            ("M4ND1R1", "MANDIRI"),
            ("8CA", "BCA"),
            ("8N1", "BNI"),
            ("8R1", "BRI"),
            ("C1M8", "CIMB"),
            ("CIMB N14G4", "CIMB NIAGA"),
            ("0CBC", "OCBC")
        ]
        for testCase in cases {
            XCTAssertEqual(
                sanitizer.sanitize(testCase.input, as: .alphabetic),
                testCase.expected,
                "alphabetic '\(testCase.input)'"
            )
        }
    }

    func testAlphabeticContextPreservesLetterCaseAndPunctuation() {
        XCTAssertEqual(sanitizer.sanitize("m4ndiri", as: .alphabetic), "mandiri")
        XCTAssertEqual(sanitizer.sanitize("MANDIRI bank, Tbk.", as: .alphabetic), "MANDIRI bank, Tbk.")
    }

    // MARK: - Context separation

    func testSameInputYieldsDifferentResultsPerContext() {
        XCTAssertEqual(sanitizer.sanitize("B", as: .numeric), "8")
        XCTAssertEqual(sanitizer.sanitize("B", as: .alphabetic), "B")
        XCTAssertEqual(sanitizer.sanitize("8", as: .numeric), "8")
        XCTAssertEqual(sanitizer.sanitize("8", as: .alphabetic), "B")
    }

    // MARK: - Properties

    private let propertyFixtures = [
        "", "4111 1111 1111 111l", "M4ND1R1", "O0Il1|BS85sZ2",
        "CIMB N14G4", "12/34", "\u{1F642}O", "O\u{301}", "mixed 0O1l B8"
    ]

    func testIsIdempotentInBothContexts() {
        for input in propertyFixtures {
            for context in [OCRCharacterContext.numeric, .alphabetic] {
                let once = sanitizer.sanitize(input, as: context)
                let twice = sanitizer.sanitize(once, as: context)
                XCTAssertEqual(once, twice, "idempotence '\(input)' \(context)")
            }
        }
    }

    func testPreservesUnicodeScalarCount() {
        for input in propertyFixtures {
            for context in [OCRCharacterContext.numeric, .alphabetic] {
                let output = sanitizer.sanitize(input, as: context)
                XCTAssertEqual(
                    output.unicodeScalars.count,
                    input.unicodeScalars.count,
                    "length '\(input)' \(context)"
                )
            }
        }
    }

    // MARK: - Unicode & hostile input

    func testNonASCIIScalarsPassThroughUnchanged() {
        XCTAssertEqual(sanitizer.sanitize("\u{1F642}O", as: .numeric), "\u{1F642}0")
        XCTAssertEqual(sanitizer.sanitize("O\u{301}", as: .numeric), "0\u{301}")
        XCTAssertEqual(sanitizer.sanitize("\u{0660}\u{FF10}", as: .alphabetic), "\u{0660}\u{FF10}")
        XCTAssertEqual(sanitizer.sanitize("a\u{0000}b", as: .alphabetic), "a\u{0000}b")
    }

    func testVeryLongInputDoesNotCrashAndKeepsLength() {
        let huge = String(repeating: "O", count: 1_000_000)
        let output = sanitizer.sanitize(huge, as: .numeric)
        XCTAssertEqual(output.unicodeScalars.count, 1_000_000)
        XCTAssertEqual(output.unicodeScalars.first, "0")
        XCTAssertEqual(output.unicodeScalars.last, "0")
    }

    // MARK: - Extensibility (injected table)

    func testCustomTableReplacesDefaultRules() {
        let table = OCRConfusionTable(toDigit: ["X": "7"], toLetter: ["7": "X"])
        let custom = OCRTextSanitizer(table: table)

        XCTAssertEqual(custom.sanitize("X", as: .numeric), "7")
        XCTAssertEqual(custom.sanitize("O", as: .numeric), "O")
        XCTAssertEqual(custom.sanitize("7", as: .alphabetic), "X")
        XCTAssertEqual(custom.sanitize("4", as: .alphabetic), "4")
    }

    func testEmptyTableIsIdentity() {
        let identity = OCRTextSanitizer(table: OCRConfusionTable(toDigit: [:], toLetter: [:]))
        XCTAssertEqual(identity.sanitize("O0B8l1", as: .numeric), "O0B8l1")
        XCTAssertEqual(identity.sanitize("M4ND1R1", as: .alphabetic), "M4ND1R1")
    }

    func testSanitizerIsSendable() {
        let value: any Sendable = OCRTextSanitizer.default
        XCTAssertNotNil(value)
    }
}
