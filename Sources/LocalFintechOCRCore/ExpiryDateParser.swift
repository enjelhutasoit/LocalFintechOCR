//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// Finds `MM/YY` and `MM/YYYY` expiry dates inside raw OCR text.
///
/// Rules:
/// - Exactly 2 month characters, `/`, then exactly 2 or 4 year characters.
/// - Characters are ASCII digits or keys of the table's `toDigit` map (OCR repair).
/// - The pattern must not touch an ASCII letter, digit, or another `/`
///   (rejects `01/12/34`, `112/34`, `A12/34`).
/// - At least half of the characters must be genuine ASCII digits.
/// - Month must be 1...12; the year must fall in 2000...2099.
///
/// Returns every valid candidate in order of appearance; choosing among them is the caller's job.
///
/// - Complexity: O(n) time, O(n) memory.
public struct ExpiryDateParser: Sendable {

    private let table: OCRConfusionTable
    private let sanitizer: OCRTextSanitizer

    public init(table: OCRConfusionTable = .default) {
        self.table = table
        self.sanitizer = OCRTextSanitizer(table: table)
    }

    /// Shared instance using the default confusion table.
    public static let `default` = ExpiryDateParser()

    public func parse(from text: String) -> [ExpiryDate] {
        let scalars = Array(text.unicodeScalars)
        var results: [ExpiryDate] = []

        for slash in scalars.indices where scalars[slash] == "/" {
            guard slash >= 2, isToken(scalars[slash - 2]), isToken(scalars[slash - 1]) else { continue }
            if slash >= 3, isBreaker(scalars[slash - 3]) { continue }

            var end = slash + 1
            while end < scalars.count, isToken(scalars[end]) { end += 1 }

            let yearLength = end - slash - 1
            guard yearLength == 2 || yearLength == 4 else { continue }
            if end < scalars.count, isBreaker(scalars[end]) { continue }

            let monthScalars = scalars[(slash - 2)..<slash]
            let yearScalars = scalars[(slash + 1)..<end]
            let all = Array(monthScalars) + Array(yearScalars)

            let realDigits = all.filter(isASCIIDigit).count
            guard realDigits * 2 >= all.count else { continue }

            let sanitized = Array(
                sanitizer.sanitize(String(String.UnicodeScalarView(all)), as: .numeric).unicodeScalars
            )
            guard sanitized.count == all.count,
                  let month = Int(String(String.UnicodeScalarView(sanitized[0..<2]))),
                  let rawYear = Int(String(String.UnicodeScalarView(sanitized[2...]))) else { continue }

            let year = yearLength == 2 ? 2000 + rawYear : rawYear
            if let expiry = ExpiryDate(month: month, year: year) {
                results.append(expiry)
            }
        }
        return results
    }

    // MARK: - Private

    private func isToken(_ scalar: Unicode.Scalar) -> Bool {
        isASCIIDigit(scalar) || table.toDigit[scalar] != nil
    }

    private func isBreaker(_ scalar: Unicode.Scalar) -> Bool {
        isASCIIDigit(scalar) || scalar == "/"
            || ("A"..."Z").contains(scalar) || ("a"..."z").contains(scalar)
    }

    private func isASCIIDigit(_ scalar: Unicode.Scalar) -> Bool {
        ("0"..."9").contains(scalar)
    }
}
