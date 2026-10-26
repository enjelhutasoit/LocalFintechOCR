//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import LocalFintechOCRCore

final class LevenshteinDistanceTests: XCTestCase {

    // MARK: - Reference oracle (naive full-matrix, test-only)

    private func referenceDistance(_ lhs: String, _ rhs: String) -> Int {
        let a = Array(lhs.unicodeScalars)
        let b = Array(rhs.unicodeScalars)
        var matrix = [[Int]](repeating: [Int](repeating: 0, count: b.count + 1), count: a.count + 1)

        for i in 0...a.count { matrix[i][0] = i }
        for j in 0...b.count { matrix[0][j] = j }

        for i in 0..<a.count {
            for j in 0..<b.count {
                let cost = a[i] == b[j] ? 0 : 1
                matrix[i + 1][j + 1] = min(
                    matrix[i][j + 1] + 1,
                    matrix[i + 1][j] + 1,
                    matrix[i][j] + cost
                )
            }
        }
        return matrix[a.count][b.count]
    }

    /// Deterministic enumeration of every string over `alphabet` with length 0...maxLength.
    private func allStrings(alphabet: [Character], maxLength: Int) -> [String] {
        var result = [""]
        var frontier = [""]
        for _ in 0..<maxLength {
            frontier = frontier.flatMap { prefix in alphabet.map { prefix + String($0) } }
            result += frontier
        }
        return result
    }

    // MARK: - Empty inputs

    func testBothEmptyIsZero() {
        XCTAssertEqual(LevenshteinDistance.distance("", ""), 0)
    }

    func testEmptyAgainstNonEmptyEqualsLengthInBothDirections() {
        XCTAssertEqual(LevenshteinDistance.distance("", "abc"), 3)
        XCTAssertEqual(LevenshteinDistance.distance("abc", ""), 3)
    }

    // MARK: - Identity

    func testIdenticalStringsHaveZeroDistance() {
        for value in ["a", "MANDIRI", "BCA", "4111111111111111", "caf\u{E9}", "🙂🙂"] {
            XCTAssertEqual(LevenshteinDistance.distance(value, value), 0)
        }
    }

    // MARK: - Known results

    func testKnownDistances() {
        let cases: [(lhs: String, rhs: String, expected: Int)] = [
            ("kitten", "sitting", 3),
            ("flaw", "lawn", 2),
            ("saturday", "sunday", 3),
            ("intention", "execution", 5),
            ("book", "back", 2),
            ("a", "b", 1),
            ("ab", "ba", 2),
            // Domain-relevant OCR confusions.
            ("MANDIRI", "M4ND1R1", 3),
            ("BNI", "BRI", 1),
            ("BCA", "BCAA", 1),
            ("CIMB", "CIMB NIAGA", 6)
        ]
        for testCase in cases {
            XCTAssertEqual(
                LevenshteinDistance.distance(testCase.lhs, testCase.rhs),
                testCase.expected,
                "distance(\(testCase.lhs), \(testCase.rhs))"
            )
        }
    }

    func testIsCaseSensitive() {
        XCTAssertEqual(LevenshteinDistance.distance("a", "A"), 1)
        XCTAssertEqual(LevenshteinDistance.distance("mandiri", "MANDIRI"), 7)
    }

    // MARK: - Unicode (scalar-level, stable across OS versions)

    func testUnicodeScalarsCountAsSingleUnits() {
        XCTAssertEqual(LevenshteinDistance.distance("🙂", "🙃"), 1)
        XCTAssertEqual(LevenshteinDistance.distance("a🙂b", "ab"), 1)
        XCTAssertEqual(LevenshteinDistance.distance("caf\u{E9}", "cafe"), 1)
        XCTAssertEqual(LevenshteinDistance.distance("日本語", "日本"), 1)
    }

    // MARK: - Oracle equivalence (exhaustive, deterministic)

    func testMatchesReferenceImplementationForAllShortStrings() {
        let strings = allStrings(alphabet: ["a", "b", "c"], maxLength: 4)
        XCTAssertEqual(strings.count, 121)

        for lhs in strings {
            for rhs in strings {
                let actual = LevenshteinDistance.distance(lhs, rhs)
                let expected = referenceDistance(lhs, rhs)
                XCTAssertEqual(actual, expected, "distance('\(lhs)', '\(rhs)')")
            }
        }
    }

    // MARK: - Metric properties

    func testSymmetryAndBounds() {
        let strings = allStrings(alphabet: ["a", "b", "c"], maxLength: 4)

        for lhs in strings {
            for rhs in strings {
                let forward = LevenshteinDistance.distance(lhs, rhs)
                let backward = LevenshteinDistance.distance(rhs, lhs)
                let lhsLength = lhs.unicodeScalars.count
                let rhsLength = rhs.unicodeScalars.count

                XCTAssertEqual(forward, backward, "symmetry '\(lhs)' '\(rhs)'")
                XCTAssertGreaterThanOrEqual(forward, abs(lhsLength - rhsLength))
                XCTAssertLessThanOrEqual(forward, max(lhsLength, rhsLength))
                XCTAssertEqual(forward == 0, lhs == rhs)
            }
        }
    }

    func testTriangleInequality() {
        let strings = allStrings(alphabet: ["a", "b"], maxLength: 4)
        XCTAssertEqual(strings.count, 31)

        for x in strings {
            for y in strings {
                for z in strings {
                    let direct = LevenshteinDistance.distance(x, z)
                    let viaY = LevenshteinDistance.distance(x, y) + LevenshteinDistance.distance(y, z)
                    XCTAssertLessThanOrEqual(direct, viaY, "triangle '\(x)' '\(y)' '\(z)'")
                }
            }
        }
    }

    // MARK: - Robustness (no timing assertions; correctness only)

    func testVeryLongInputAgainstEmptyDoesNotCrash() {
        let huge = String(repeating: "a", count: 1_000_000)
        XCTAssertEqual(LevenshteinDistance.distance(huge, ""), 1_000_000)
        XCTAssertEqual(LevenshteinDistance.distance("", huge), 1_000_000)
    }

    func testLongCompletelyDifferentStrings() {
        let lhs = String(repeating: "a", count: 1_500)
        let rhs = String(repeating: "b", count: 1_500)
        XCTAssertEqual(LevenshteinDistance.distance(lhs, rhs), 1_500)
    }

    func testLongStringsWithDifferentLengths() {
        let lhs = String(repeating: "a", count: 1_500)
        let rhs = String(repeating: "a", count: 1_200)
        XCTAssertEqual(LevenshteinDistance.distance(lhs, rhs), 300)
        XCTAssertEqual(LevenshteinDistance.distance(rhs, lhs), 300)
    }
}
