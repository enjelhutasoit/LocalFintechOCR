//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import LocalFintechOCRCore

final class RecognizedTextAssemblerTests: XCTestCase {

    private let assembler = RecognizedTextAssembler.default

    private func line(_ text: String, x: Double = 0, y: Double) -> RecognizedTextLine {
        RecognizedTextLine(text: text, minX: x, centerY: y)
    }

    // MARK: - Basics

    func testEmptyInputGivesEmptyString() {
        XCTAssertEqual(assembler.assemble([]), "")
    }

    func testSingleLineIsReturnedAsIs() {
        XCTAssertEqual(assembler.assemble([line("4111 1111 1111 1111", y: 0.5)]), "4111 1111 1111 1111")
    }

    // MARK: - Ordering

    func testOrdersRowsFromTopToBottom() {
        let lines = [line("C", y: 0.2), line("A", y: 0.8), line("B", y: 0.5)]
        XCTAssertEqual(assembler.assemble(lines), "A\nB\nC")
    }

    func testResultDoesNotDependOnInputOrder() {
        let lines = [line("A", y: 0.9), line("B", y: 0.6), line("C", y: 0.3), line("D", x: 0.5, y: 0.3)]
        let expected = assembler.assemble(lines)
        XCTAssertEqual(assembler.assemble(lines.reversed()), expected)
        XCTAssertEqual(expected, "A\nB\nC D")
    }

    // MARK: - Row grouping

    func testBlocksOnTheSameRowAreJoinedLeftToRight() {
        let lines = [
            line("1111 1111", x: 0.5, y: 0.50),
            line("4111 1111", x: 0.1, y: 0.51)
        ]
        XCTAssertEqual(assembler.assemble(lines), "4111 1111 1111 1111")
    }

    func testBlocksFarApartVerticallyStaySeparateRows() {
        XCTAssertEqual(assembler.assemble([line("A", y: 0.5), line("B", y: 0.4)]), "A\nB")
    }

    func testCustomToleranceCanMergeRows() {
        let wide = RecognizedTextAssembler(rowTolerance: 0.2)
        XCTAssertEqual(wide.assemble([line("A", y: 0.5), line("B", x: 0.5, y: 0.4)]), "A B")
    }

    func testNegativeToleranceIsTreatedAsZero() {
        let strict = RecognizedTextAssembler(rowTolerance: -1)
        XCTAssertEqual(strict.assemble([line("A", y: 0.5), line("B", y: 0.499)]), "A\nB")
        XCTAssertEqual(strict.assemble([line("A", y: 0.5), line("B", x: 0.5, y: 0.5)]), "A B")
    }

    func testRowToleranceIsMeasuredFromTheFirstBlockOfTheRow() {
        // 0.50 and 0.49 are within 0.015; 0.48 is 0.02 from the anchor, so it starts a new row.
        let custom = RecognizedTextAssembler(rowTolerance: 0.015)
        let lines = [line("A", x: 0.0, y: 0.50), line("B", x: 0.1, y: 0.49), line("C", x: 0.0, y: 0.48)]
        XCTAssertEqual(custom.assemble(lines), "A B\nC")
    }

    func testIdenticalPositionsKeepOriginalOrder() {
        XCTAssertEqual(assembler.assemble([line("first", y: 0.5), line("second", y: 0.5)]), "first second")
    }

    // MARK: - Filtering and hostile input

    func testBlankLinesAreDropped() {
        let lines = [line("  ", y: 0.9), line("A", y: 0.5), line("\t\n", y: 0.1)]
        XCTAssertEqual(assembler.assemble(lines), "A")
        XCTAssertEqual(assembler.assemble([line(" ", y: 0.5)]), "")
    }

    func testNonFiniteCoordinatesDoNotCrash() {
        let lines = [
            RecognizedTextLine(text: "A", minX: .nan, centerY: .nan),
            RecognizedTextLine(text: "B", minX: .infinity, centerY: -.infinity)
        ]
        let output = assembler.assemble(lines)
        XCTAssertTrue(output.contains("A"))
        XCTAssertTrue(output.contains("B"))
    }

    func testHandlesManyLinesWithoutCrashing() {
        let strict = RecognizedTextAssembler(rowTolerance: 0)
        let lines = (0..<100_000).map { line("x\($0)", y: Double($0) / 100_000) }
        let output = strict.assemble(lines)
        XCTAssertTrue(output.hasPrefix("x99999\n"))
        XCTAssertTrue(output.hasSuffix("\nx0"))
        XCTAssertEqual(output.utf8.filter { $0 == 0x0A }.count, 99_999)
    }

    func testIsSendable() {
        let value: any Sendable = RecognizedTextAssembler.default
        XCTAssertNotNil(value)
    }
}
