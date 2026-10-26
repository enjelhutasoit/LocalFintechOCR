//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// Why text recognition failed.
public enum TextRecognitionError: Error, Sendable, Equatable {
    /// The image data was empty.
    case invalidImage
    /// The recognition engine failed (for example, the data was not a decodable image).
    case recognitionFailed
    /// The surrounding task was cancelled.
    case cancelled
}

/// Port for any engine that reads text from an encoded image (JPEG, PNG, HEIC...).
///
/// Core never depends on a concrete engine; `LocalFintechOCRVision` provides the Apple Vision adapter.
public protocol TextRecognizing: Sendable {
    func recognizeText(in imageData: Data) async throws -> [RecognizedTextLine]
}
