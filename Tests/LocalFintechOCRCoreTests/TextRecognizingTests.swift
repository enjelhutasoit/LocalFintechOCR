//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import LocalFintechOCRCore

final class TextRecognizingTests: XCTestCase {

    func testErrorCasesAreDistinctEquatableAndSendable() {
        XCTAssertEqual(TextRecognitionError.invalidImage, .invalidImage)
        XCTAssertNotEqual(TextRecognitionError.invalidImage, .recognitionFailed)
        XCTAssertNotEqual(TextRecognitionError.recognitionFailed, .cancelled)

        let error: any Error = TextRecognitionError.cancelled
        XCTAssertEqual(error as? TextRecognitionError, .cancelled)
        let sendable: any Sendable = TextRecognitionError.invalidImage
        XCTAssertNotNil(sendable)
    }

    func testProtocolCanBeImplementedByAnyValueType() async throws {
        let expected = [RecognizedTextLine(text: "BCA", minX: 0, centerY: 0.5)]
        let recognizer: any TextRecognizing = StubTextRecognizer.returning(expected)
        let lines = try await recognizer.recognizeText(in: Data([0x01]))
        XCTAssertEqual(lines, expected)
    }
}
