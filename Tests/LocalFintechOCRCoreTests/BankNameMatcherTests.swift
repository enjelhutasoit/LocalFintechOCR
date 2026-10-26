//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import LocalFintechOCRCore

final class BankNameMatcherTests: XCTestCase {

    private let matcher = BankNameMatcher.default

    private func name(_ text: String, using matcher: BankNameMatcher? = nil) -> String? {
        (matcher ?? self.matcher).match(text)?.bank.name
    }

    // MARK: - Exact & formatting (default catalog)

    func testMatchesNamesAndAliasesRegardlessOfCaseAndFormatting() {
        let inputs = ["MANDIRI", "mandiri", "  Mandiri  ", "BANK MANDIRI", "bank-mandiri"]
        for input in inputs {
            let result = matcher.match(input)
            XCTAssertEqual(result?.bank.name, "MANDIRI", input)
            XCTAssertEqual(result?.distance, 0, input)
            XCTAssertEqual(result?.isExact, true, input)
        }
    }

    // MARK: - OCR repair (default catalog)

    func testRepairsOCRConfusedCharactersBeforeMatching() {
        let cases: [(input: String, expected: String)] = [
            ("M4ND1R1", "MANDIRI"),
            ("8CA", "BCA"),
            ("8N1", "BNI"),
            ("8R1", "BRI"),
            ("8TN", "BTN"),
            ("85I", "BSI"),
            ("0C8C", "OCBC"),
            ("D4N4M0N", "DANAMON"),
            ("P3RM4T4", "PERMATA"),
            ("C1M8 N14G4", "CIMB NIAGA")
        ]
        for item in cases {
            let result = matcher.match(item.input)
            XCTAssertEqual(result?.bank.name, item.expected, item.input)
            XCTAssertEqual(result?.distance, 0, item.input)
        }
    }

    // MARK: - Fuzzy tolerance (default catalog)

    func testToleratesSmallEditsInLongerNames() {
        let cases: [(input: String, expected: String, distance: Int)] = [
            ("MANDRI", "MANDIRI", 1),
            ("PERMATTA", "PERMATA", 1),
            ("DANAMN", "DANAMON", 1),
            ("MANDR", "MANDIRI", 2)
        ]
        for item in cases {
            let result = matcher.match(item.input)
            XCTAssertEqual(result?.bank.name, item.expected, item.input)
            XCTAssertEqual(result?.distance, item.distance, item.input)
            XCTAssertEqual(result?.isExact, false, item.input)
        }
    }

    func testThreeLetterNamesRequireExactMatch() {
        XCTAssertNil(matcher.match("BCX"))
        XCTAssertNil(matcher.match("MAN"))
    }

    func testRejectsUnrelatedText() {
        XCTAssertNil(matcher.match("QQQQQQQQ"))
    }

    func testReturnsNilWhenNothingUsableRemainsAfterNormalization() {
        for text in ["", " ", "---", "\u{1F642}", "\u{0660}\u{0661}"] {
            XCTAssertNil(matcher.match(text), "text '\(text)'")
        }
    }

    // MARK: - Catalog invariants

    func testEveryDefaultNameAndAliasResolvesToItsOwnBankExactly() {
        XCTAssertFalse(Bank.defaults.isEmpty)
        for bank in Bank.defaults {
            for label in [bank.name] + bank.aliases {
                let result = matcher.match(label)
                XCTAssertEqual(result?.bank, bank, label)
                XCTAssertEqual(result?.distance, 0, label)
            }
        }
    }

    // MARK: - Normalization (custom catalog)

    func testNormalizationIgnoresSeparatorsAndNonASCII() {
        let custom = BankNameMatcher(banks: [Bank(name: "Cimb Niaga", aliases: ["C.I.M.B"])])
        let inputs = [
            "CIMB NIAGA", "cimb-niaga", "  CIMB   NIAGA.  ",
            "CIMB\u{200B}NIAGA", "CIMB\u{1F642}NIAGA", "c1mb n14ga"
        ]
        for input in inputs {
            XCTAssertEqual(name(input, using: custom), "Cimb Niaga", input)
            XCTAssertEqual(custom.match(input)?.distance, 0, input)
        }
        XCTAssertEqual(name("c.i.m.b", using: custom), "Cimb Niaga")
    }

