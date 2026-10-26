//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import LocalFintechOCRCore

final class CardImageScannerTests: XCTestCase {

    private let imageData = Data([0x01, 0x02, 0x03])

    // Deliberately out of reading order.
    private let cardLines = [
        RecognizedTextLine(text: "VALID THRU 12/34", minX: 0.5, centerY: 0.2),
        RecognizedTextLine(text: "4111 1111 1111 1111", minX: 0.1, centerY: 0.5),
        RecognizedTextLine(text: "BANK MANDIRI", minX: 0.1, centerY: 0.9)
    ]

    private func scan(_ recognizer: StubTextRecognizer) async -> Result<CardScanResult, CardImageScanError> {
        await CardImageScanner(recognizer: recognizer).scan(imageData: imageData)
    }

    private func failure(_ recognizer: StubTextRecognizer) async -> CardImageScanError? {
        if case .failure(let error) = await scan(recognizer) { return error }
        return nil
    }

    // MARK: - Success

    func testScansRecognizedLinesIntoTypedResult() async throws {
        let result = try await scan(.returning(cardLines)).get()
        XCTAssertEqual(result.cardNumber.digits, "4111111111111111")
        XCTAssertEqual(result.network, .visa)
        XCTAssertEqual(result.expiry?.formatted, "12/34")
        XCTAssertEqual(result.bank?.bank.name, "MANDIRI")
    }

    func testCardNumberSplitAcrossBlocksOnOneRowStillSucceeds() async throws {
        let lines = [
            RecognizedTextLine(text: "1111 1111", minX: 0.5, centerY: 0.50),
            RecognizedTextLine(text: "4111 1111", minX: 0.1, centerY: 0.51)
        ]
        let result = try await scan(.returning(lines)).get()
        XCTAssertEqual(result.cardNumber.digits, "4111111111111111")
    }

    func testForwardsTheExactImageDataToTheRecognizer() async throws {
        let payload = Data("4111 1111 1111 1111".utf8)
        let recognizer = StubTextRecognizer { data in
            [RecognizedTextLine(text: String(decoding: data, as: UTF8.self), minX: 0, centerY: 0.5)]
        }
        let result = try await CardImageScanner(recognizer: recognizer).scan(imageData: payload).get()
        XCTAssertEqual(result.cardNumber.digits, "4111111111111111")
    }

    // MARK: - Recognition failures

    func testRecognitionErrorsAreWrapped() async {
        let cases: [TextRecognitionError] = [.invalidImage, .recognitionFailed, .cancelled]
        for expected in cases {
            let error = await failure(.failing(with: expected))
            XCTAssertEqual(error, .recognition(expected))
        }
    }

    func testUnknownErrorsBecomeRecognitionFailed() async {
        struct Unexpected: Error {}
        let error = await failure(.failing(with: Unexpected()))
        XCTAssertEqual(error, .recognition(.recognitionFailed))
    }

    func testCancellationErrorBecomesCancelled() async {
        let error = await failure(.failing(with: CancellationError()))
        XCTAssertEqual(error, .recognition(.cancelled))
    }

    // MARK: - Pipeline failures

    func testNoRecognizedLinesFailsAsEmptyInput() async {
        let error = await failure(.returning([]))
        XCTAssertEqual(error, .scan(.emptyInput))
    }

    func testTextWithoutCardNumberFailsAsNotFound() async {
        let lines = [RecognizedTextLine(text: "BANK MANDIRI", minX: 0, centerY: 0.5)]
        let error = await failure(.returning(lines))
        XCTAssertEqual(error, .scan(.cardNumberNotFound))
    }

    func testTwoDifferentCardsFailAsAmbiguous() async {
        let lines = [
            RecognizedTextLine(text: "4111 1111 1111 1111", minX: 0, centerY: 0.8),
            RecognizedTextLine(text: "5555 5555 5555 4444", minX: 0, centerY: 0.2)
        ]
        let error = await failure(.returning(lines))
        XCTAssertEqual(error, .scan(.ambiguousCardNumbers))
    }

    // MARK: - Types

    func testErrorIsDistinctEquatableAndSendable() {
        XCTAssertNotEqual(CardImageScanError.recognition(.invalidImage), .scan(.emptyInput))
        XCTAssertNotEqual(CardImageScanError.scan(.emptyInput), .scan(.cardNumberNotFound))
        let error: any Error = CardImageScanError.scan(.emptyInput)
        XCTAssertEqual(error as? CardImageScanError, .scan(.emptyInput))
        let sendable: any Sendable = CardImageScanError.recognition(.cancelled)
        XCTAssertNotNil(sendable)
    }

    func testScannerIsSendable() {
        let value: any Sendable = CardImageScanner(recognizer: StubTextRecognizer.returning([]))
        XCTAssertNotNil(value)
    }
}
