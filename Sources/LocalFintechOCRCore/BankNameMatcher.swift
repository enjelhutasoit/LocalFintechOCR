//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// The result of a successful bank lookup.
public struct BankMatch: Sendable, Equatable {

    public let bank: Bank
    /// Levenshtein distance between the normalized input and the matched name or alias.
    public let distance: Int

    public init(bank: Bank, distance: Int) {
        self.bank = bank
        self.distance = distance
    }

    /// `true` when the normalized input equals a name or alias exactly.
    public var isExact: Bool { distance == 0 }
}

/// Matches noisy OCR text to a bank in a catalog.
///
/// Pipeline: alphabetic OCR repair, ASCII uppercase, keep only `A-Z`/`0-9`,
/// then Levenshtein distance against every normalized name and alias.
///
/// - A candidate is accepted when `distance <= max(inputLength, keyLength) * perMille / 1000`
///   (integer math). With the default 300, names of 3 letters need an exact match.
/// - The smallest distance wins. Ties go to the bank listed first in the catalog.
/// - Returns `nil` when nothing is close enough. That is a valid answer, not an error.
///
/// - Complexity: O(1) pruning per key by length gap, then O(m·n) time and O(min(m, n))
///   memory per surviving key.
public struct BankNameMatcher: Sendable {

    private struct Entry: Sendable {
        let bank: Bank
        let keys: [String]
    }

    private let entries: [Entry]
    private let sanitizer: OCRTextSanitizer
    private let maxDistancePerMille: Int

    /// - Parameter maxDistancePerMille: allowed edits per 1000 characters; clamped to 0...1000.
    public init(
        banks: [Bank] = Bank.defaults,
        table: OCRConfusionTable = .default,
        maxDistancePerMille: Int = 300
    ) {
        self.sanitizer = OCRTextSanitizer(table: table)
        self.maxDistancePerMille = min(max(maxDistancePerMille, 0), 1_000)
        self.entries = banks.map { bank in
            let keys = ([bank.name] + bank.aliases)
                .map(Self.normalize)
                .filter { !$0.isEmpty }
            return Entry(bank: bank, keys: keys)
        }
    }

    /// Shared instance using the default catalog, table, and threshold.
    public static let `default` = BankNameMatcher()

    /// Returns the closest bank for `text`, or `nil` when none is close enough.
    public func match(_ text: String) -> BankMatch? {
        let query = Self.normalize(sanitizer.sanitize(text, as: .alphabetic))
        let queryLength = query.utf8.count
        guard queryLength > 0 else { return nil }

        var bestCandidate: (entryIndex: Int, distance: Int)?

        for (index, entry) in entries.enumerated() {
            for key in entry.keys {
                let keyLength = key.utf8.count
                let allowed = max(queryLength, keyLength) * maxDistancePerMille / 1_000

                // Levenshtein distance is never smaller than the length gap.
                guard abs(queryLength - keyLength) <= allowed else { continue }

                let distance = LevenshteinDistance.distance(query, key)
                guard distance <= allowed else { continue }

                if let current = bestCandidate, current.distance <= distance { continue }
                bestCandidate = (index, distance)
            }
        }

        guard let winner = bestCandidate else { return nil }
        return BankMatch(bank: entries[winner.entryIndex].bank, distance: winner.distance)
    }

    // MARK: - Private

    /// Keeps ASCII letters (uppercased) and digits; drops everything else.
    /// Uppercasing is done by hand so the result never depends on the OS Unicode tables.
    private static func normalize(_ text: String) -> String {
        var output = String.UnicodeScalarView()
        for scalar in text.unicodeScalars {
            switch scalar.value {
            case 0x41...0x5A, 0x30...0x39:
                output.append(scalar)
            case 0x61...0x7A:
                output.append(Unicode.Scalar(UInt8(scalar.value - 0x20)))
            default:
                break
            }
        }
        return String(output)
    }
}
