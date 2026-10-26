//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// Why scanning an image produced no result.
public enum CardImageScanError: Error, Sendable, Equatable {
    /// The recognition engine failed.
    case recognition(TextRecognitionError)
    /// Text was recognized but did not contain a usable card.
    case scan(CardScanError)
}

/// Image in, `CardScanResult` out: recognizer, then text assembly, then `CardScanPipeline`.
///
/// Orchestration only. All components are injected, so tests run with a stub recognizer.
public struct CardImageScanner: Sendable {

    private let recognizer: any TextRecognizing
    private let assembler: RecognizedTextAssembler
    private let pipeline: CardScanPipeline

    public init(
        recognizer: any TextRecognizing,
        assembler: RecognizedTextAssembler = .default,
        pipeline: CardScanPipeline = .default
    ) {
        self.recognizer = recognizer
        self.assembler = assembler
        self.pipeline = pipeline
    }

    /// - Parameter imageData: encoded image bytes (JPEG, PNG, HEIC...).
    public func scan(imageData: Data) async -> Result<CardScanResult, CardImageScanError> {
        let lines: [RecognizedTextLine]
        do {
            lines = try await recognizer.recognizeText(in: imageData)
        } catch let error as TextRecognitionError {
            return .failure(.recognition(error))
        } catch is CancellationError {
            return .failure(.recognition(.cancelled))
        } catch {
            return .failure(.recognition(.recognitionFailed))
        }

        switch pipeline.scan(assembler.assemble(lines)) {
        case .success(let result): return .success(result)
        case .failure(let error): return .failure(.scan(error))
        }
    }
}
