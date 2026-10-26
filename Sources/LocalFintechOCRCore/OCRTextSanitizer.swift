//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// The kind of text a fragment is expected to contain.
/// The caller decides; the sanitizer never guesses.
public enum OCRCharacterContext: Sendable {
    /// Expected to contain digits (card number, expiry date).
    case numeric
    /// Expected to contain letters (bank name, cardholder name).
    case alphabetic
}

/// Corrects visually confusable OCR characters according to an `OCRConfusionTable`.
///
/// Guarantees:
/// - Length-preserving (same number of Unicode scalars).
/// - Idempotent for tables that satisfy the invariant documented on `OCRConfusionTable`.
/// - Characters without a rule (separators, unknown letters, non-ASCII) pass through untouched.
/// - Does not change letter case and does not validate.
///
/// - Complexity: O(n) time, O(n) memory for the result.
public struct OCRTextSanitizer: Sendable {

    private let table: OCRConfusionTable

    public init(table: OCRConfusionTable = .default) {
        self.table = table
    }

    /// Shared instance using the default confusion table.
    public static let `default` = OCRTextSanitizer()

    /// Returns `input` with confusable scalars replaced according to `context`.
    public func sanitize(_ input: String, as context: OCRCharacterContext) -> String {
        let rules: [Unicode.Scalar: Unicode.Scalar]
        switch context {
        case .numeric: rules = table.toDigit
        case .alphabetic: rules = table.toLetter
        }

        var output = String.UnicodeScalarView()
        for scalar in input.unicodeScalars {
            output.append(rules[scalar] ?? scalar)
        }
        return String(output)
    }
}
