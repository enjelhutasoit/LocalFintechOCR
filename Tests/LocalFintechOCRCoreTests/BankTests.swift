//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import LocalFintechOCRCore

final class BankTests: XCTestCase {

    func testInitKeepsNameAndAliases() {
        let bank = Bank(name: "CIMB NIAGA", aliases: ["CIMB"])
        XCTAssertEqual(bank.name, "CIMB NIAGA")
        XCTAssertEqual(bank.aliases, ["CIMB"])
    }

    func testAliasesDefaultToEmpty() {
        XCTAssertEqual(Bank(name: "BCA").aliases, [])
    }

    func testEqualityAndHashing() {
        let first = Bank(name: "BCA", aliases: ["BANK CENTRAL ASIA"])
        let second = Bank(name: "BCA", aliases: ["BANK CENTRAL ASIA"])
        let other = Bank(name: "BNI")
        XCTAssertEqual(first, second)
        XCTAssertNotEqual(first, other)
        XCTAssertEqual(Set([first, second, other]).count, 2)
    }

    func testDefaultCatalogContainsExpectedBanksInStableOrder() {
        XCTAssertEqual(
            Bank.defaults.map(\.name),
            ["BCA", "MANDIRI", "BNI", "BRI", "CIMB NIAGA",
             "PERMATA", "DANAMON", "BTN", "OCBC", "BSI"]
        )
    }

    func testDefaultCatalogHasNoEmptyNamesOrAliases() {
        for bank in Bank.defaults {
            XCTAssertFalse(bank.name.isEmpty)
            XCTAssertTrue(bank.aliases.allSatisfy { !$0.isEmpty }, bank.name)
        }
    }

    func testIsSendable() {
        let value: any Sendable = Bank(name: "BCA")
        XCTAssertNotNil(value)
    }
}
