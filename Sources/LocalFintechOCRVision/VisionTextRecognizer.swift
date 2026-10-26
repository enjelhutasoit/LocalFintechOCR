//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import Vision
import LocalFintechOCRCore

/// Apple Vision implementation of `TextRecognizing`. Runs fully on-device.
///
/// - `.accurate` recognition.
/// - `usesLanguageCorrection = false`: Vision's dictionary correction rewrites digits and
///   names unpredictably; repair is done by the SDK's deterministic sanitizer and matcher.
/// - Work runs on a background queue; the caller's thread is never blocked.
public struct VisionTextRecognizer: TextRecognizing {

    private let recognitionLanguages: [String]

    public init(recognitionLanguages: [String] = ["en-US"]) {
        self.recognitionLanguages = recognitionLanguages
    }

    public func recognizeText(in imageData: Data) async throws -> [RecognizedTextLine] {
        guard !imageData.isEmpty else { throw TextRecognitionError.invalidImage }

        let languages = recognitionLanguages
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(with: Result { try Self.perform(imageData, languages: languages) })
            }
        }
    }

    // MARK: - Private

    private static func perform(_ data: Data, languages: [String]) throws -> [RecognizedTextLine] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        request.recognitionLanguages = languages

        let handler = VNImageRequestHandler(data: data, options: [:])
        do {
            try handler.perform([request])
        } catch {
            throw TextRecognitionError.recognitionFailed
        }

        let observations = request.results ?? []
        return observations.compactMap { observation in
            guard let candidate = observation.topCandidates(1).first else { return nil }
            return RecognizedTextLine(
                text: candidate.string,
                minX: Double(observation.boundingBox.minX),
                centerY: Double(observation.boundingBox.midY)
            )
        }
    }
}
