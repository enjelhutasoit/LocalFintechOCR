//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import LocalFintechOCR

/// Deterministic stand-in for Vision. Never touches Vision or real images.
struct FacadeStubRecognizer: TextRecognizing {
    let handler: @Sendable (Data) throws -> [RecognizedTextLine]

    func recognizeText(in imageData: Data) async throws -> [RecognizedTextLine] {
        try handler(imageData)
    }

    static func returning(_ lines: [RecognizedTextLine]) -> FacadeStubRecognizer {
        FacadeStubRecognizer { _ in lines }
    }

    static func failing(with error: any Error) -> FacadeStubRecognizer {
        FacadeStubRecognizer { _ in throw error }
    }
}
