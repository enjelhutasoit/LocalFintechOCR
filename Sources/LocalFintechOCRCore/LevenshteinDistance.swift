//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// Computes the Levenshtein edit distance (insertions, deletions, substitutions,
/// each with cost 1) between two strings.
///
/// - Comparison unit: Unicode scalar. This is stable across OS versions, unlike
///   grapheme-cluster segmentation. Consequently, a precomposed `é` and `e` followed
///   by a combining accent are considered different; normalize before calling if needed.
/// - Case-sensitive. Callers normalize case beforehand.
///
/// - Complexity: O(m·n) time. O(min(m, n)) memory (two DP rows sized by the shorter string).
public enum LevenshteinDistance {

    /// Returns the minimum number of single-scalar edits needed to turn `lhs` into `rhs`.
    public static func distance(_ lhs: String, _ rhs: String) -> Int {
        let lhsCount = lhs.unicodeScalars.count
        let rhsCount = rhs.unicodeScalars.count

        // The shorter string becomes the DP row; the longer one is streamed.
        let longer = lhsCount >= rhsCount ? lhs : rhs
        let shorter = lhsCount >= rhsCount ? rhs : lhs
        let longerCount = max(lhsCount, rhsCount)

        let shortScalars = Array(shorter.unicodeScalars)
        guard !shortScalars.isEmpty else { return longerCount }

        var previous = Array(0...shortScalars.count)
        var current = [Int](repeating: 0, count: shortScalars.count + 1)

        var row = 0
        for scalar in longer.unicodeScalars {
            row += 1
            current[0] = row

            for column in 1...shortScalars.count {
                let substitutionCost = scalar == shortScalars[column - 1] ? 0 : 1
                current[column] = min(
                    previous[column] + 1,
                    current[column - 1] + 1,
                    previous[column - 1] + substitutionCost
                )
            }
            swap(&previous, &current)
        }

        return previous[shortScalars.count]
    }
}
