//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import LocalFintechOCRCore

final class LuhnValidatorTests: XCTestCase {

    // MARK: - Fixtures (public test PANs only; never real card data)

    private let knownValidPANs: [(label: String, pan: String)] = [
        ("Visa 16", "4111111111111111"),
        ("Visa 16 alt", "4012888888881881"),
        ("Visa 13", "4222222222222"),
        ("Mastercard 16", "5555555555554444"),
        ("Amex 15", "378282246310005"),
        ("Discover 16", "6011111111111117"),
        ("JCB 16", "3530111333300000"),
        ("Diners 14", "30569309025904")
    ]

    /// Luhn-valid numbers built at the exact length boundaries.
    private var valid12Digits: String { "4" + String(repeating: "0", count: 10) + "2" }
    private var valid19Digits: String { "4" + String(repeating: "0", count: 17) + "6" }
    /// Luhn-valid but outside the accepted length range.
    private var valid11Digits: String { "4" + String(repeating: "0", count: 9) + "6" }
    private var valid20Digits: String { "4" + String(repeating: "0", count: 18) + "2" }

    // MARK: - Acceptance

    func testAcceptsWellKnownValidTestPANs() {
        for fixture in knownValidPANs {
            XCTAssertTrue(LuhnValidator.isValid(fixture.pan), "Expected valid: \(fixture.label)")
        }
    }

    func testAcceptsLowerAndUpperLengthBoundaries() {
        XCTAssertEqual(valid12Digits.count, 12)
        XCTAssertEqual(valid19Digits.count, 19)
        XCTAssertTrue(LuhnValidator.isValid(valid12Digits))
        XCTAssertTrue(LuhnValidator.isValid(valid19Digits))
    }

    // MARK: - Length rejection

    func testRejectsOutOfRangeLengthEvenWhenChecksumIsValid() {
        XCTAssertEqual(valid11Digits.count, 11)
        XCTAssertEqual(valid20Digits.count, 20)
        XCTAssertFalse(LuhnValidator.isValid(valid11Digits))
        XCTAssertFalse(LuhnValidator.isValid(valid20Digits))
    }

    // MARK: - Checksum rejection

    func testRejectsInvalidChecksum() {
        let invalid = [
            "4111111111111112",
            "5555555555554445",
            "378282246310006",
            "6011111111111118"
        ]
        for pan in invalid {
            XCTAssertFalse(LuhnValidator.isValid(pan), "Expected invalid checksum")
        }
    }

    func testDetectsEverySingleDigitSubstitution() {
        let base = Array("4111111111111111")
        XCTAssertTrue(LuhnValidator.isValid(String(base)))

        for index in base.indices {
            for replacement in "0123456789" where replacement != base[index] {
                var mutated = base
                mutated[index] = replacement
                XCTAssertFalse(
                    LuhnValidator.isValid(String(mutated)),
                    "Substitution at index \(index) with \(replacement) must be detected"
                )
            }
        }
    }

    // MARK: - Non-digit / hostile input

    func testRejectsEmptyAndWhitespaceOnlyInput() {
        for input in ["", " ", "            ", "\n", "\t"] {
            XCTAssertFalse(LuhnValidator.isValid(input))
        }
    }

    func testRejectsFormattingCharactersBecauseNormalizationIsNotItsJob() {
        let formatted = [
            "4111 1111 1111 1111",
            "4111-1111-1111-1111",
            " 4111111111111111",
            "4111111111111111 ",
            "4111111111111111\n",
            "411111111111111a"
        ]
        for input in formatted {
            XCTAssertFalse(LuhnValidator.isValid(input), "Must reject non-normalized input")
        }
    }

    func testRejectsNonASCIIDigitsThatLookNumeric() {
        // All-zero strings have checksum 0, so a naive Unicode-aware
        // implementation would incorrectly accept them.
        let arabicIndicZeros = String(repeating: "\u{0660}", count: 16)
        let fullwidthZeros = String(repeating: "\u{FF10}", count: 16)
        let combiningMark = "4111111111111111\u{0301}"
        let nullByte = "4111111111111111\u{0000}"

        for input in [arabicIndicZeros, fullwidthZeros, combiningMark, nullByte, "🙂🙂🙂🙂🙂🙂🙂🙂🙂🙂🙂🙂"] {
            XCTAssertFalse(LuhnValidator.isValid(input))
        }
    }

    // MARK: - Robustness

    func testHandlesExtremelyLongInputWithoutCrashing() {
        let huge = String(repeating: "0", count: 1_000_000)
        XCTAssertFalse(LuhnValidator.isValid(huge))
    }
}
