//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import LocalFintechOCRCore

/// Deterministic stand-in for a real recognizer. Never touches Vision.
struct StubTextRecognizer: TextRecognizing {
    let handler: @Sendable (Data) throws -> [RecognizedTextLine]

    func recognizeText(in imageData: Data) async throws -> [RecognizedTextLine] {
        try handler(imageData)
    }

    static func returning(_ lines: [RecognizedTextLine]) -> StubTextRecognizer {
        StubTextRecognizer { _ in lines }
    }

    static func failing(with error: any Error) -> StubTextRecognizer {
        StubTextRecognizer { _ in throw error }
    }
}
