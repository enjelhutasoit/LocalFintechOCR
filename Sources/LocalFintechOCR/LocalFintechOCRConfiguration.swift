//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import LocalFintechOCRCore

/// All tunable behavior of `LocalFintechOCRClient`, as plain data.
///
/// Start from `.default` and change only what you need:
///
///     var config = LocalFintechOCRConfiguration.default
///     config.banks.append(Bank(name: "SEABANK"))
public struct LocalFintechOCRConfiguration: Sendable, Equatable {

    /// OCR confusable-character rules. One table drives the card number extractor,
    /// the expiry parser, and the bank matcher, so repair behavior is always consistent.
    public var confusionTable: OCRConfusionTable

    /// Bank catalog. Order breaks ties between equally close matches.
    public var banks: [Bank]

    /// Card network rules. The first matching rule wins.
    public var networkRules: [CardNetworkRule]

    /// Allowed bank-name edits per 1000 characters (clamped to 0...1000 by the matcher).
    public var bankMaxDistancePerMille: Int

    /// Maximum normalized vertical distance for two text blocks to count as one row.
    public var rowTolerance: Double

    public init(
        confusionTable: OCRConfusionTable = .default,
        banks: [Bank] = Bank.defaults,
        networkRules: [CardNetworkRule] = CardNetworkRule.defaults,
        bankMaxDistancePerMille: Int = 300,
        rowTolerance: Double = 0.02
    ) {
        self.confusionTable = confusionTable
        self.banks = banks
        self.networkRules = networkRules
        self.bankMaxDistancePerMille = bankMaxDistancePerMille
        self.rowTolerance = rowTolerance
    }

    /// Conservative defaults for Indonesian cards.
    public static let `default` = LocalFintechOCRConfiguration()
}
