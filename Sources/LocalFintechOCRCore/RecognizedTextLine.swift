//
// Copyright (c) 2026 Enjel Hutasoit
//
import Foundation

/// One block of text found in an image, with its position.
///
/// Coordinates are normalized (0...1) with the origin at the bottom-left, matching Vision.
/// Non-finite coordinates are replaced by 0 so sorting never sees `NaN`.
///
/// The raw text may contain PII, so every textual and reflective representation is redacted.
public struct RecognizedTextLine: Sendable, Equatable, CustomStringConvertible,
                                  CustomDebugStringConvertible, CustomReflectable {

    public let text: String
    /// Left edge of the block.
    public let minX: Double
    /// Vertical center of the block (1 = top of the image).
    public let centerY: Double

    public init(text: String, minX: Double, centerY: Double) {
        self.text = text
        self.minX = minX.isFinite ? minX : 0
        self.centerY = centerY.isFinite ? centerY : 0
    }

    public var description: String { "RecognizedTextLine(<redacted>)" }
    public var debugDescription: String { description }

    public var customMirror: Mirror {
        Mirror(self, children: ["minX": minX, "centerY": centerY], displayStyle: .struct)
    }
}
