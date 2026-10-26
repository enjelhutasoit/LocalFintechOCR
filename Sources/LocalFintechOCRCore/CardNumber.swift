//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// A Luhn-valid payment card number (PAN).
///
/// Invalid values cannot be constructed. Every textual and reflective
/// representation is masked (`•••• 1111`) so the full number never reaches
/// logs, crash reports, or debugger output by accident.
/// The full value is available only through the explicit `digits` property.
public struct CardNumber: Sendable, Hashable, CustomStringConvertible,
                          CustomDebugStringConvertible, CustomReflectable {

    /// The full PAN as plain ASCII digits. Handle with care (PII).
    public let digits: String

    /// Returns `nil` unless `digits` is plain ASCII digits with a valid Luhn checksum.
    public init?(digits: String) {
        guard LuhnValidator.isValid(digits) else { return nil }
        self.digits = digits
    }

    /// The last four digits.
    public var lastFour: String { String(digits.suffix(4)) }

    /// Masked representation, e.g. `•••• 1111`.
    public var masked: String { "\u{2022}\u{2022}\u{2022}\u{2022} " + lastFour }

    public var description: String { masked }
    public var debugDescription: String { masked }

    public var customMirror: Mirror {
        Mirror(self, children: ["masked": masked], displayStyle: .struct)
    }
}
