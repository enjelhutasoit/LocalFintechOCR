//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// A card expiry month and year. Invalid values cannot be constructed.
///
/// - Month: 1...12. Year: 2000...2099 (two-digit `YY` is interpreted as `20YY`).
/// - A card is valid through the END of its expiry month.
public struct ExpiryDate: Sendable, Hashable, CustomStringConvertible {

    private static let validMonths: ClosedRange<Int> = 1...12
    private static let validYears: ClosedRange<Int> = 2000...2099

    public let month: Int
    public let year: Int

    /// Returns `nil` when `month` or `year` is outside the supported range.
    public init?(month: Int, year: Int) {
        guard Self.validMonths.contains(month), Self.validYears.contains(year) else { return nil }
        self.month = month
        self.year = year
    }

    /// `MM/YY`, e.g. `01/26`.
    public var formatted: String {
        let yearSuffix = year % 100
        return pad(month) + "/" + pad(yearSuffix)
    }

    public var description: String { formatted }

    /// Returns `true` once the expiry month has fully passed in `calendar`.
    ///
    /// `now` and `calendar` are injected so the result is deterministic and testable.
    /// The caller's calendar (and its time zone) decides which month `now` falls in.
    public func isExpired(asOf now: Date, calendar: Calendar) -> Bool {
        let current = calendar.dateComponents([.year, .month], from: now)
        // Fail closed: if the reference month cannot be determined, treat as expired.
        guard let currentYear = current.year, let currentMonth = current.month else { return true }
        return (currentYear, currentMonth) > (year, month)
    }

    private func pad(_ value: Int) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }
}
