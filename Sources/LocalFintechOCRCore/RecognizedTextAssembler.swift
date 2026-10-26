//
// Copyright (c) 2026 Enjel Hutasoit
//


import Foundation

/// Rebuilds reading-order text from positioned blocks.
///
/// - Rows run top to bottom. Blocks whose `centerY` is within `rowTolerance` of the
///   first block of a row belong to that row and are ordered left to right.
/// - Blocks in a row are joined with a space; rows are joined with `\n`.
/// - Blank blocks are dropped. Exact position ties keep the original order,
///   so the result is deterministic.
///
/// - Complexity: O(n log n) time, O(n) memory.
public struct RecognizedTextAssembler: Sendable {

    private let rowTolerance: Double

    /// - Parameter rowTolerance: maximum vertical distance (normalized) inside one row; negatives become 0.
    public init(rowTolerance: Double = 0.02) {
        self.rowTolerance = rowTolerance.isFinite ? max(rowTolerance, 0) : 0
    }

    public static let `default` = RecognizedTextAssembler()

    public func assemble(_ lines: [RecognizedTextLine]) -> String {
        let usable = lines.enumerated().filter {
            !$0.element.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        let topToBottom = usable.sorted { lhs, rhs in
            if lhs.element.centerY != rhs.element.centerY { return lhs.element.centerY > rhs.element.centerY }
            if lhs.element.minX != rhs.element.minX { return lhs.element.minX < rhs.element.minX }
            return lhs.offset < rhs.offset
        }

        var rows: [[(offset: Int, element: RecognizedTextLine)]] = []
        var anchorY = 0.0
        for item in topToBottom {
            if !rows.isEmpty, anchorY - item.element.centerY <= rowTolerance {
                rows[rows.count - 1].append(item)
            } else {
                rows.append([item])
                anchorY = item.element.centerY
            }
        }

        return rows
            .map { row in
                row.sorted { lhs, rhs in
                    if lhs.element.minX != rhs.element.minX { return lhs.element.minX < rhs.element.minX }
                    return lhs.offset < rhs.offset
                }
                .map(\.element.text)
                .joined(separator: " ")
            }
            .joined(separator: "\n")
    }
}
