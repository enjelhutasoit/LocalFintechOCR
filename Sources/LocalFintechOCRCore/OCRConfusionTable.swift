//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// Data-only description of characters that OCR commonly confuses.
///
/// Rules are keyed by `Unicode.Scalar` (stable across OS versions).
/// To stay idempotent, replacement values must never also be keys of the same map.
/// `OCRConfusionTable.default` satisfies this invariant (enforced by tests).
public struct OCRConfusionTable: Sendable, Equatable {

    /// Letters/symbols that should become digits in a numeric context.
    public let toDigit: [Unicode.Scalar: Unicode.Scalar]

    /// Digits that should become letters in an alphabetic context.
    public let toLetter: [Unicode.Scalar: Unicode.Scalar]

    public init(
        toDigit: [Unicode.Scalar: Unicode.Scalar],
        toLetter: [Unicode.Scalar: Unicode.Scalar]
    ) {
        self.toDigit = toDigit
        self.toLetter = toLetter
    }

    /// Conservative defaults for Latin-script card text.
    public static let `default` = OCRConfusionTable(
        toDigit: [
            "O": "0", "o": "0",
            "I": "1", "l": "1", "|": "1",
            "Z": "2",
            "S": "5", "s": "5",
            "B": "8"
        ],
        toLetter: [
            "0": "O",
            "1": "I",
            "3": "E",
            "4": "A",
            "5": "S",
            "8": "B"
        ]
    )
}
