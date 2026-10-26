//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// Turns raw OCR text into a typed `CardScanResult`.
///
/// Orchestration only; every rule lives in an injected component:
/// - `CardNumberExtractor`: card number (Luhn-validated, OCR-repaired).
/// - `CardNetworkDetector`: network from the number.
/// - `ExpiryDateParser`: expiry candidates; the latest one is used.
/// - `BankNameMatcher`: applied to each line; smallest distance wins, earlier line breaks ties.
///
/// Policy: identical card numbers are merged; different ones fail as ambiguous.
///
/// - Complexity: O(n) over the text for number/date extraction, plus O(1)-pruned
///   bank matching per line and key.
public struct CardScanPipeline: Sendable {

    private let extractor: CardNumberExtractor
    private let expiryParser: ExpiryDateParser
    private let networkDetector: CardNetworkDetector
    private let bankMatcher: BankNameMatcher

    public init(
        extractor: CardNumberExtractor = .default,
        expiryParser: ExpiryDateParser = .default,
        networkDetector: CardNetworkDetector = .default,
        bankMatcher: BankNameMatcher = .default
    ) {
        self.extractor = extractor
        self.expiryParser = expiryParser
        self.networkDetector = networkDetector
        self.bankMatcher = bankMatcher
    }

    /// Shared instance using all default components.
    public static let `default` = CardScanPipeline()

    public func scan(_ text: String) -> Result<CardScanResult, CardScanError> {
        guard !isBlank(text) else { return .failure(.emptyInput) }

        var seen = Set<CardNumber>()
        let cards = extractor.extract(from: text).filter { seen.insert($0).inserted }

        guard let card = cards.first else { return .failure(.cardNumberNotFound) }
        guard cards.count == 1 else { return .failure(.ambiguousCardNumbers) }

        let expiry = expiryParser.parse(from: text).max {
            ($0.year, $0.month) < ($1.year, $1.month)
        }

        return .success(
            CardScanResult(
                cardNumber: card,
                network: networkDetector.detect(card),
                expiry: expiry,
                bank: bestBankMatch(in: text)
            )
        )
    }

    // MARK: - Private

    private func bestBankMatch(in text: String) -> BankMatch? {
        var best: BankMatch?
        for line in lines(of: text) {
            guard let candidate = bankMatcher.match(line) else { continue }
            // Strictly smaller wins, so an equal distance keeps the earlier line.
            if let current = best, current.distance <= candidate.distance { continue }
            best = candidate
        }
        return best
    }

    private func lines(of text: String) -> [String] {
        text.unicodeScalars
            .split(omittingEmptySubsequences: true) { $0 == "\n" || $0 == "\r" }
            .map { String(String.UnicodeScalarView($0)) }
    }

    private func isBlank(_ text: String) -> Bool {
        text.unicodeScalars.allSatisfy { $0 == " " || $0 == "\n" || $0 == "\r" || $0 == "\t" }
    }
}
