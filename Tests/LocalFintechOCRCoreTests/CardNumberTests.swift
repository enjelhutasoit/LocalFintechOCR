//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import LocalFintechOCRCore

final class CardNumberTests: XCTestCase {

    private let visa = "4111111111111111"

    // MARK: - Construction

    func testAcceptsLuhnValidDigits() throws {
        let card = try XCTUnwrap(CardNumber(digits: visa))
        XCTAssertEqual(card.digits, visa)
    }

    func testRejectsInvalidInput() {
        let inputs = [
            "", "4111111111111112", "4111 1111 1111 1111",
            "4111-1111-1111-1111", "411111111111111a", "411"
        ]
        for input in inputs {
            XCTAssertNil(CardNumber(digits: input), "Must reject '\(input)'")
        }
    }

    // MARK: - Derived values

    func testLastFourAndMasked() throws {
        let card = try XCTUnwrap(CardNumber(digits: "5555555555554444"))
        XCTAssertEqual(card.lastFour, "4444")
        XCTAssertEqual(card.masked, "\u{2022}\u{2022}\u{2022}\u{2022} 4444")
    }

    // MARK: - PII safety

    func testTextRepresentationsNeverExposeFullNumber() throws {
        let card = try XCTUnwrap(CardNumber(digits: visa))
        let outputs = [
            card.description,
            card.debugDescription,
            "\(card)",
            String(describing: card),
            String(reflecting: card)
        ]
        for output in outputs {
            XCTAssertEqual(output, card.masked)
            XCTAssertFalse(output.contains("411111111111"))
        }
    }

    func testDumpNeverExposesFullNumber() throws {
        let card = try XCTUnwrap(CardNumber(digits: visa))
        var output = ""
        dump(card, to: &output)
        XCTAssertFalse(output.contains("411111111111"))
        XCTAssertTrue(output.contains(card.masked))
    }

    // MARK: - Value semantics

    func testEqualityAndHashingFollowDigits() throws {
        let first = try XCTUnwrap(CardNumber(digits: visa))
        let second = try XCTUnwrap(CardNumber(digits: visa))
        let other = try XCTUnwrap(CardNumber(digits: "5555555555554444"))

        XCTAssertEqual(first, second)
        XCTAssertNotEqual(first, other)
        XCTAssertEqual(Set([first, second, other]).count, 2)
    }

    func testIsSendable() throws {
        let value: any Sendable = try XCTUnwrap(CardNumber(digits: visa))
        XCTAssertNotNil(value)
    }
}