    func testBanksWithoutAnyUsableKeyNeverMatch() {
        let custom = BankNameMatcher(
            banks: [Bank(name: "---"), Bank(name: "X")],
            maxDistancePerMille: 1_000
        )
        XCTAssertEqual(name("ZZZ", using: custom), "X")

        let onlyEmpty = BankNameMatcher(banks: [Bank(name: "---")], maxDistancePerMille: 1_000)
        XCTAssertNil(onlyEmpty.match("A"))
    }

    // MARK: - Ranking & tie-break (custom catalog)

    func testEqualDistanceIsResolvedByCatalogOrder() {
        let alpha = Bank(name: "ALPHA")
        let alphb = Bank(name: "ALPHB")

        XCTAssertEqual(name("ALPHC", using: BankNameMatcher(banks: [alpha, alphb])), "ALPHA")
        XCTAssertEqual(name("ALPHC", using: BankNameMatcher(banks: [alphb, alpha])), "ALPHB")
    }

    func testSmallerDistanceBeatsEarlierCatalogPosition() {
        let custom = BankNameMatcher(banks: [Bank(name: "ALPHA"), Bank(name: "ALPHB")])
        let result = custom.match("ALPHB")
        XCTAssertEqual(result?.bank.name, "ALPHB")
        XCTAssertEqual(result?.distance, 0)
    }

    // MARK: - Threshold (custom catalog, 10-letter name)

    private let tenLetters = Bank(name: "ABCDEFGHIJ")

    func testDefaultThresholdAllowsThirtyPercent() {
        let custom = BankNameMatcher(banks: [tenLetters])
        XCTAssertEqual(custom.match("ABCDEFGXXX")?.distance, 3)
        XCTAssertNil(custom.match("ABCDEFWXXX"))
    }

    func testZeroThresholdRequiresExactMatch() {
        let custom = BankNameMatcher(banks: [tenLetters], maxDistancePerMille: 0)
        XCTAssertEqual(custom.match("ABCDEFGHIJ")?.distance, 0)
        XCTAssertNil(custom.match("ABCDEFGHIX"))
    }

    func testOutOfRangeThresholdIsClamped() {
        let negative = BankNameMatcher(banks: [tenLetters], maxDistancePerMille: -100)
        XCTAssertEqual(negative.match("ABCDEFGHIJ")?.distance, 0)
        XCTAssertNil(negative.match("ABCDEFGHIX"))

        let huge = BankNameMatcher(banks: [tenLetters], maxDistancePerMille: 5_000)
        XCTAssertEqual(huge.match("QQQQQQQQQQ")?.distance, 10)
    }

    // MARK: - Extensibility

    func testEmptyCatalogNeverMatches() {
        XCTAssertNil(BankNameMatcher(banks: []).match("MANDIRI"))
    }

    func testInjectedConfusionTableReplacesDefaultRepair() {
        let strict = BankNameMatcher(
            banks: Bank.defaults,
            table: OCRConfusionTable(toDigit: [:], toLetter: [:])
        )
        XCTAssertEqual(name("MANDIRI", using: strict), "MANDIRI")
        XCTAssertNil(strict.match("M4ND1R1"))
    }

    // MARK: - Hostile input

    func testHandlesVeryLongInputWithoutCrashing() {
        XCTAssertNil(matcher.match(String(repeating: "Q", count: 1_000_000)))
        XCTAssertNil(matcher.match(String(repeating: "A", count: 1_000_000)))
        XCTAssertNil(matcher.match(String(repeating: "-", count: 1_000_000)))
        XCTAssertNil(matcher.match(String(repeating: "MANDIRI", count: 100_000)))
    }

    func testIsSendable() {
        let matcherValue: any Sendable = BankNameMatcher.default
        let matchValue: any Sendable = BankMatch(bank: Bank(name: "BCA"), distance: 0)
        XCTAssertNotNil(matcherValue)
        XCTAssertNotNil(matchValue)
    }
}
