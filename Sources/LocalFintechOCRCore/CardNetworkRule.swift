//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// Supported card networks. `.unknown` is a valid result, not an error.
public enum CardNetwork: String, Sendable, CaseIterable {
    case visa
    case mastercard
    case jcb
    case unionPay
    case gpn
    case unknown
}

/// A numeric range over the first `digitCount` digits of a PAN (a BIN/IIN prefix range).
public struct BINRange: Sendable, Equatable {

    /// How many leading digits are compared. Only 1...9 can match (overflow-safe).
    public let digitCount: Int
    public let range: ClosedRange<Int>

    public init(digitCount: Int, range: ClosedRange<Int>) {
        self.digitCount = digitCount
        self.range = range
    }

    /// `digits` must be ASCII digits (guaranteed when it comes from `CardNumber`).
    public func matches(_ digits: String) -> Bool {
        guard (1...9).contains(digitCount), digits.utf8.count >= digitCount else { return false }
        var value = 0
        for byte in digits.utf8.prefix(digitCount) {
            guard byte >= 0x30, byte <= 0x39 else { return false }
            value = value * 10 + Int(byte &- 0x30)
        }
        return range.contains(value)
    }
}

/// Data describing how to recognize one card network.
public struct CardNetworkRule: Sendable, Equatable {

    public let network: CardNetwork
    public let binRanges: [BINRange]
    /// Accepted total PAN lengths.
    public let lengths: Set<Int>

    public init(network: CardNetwork, binRanges: [BINRange], lengths: Set<Int>) {
        self.network = network
        self.binRanges = binRanges
        self.lengths = lengths
    }

    /// Default non-overlapping rules.
    /// - Important: Review against the networks' current published BIN ranges before each release.
    public static let defaults: [CardNetworkRule] = [
        CardNetworkRule(
            network: .visa,
            binRanges: [BINRange(digitCount: 1, range: 4...4)],
            lengths: [13, 16, 19]
        ),
        CardNetworkRule(
            network: .mastercard,
            binRanges: [
                BINRange(digitCount: 2, range: 51...55),
                BINRange(digitCount: 4, range: 2221...2720)
            ],
            lengths: [16]
        ),
        CardNetworkRule(
            network: .jcb,
            binRanges: [BINRange(digitCount: 4, range: 3528...3589)],
            lengths: [16, 17, 18, 19]
        ),
        CardNetworkRule(
            network: .unionPay,
            binRanges: [BINRange(digitCount: 2, range: 62...62)],
            lengths: [16, 17, 18, 19]
        ),
        CardNetworkRule(
            network: .gpn,
            binRanges: [BINRange(digitCount: 4, range: 1946...1946)],
            lengths: [16]
        )
    ]
}
