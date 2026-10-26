//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import LocalFintechOCRCore
import LocalFintechOCRVision

/// The public entry point of the SDK: card image (or text) in, typed `CardScanResult` out.
///
/// Everything runs on-device. The client is a `Sendable` value and is safe to call
/// from several tasks at once.
///
///     let client = LocalFintechOCRClient()
///     let card = try await client.scan(imageData: jpegData)
///     print(card.cardNumber)   // masked: •••• 1111
///
/// Printing or logging a `CardScanResult` never reveals the full card number.
/// The full value is available only through `cardNumber.digits`.
public struct LocalFintechOCRClient: Sendable {

    private let scanner: CardImageScanner
    private let pipeline: CardScanPipeline

    /// - Parameters:
    ///   - recognizer: text engine. Defaults to Apple Vision. Inject a stub in your own tests.
    ///   - configuration: tunable behavior. Defaults to `.default`.
    public init(
        recognizer: any TextRecognizing = VisionTextRecognizer(),
        configuration: LocalFintechOCRConfiguration = .default
    ) {
        let table = configuration.confusionTable
        let pipeline = CardScanPipeline(
            extractor: CardNumberExtractor(table: table),
            expiryParser: ExpiryDateParser(table: table),
            networkDetector: CardNetworkDetector(rules: configuration.networkRules),
            bankMatcher: BankNameMatcher(
                banks: configuration.banks,
                table: table,
                maxDistancePerMille: configuration.bankMaxDistancePerMille
            )
        )
        self.pipeline = pipeline
        self.scanner = CardImageScanner(
            recognizer: recognizer,
            assembler: RecognizedTextAssembler(rowTolerance: configuration.rowTolerance),
            pipeline: pipeline
        )
    }

    /// Reads a card from an encoded image (JPEG, PNG, HEIC...).
    ///
    /// - Throws: `CardImageScanError`.
    public func scan(imageData: Data) async throws -> CardScanResult {
        try await scanner.scan(imageData: imageData).get()
    }

    /// Reads a card from text you already recognized with another OCR engine.
    ///
    /// - Throws: `CardScanError`.
    public func scan(text: String) throws -> CardScanResult {
        try pipeline.scan(text).get()
    }
}
