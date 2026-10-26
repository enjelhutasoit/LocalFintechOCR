//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import LocalFintechOCRCore
import LocalFintechOCRVision

/// Deliberately limited to deterministic behavior.
/// Real OCR output and Vision's reaction to corrupt images vary across OS versions,
/// so neither is asserted here. Domain logic is covered with stubs in Core tests.
final class VisionTextRecognizerTests: XCTestCase {

    func testEmptyImageDataIsRejectedAsInvalidImage() async {
        do {
            _ = try await VisionTextRecognizer().recognizeText(in: Data())
            XCTFail("Expected invalidImage")
        } catch {
            XCTAssertEqual(error as? TextRecognitionError, .invalidImage)
        }
    }

    func testConformsToTextRecognizing() {
        let recognizer: any TextRecognizing = VisionTextRecognizer()
        XCTAssertNotNil(recognizer)
    }

    func testCanBeCreatedWithCustomLanguages() {
        let value: any Sendable = VisionTextRecognizer(recognitionLanguages: ["en-US", "id-ID"])
        XCTAssertNotNil(value)
    }
}
