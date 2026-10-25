import Foundation

/// Validates payment card numbers (PAN) using the Luhn (mod 10) checksum.
///
/// Accepts only plain ASCII digits `0-9` with a length between 12 and 19.
/// Callers are responsible for stripping spaces/dashes beforehand.
///
/// - Important: Luhn is an integrity check against typos and OCR misreads.
///   It is NOT an authenticity or security check.
///
/// - Complexity: O(n) time, O(1) memory. Length is checked first, so
///   oversized input is rejected in O(1).
public enum LuhnValidator {

    private static let validLengthRange: ClosedRange<Int> = 12...19
    private static let asciiZero: UInt8 = 0x30
    private static let asciiNine: UInt8 = 0x39

    /// Returns `true` only when `input` is 12–19 ASCII digits with a valid Luhn checksum.
    public static func isValid(_ input: String) -> Bool {
        let bytes = input.utf8
        guard validLengthRange.contains(bytes.count) else { return false }

        var sum = 0
        var shouldDouble = false

        for byte in bytes.reversed() {
            guard byte >= asciiZero, byte <= asciiNine else { return false }

            var digit = Int(byte &- asciiZero)
            if shouldDouble {
                digit *= 2
                if digit > 9 { digit -= 9 }
            }
            sum += digit
            shouldDouble.toggle()
        }

        return sum % 10 == 0
    }
}
