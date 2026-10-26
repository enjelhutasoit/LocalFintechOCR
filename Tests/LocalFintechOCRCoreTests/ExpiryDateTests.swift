//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import LocalFintechOCRCore

final class ExpiryDateTests: XCTestCase {

    // MARK: - Fixtures (fixed instants, UTC calendar; no Date(), no time zone dependence)

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int,
                      _ hour: Int = 0, _ minute: Int = 0, _ second: Int = 0) throws -> Date {
        let components = DateComponents(
            year: year, month: month, day: day, hour: hour, minute: minute, second: second
        )
        return try XCTUnwrap(calendar.date(from: components))
    }

    // MARK: - Construction

    func testAcceptsValidMonthAndYearRange() {
        XCTAssertNotNil(ExpiryDate(month: 1, year: 2000))
        XCTAssertNotNil(ExpiryDate(month: 12, year: 2099))
        XCTAssertNotNil(ExpiryDate(month: 6, year: 2030))
    }

    func testRejectsInvalidMonthOrYear() {
        let invalid: [(month: Int, year: Int)] = [
            (0, 2030), (13, 2030), (-1, 2030), (1, 1999), (1, 2100), (1, -2030)
        ]
        for item in invalid {
            XCTAssertNil(ExpiryDate(month: item.month, year: item.year), "\(item)")
        }
    }

    // MARK: - Formatting

    func testFormattedUsesTwoDigitMonthAndYear() throws {
        XCTAssertEqual(try XCTUnwrap(ExpiryDate(month: 1, year: 2026)).formatted, "01/26")
        XCTAssertEqual(try XCTUnwrap(ExpiryDate(month: 12, year: 2034)).formatted, "12/34")
        XCTAssertEqual(try XCTUnwrap(ExpiryDate(month: 7, year: 2005)).formatted, "07/05")
        XCTAssertEqual(try XCTUnwrap(ExpiryDate(month: 7, year: 2005)).description, "07/05")
    }

    // MARK: - Expiry (valid through the END of the expiry month)

    func testIsNotExpiredDuringExpiryMonth() throws {
        let expiry = try XCTUnwrap(ExpiryDate(month: 10, year: 2026))
        XCTAssertFalse(expiry.isExpired(asOf: try date(2026, 10, 1), calendar: calendar))
        XCTAssertFalse(expiry.isExpired(asOf: try date(2026, 10, 31, 23, 59, 59), calendar: calendar))
    }

    func testIsExpiredFromTheFirstInstantOfTheNextMonth() throws {
        let expiry = try XCTUnwrap(ExpiryDate(month: 10, year: 2026))
        XCTAssertTrue(expiry.isExpired(asOf: try date(2026, 11, 1, 0, 0, 0), calendar: calendar))
    }

    func testYearBoundary() throws {
        let expiry = try XCTUnwrap(ExpiryDate(month: 12, year: 2026))
        XCTAssertFalse(expiry.isExpired(asOf: try date(2026, 12, 31, 23, 59, 59), calendar: calendar))
        XCTAssertTrue(expiry.isExpired(asOf: try date(2027, 1, 1), calendar: calendar))
    }

    func testEarlierAndLaterReferenceDates() throws {
        let expiry = try XCTUnwrap(ExpiryDate(month: 6, year: 2030))
        XCTAssertFalse(expiry.isExpired(asOf: try date(2020, 1, 1), calendar: calendar))
        XCTAssertFalse(expiry.isExpired(asOf: try date(2029, 12, 31), calendar: calendar))
        XCTAssertTrue(expiry.isExpired(asOf: try date(2031, 1, 1), calendar: calendar))
    }

    // MARK: - Value semantics

    func testEqualityAndHashing() throws {
        let first = try XCTUnwrap(ExpiryDate(month: 12, year: 2034))
        let second = try XCTUnwrap(ExpiryDate(month: 12, year: 2034))
        let other = try XCTUnwrap(ExpiryDate(month: 11, year: 2034))
        XCTAssertEqual(first, second)
        XCTAssertNotEqual(first, other)
        XCTAssertEqual(Set([first, second, other]).count, 2)
    }

    func testIsSendable() throws {
        let value: any Sendable = try XCTUnwrap(ExpiryDate(month: 1, year: 2030))
        XCTAssertNotNil(value)
    }
}
