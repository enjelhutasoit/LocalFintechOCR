//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// Identifies a card's network from its BIN prefix and length.
///
/// Rules are evaluated in order; the first match wins. No match yields `.unknown`.
/// This is a prefix heuristic, not proof that the card is genuine.
///
/// - Complexity: O(r·b) per card for r rules and b ranges per rule (both tiny constants).
public struct CardNetworkDetector: Sendable {

    private let rules: [CardNetworkRule]

    public init(rules: [CardNetworkRule] = CardNetworkRule.defaults) {
        self.rules = rules
    }

    /// Shared instance using the default rules.
    public static let `default` = CardNetworkDetector()

    public func detect(_ card: CardNumber) -> CardNetwork {
        let digits = card.digits
        let length = digits.utf8.count

        for rule in rules where rule.lengths.contains(length) {
            if rule.binRanges.contains(where: { $0.matches(digits) }) {
                return rule.network
            }
        }
        return .unknown
    }
}
