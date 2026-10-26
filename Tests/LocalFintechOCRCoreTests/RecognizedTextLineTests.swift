//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import LocalFintechOCRCore

final class RecognizedTextLineTests: XCTestCase {

    func testInitKeepsValues() {
        let line = RecognizedTextLine(text: "BCA", minX: 0.25, centerY: 0.75)
        XCTAssertEqual(line.text, "BCA")
        XCTAssertEqual(line.minX, 0.25)
        XCTAssertEqual(line.centerY, 0.75)
    }

    func testNonFiniteCoordinatesBecomeZero() {
        let line = RecognizedTextLine(text: "x", minX: .nan, centerY: .infinity)
        XCTAssertEqual(line.minX, 0)
        XCTAssertEqual(line.centerY, 0)
        XCTAssertEqual(RecognizedTextLine(text: "x", minX: -.infinity, centerY: 0.5).minX, 0)
    }

    func testTextRepresentationsNeverExposeRawText() {
        let line = RecognizedTextLine(text: "4111 1111 1111 1111", minX: 0.1, centerY: 0.5)
        var dumped = ""
        dump(line, to: &dumped)

        let outputs = [
            line.description, line.debugDescription,
            "\(line)", String(describing: line), String(reflecting: line), dumped
        ]
        for output in outputs {
            XCTAssertFalse(output.contains("4111"), output)
        }
    }

    func testEqualityAndSendable() {
        let first = RecognizedTextLine(text: "A", minX: 0, centerY: 0)
        XCTAssertEqual(first, RecognizedTextLine(text: "A", minX: 0, centerY: 0))
        XCTAssertNotEqual(first, RecognizedTextLine(text: "B", minX: 0, centerY: 0))
        XCTAssertNotEqual(first, RecognizedTextLine(text: "A", minX: 0.1, centerY: 0))
        let value: any Sendable = first
        XCTAssertNotNil(value)
    }
}
