//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// A bank the matcher can recognize: one canonical name plus optional aliases.
///
/// Names and aliases are compared after normalization (case, spaces, and punctuation
/// are ignored; only ASCII letters and digits are kept), so write them in plain Latin script.
public struct Bank: Sendable, Hashable {

    public let name: String
    public let aliases: [String]

    public init(name: String, aliases: [String] = []) {
        self.name = name
        self.aliases = aliases
    }

    /// Default Indonesian bank catalog. Order matters: it breaks ties between equally close matches.
    /// - Important: Review against the official bank list before each release.
    public static let defaults: [Bank] = [
        Bank(name: "BCA", aliases: ["BANK CENTRAL ASIA"]),
        Bank(name: "MANDIRI", aliases: ["BANK MANDIRI"]),
        Bank(name: "BNI", aliases: ["BANK NEGARA INDONESIA"]),
        Bank(name: "BRI", aliases: ["BANK RAKYAT INDONESIA"]),
        Bank(name: "CIMB NIAGA", aliases: ["CIMB", "BANK CIMB NIAGA"]),
        Bank(name: "PERMATA", aliases: ["BANK PERMATA"]),
        Bank(name: "DANAMON", aliases: ["BANK DANAMON"]),
        Bank(name: "BTN", aliases: ["BANK TABUNGAN NEGARA"]),
        Bank(name: "OCBC", aliases: ["OCBC NISP"]),
        Bank(name: "BSI", aliases: ["BANK SYARIAH INDONESIA"])
    ]
}
