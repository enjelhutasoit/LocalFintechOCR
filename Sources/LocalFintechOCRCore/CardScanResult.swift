//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// Structured data extracted from one card scan.
///
/// Only `cardNumber` is guaranteed; the other fields are `nil` when not found.
/// Printing or dumping this value never reveals the full card number
/// (`CardNumber` masks all of its representations).
public struct CardScanResult: Sendable, Equatable {

    public let cardNumber: CardNumber
    /// `.unknown` when the network is unsupported; it is not an error.
    public let network: CardNetwork
    /// Latest valid `MM/YY` date found, if any. Check expiry with `isExpired(asOf:calendar:)`.
    public let expiry: ExpiryDate?
    /// Closest catalog bank found, if any.
    public let bank: BankMatch?

    public init(
        cardNumber: CardNumber,
        network: CardNetwork,
        expiry: ExpiryDate?,
        bank: BankMatch?
    ) {
        self.cardNumber = cardNumber
        self.network = network
        self.expiry = expiry
        self.bank = bank
    }
}

/// Why a scan produced no result.
public enum CardScanError: Error, Sendable, Equatable {
    /// The text was empty or whitespace only.
    case emptyInput
    /// No Luhn-valid card number was found.
    case cardNumberNotFound
    /// Two or more different card numbers were found; the pipeline refuses to guess.
    case ambiguousCardNumbers
}
