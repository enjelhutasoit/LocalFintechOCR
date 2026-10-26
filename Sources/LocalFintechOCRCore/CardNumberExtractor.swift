//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// Finds Luhn-valid card numbers inside raw OCR text.
///
/// Candidate rules:
/// - A candidate is a run of ASCII digits or characters the table maps to digits,
///   with groups separated by exactly one space or dash.
/// - The run must not touch an ASCII letter (`A4111…`, `…1111A`).
/// - It must have 13...19 characters (separators excluded) and at least half of them
///   must be genuine ASCII digits, so letter-only text never turns into a number.
/// - After numeric sanitization the result must pass `CardNumber` (Luhn).
///
/// Runs longer than 19 characters are skipped, never split, to avoid inventing
/// card numbers out of longer digit sequences.
///
/// - Complexity: O(n) time and memory, single pass, no backtracking.
public struct CardNumberExtractor: Sendable {

    private static let lengthRange: ClosedRange<Int> = 13...19

    private let table: OCRConfusionTable
    private let sanitizer: OCRTextSanitizer

    public init(table: OCRConfusionTable = .default) {
        self.table = table
        self.sanitizer = OCRTextSanitizer(table: table)
    }

    /// Shared instance using the default confusion table.
    public static let `default` = CardNumberExtractor()

    /// Returns all valid card numbers in `text`, in order of appearance.
    public func extract(from text: String) -> [CardNumber] {
        let scalars = Array(text.unicodeScalars)
        var results: [CardNumber] = []
        var index = 0

        while index < scalars.count {
            guard isCandidate(scalars[index]) else {
                index += 1
                continue
            }

            let start = index
            var end = index + 1
            while end < scalars.count {
                if isCandidate(scalars[end]) {
                    end += 1
                } else if isSeparator(scalars[end]),
                          end + 1 < scalars.count,
                          isCandidate(scalars[end + 1]) {
                    end += 2
                } else {
                    break
                }
            }
            index = end

            let touchesLetter = (start > 0 && isASCIILetter(scalars[start - 1]))
                || (end < scalars.count && isASCIILetter(scalars[end]))
            guard !touchesLetter else { continue }

            if let card = makeCard(from: scalars[start..<end]) {
                results.append(card)
            }
        }
        return results
    }

    // MARK: - Private

    private func makeCard(from run: ArraySlice<Unicode.Scalar>) -> CardNumber? {
        var count = 0
        var realDigits = 0
        for scalar in run where !isSeparator(scalar) {
            count += 1
            if isASCIIDigit(scalar) { realDigits += 1 }
        }
        guard Self.lengthRange.contains(count), realDigits * 2 >= count else { return nil }

        var stripped = String.UnicodeScalarView()
        for scalar in run where !isSeparator(scalar) {
            stripped.append(scalar)
        }
        return CardNumber(digits: sanitizer.sanitize(String(stripped), as: .numeric))
    }

    private func isCandidate(_ scalar: Unicode.Scalar) -> Bool {
        isASCIIDigit(scalar) || table.toDigit[scalar] != nil
    }

    private func isSeparator(_ scalar: Unicode.Scalar) -> Bool {
        scalar == " " || scalar == "-"
    }

    private func isASCIIDigit(_ scalar: Unicode.Scalar) -> Bool {
        ("0"..."9").contains(scalar)
    }

    private func isASCIILetter(_ scalar: Unicode.Scalar) -> Bool {
        ("A"..."Z").contains(scalar) || ("a"..."z").contains(scalar)
    }
}
