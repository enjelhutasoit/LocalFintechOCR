//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import LocalFintechOCR // Facade only: proves consumers need a single import.

final class LocalFintechOCRClientTests: XCTestCase {

    private let imageData = Data([0x01, 0x02, 0x03])

    // Deliberately out of reading order.
    private let cardLines = [
        RecognizedTextLine(text: "VALID THRU 12/34", minX: 0.5, centerY: 0.2),
        RecognizedTextLine(text: "4111 1111 1111 1111", minX: 0.1, centerY: 0.5),
        RecognizedTextLine(text: "BANK MANDIRI", minX: 0.1, centerY: 0.9)
    ]

    private func client(
        _ recognizer: FacadeStubRecognizer,
        configuration: LocalFintechOCRConfiguration = .default
    ) -> LocalFintechOCRClient {
        LocalFintechOCRClient(recognizer: recognizer, configuration: configuration)
    }

    private func imageError(_ client: LocalFintechOCRClient) async -> CardImageScanError? {
        do {
            _ = try await client.scan(imageData: imageData)
            return nil
        } catch {
            return error as? CardImageScanError
        }
    }

    // MARK: - Image scanning

    func testScansImageIntoTypedResult() async throws {
        let result = try await client(.returning(cardLines)).scan(imageData: imageData)

        XCTAssertEqual(result.cardNumber.digits, "4111111111111111")
        XCTAssertEqual(result.network, .visa)
        XCTAssertEqual(result.expiry?.formatted, "12/34")
        XCTAssertEqual(result.bank?.bank.name, "MANDIRI")
    }

    func testForwardsTheExactImageDataToTheRecognizer() async throws {
        let payload = Data("4111 1111 1111 1111".utf8)
        let recognizer = FacadeStubRecognizer { data in
            [RecognizedTextLine(text: String(decoding: data, as: UTF8.self), minX: 0, centerY: 0.5)]
        }
        let result = try await client(recognizer).scan(imageData: payload)
        XCTAssertEqual(result.cardNumber.digits, "4111111111111111")
    }

    // MARK: - Image failures

    func testRecognitionErrorsAreThrownAsTypedErrors() async {
        for expected in [TextRecognitionError.invalidImage, .recognitionFailed, .cancelled] {
            let error = await imageError(client(.failing(with: expected)))
            XCTAssertEqual(error, .recognition(expected))
        }
    }

    func testCancellationErrorIsThrownAsCancelled() async {
        let error = await imageError(client(.failing(with: CancellationError())))
        XCTAssertEqual(error, .recognition(.cancelled))
    }

    func testPipelineFailuresAreThrownAsTypedErrors() async {
        let empty = await imageError(client(.returning([])))
        XCTAssertEqual(empty, .scan(.emptyInput))

        let notFound = await imageError(
            client(.returning([RecognizedTextLine(text: "BANK MANDIRI", minX: 0, centerY: 0.5)]))
        )
        XCTAssertEqual(notFound, .scan(.cardNumberNotFound))

        let ambiguous = await imageError(client(.returning([
            RecognizedTextLine(text: "4111 1111 1111 1111", minX: 0, centerY: 0.8),
            RecognizedTextLine(text: "5555 5555 5555 4444", minX: 0, centerY: 0.2)
        ])))
        XCTAssertEqual(ambiguous, .scan(.ambiguousCardNumbers))
    }

    func testDefaultRecognizerRejectsEmptyDataBeforeVisionIsCalled() async {
        do {
            _ = try await LocalFintechOCRClient().scan(imageData: Data())
            XCTFail("Expected invalidImage")
        } catch {
            XCTAssertEqual(error as? CardImageScanError, .recognition(.invalidImage))
        }
    }

    // MARK: - Text scanning

    func testScansTextWithoutAnyRecognizer() throws {
        let text = "BANK MANDIRI\n4111 1111 1111 1111\nVALID THRU 12/34"
        let result = try client(.returning([])).scan(text: text)
        XCTAssertEqual(result.cardNumber.digits, "4111111111111111")
        XCTAssertEqual(result.bank?.bank.name, "MANDIRI")
    }

    func testTextFailuresAreThrownAsCardScanError() {
        let sut = client(.returning([]))
        for (text, expected) in [("", CardScanError.emptyInput), ("MANDIRI", .cardNumberNotFound)] {
            do {
                _ = try sut.scan(text: text)
                XCTFail("Expected \(expected)")
            } catch {
                XCTAssertEqual(error as? CardScanError, expected)
            }
        }
    }

    // MARK: - Configuration is honored

    func testDefaultBankThresholdToleratesOneEdit() async throws {
        let lines = [
            RecognizedTextLine(text: "MANDRI", minX: 0, centerY: 0.9),
            RecognizedTextLine(text: "4111 1111 1111 1111", minX: 0, centerY: 0.5)
        ]
        let result = try await client(.returning(lines)).scan(imageData: imageData)
        XCTAssertEqual(result.bank?.bank.name, "MANDIRI")
        XCTAssertEqual(result.bank?.distance, 1)
    }

    func testBankThresholdIsConfigurable() async throws {
        var config = LocalFintechOCRConfiguration.default
        config.bankMaxDistancePerMille = 0
        let lines = [
            RecognizedTextLine(text: "MANDRI", minX: 0, centerY: 0.9),
            RecognizedTextLine(text: "4111 1111 1111 1111", minX: 0, centerY: 0.5)
        ]
        let result = try await client(.returning(lines), configuration: config).scan(imageData: imageData)
        XCTAssertNil(result.bank)
    }

    func testEmptyBankCatalogYieldsNilBank() async throws {
        var config = LocalFintechOCRConfiguration.default
        config.banks = []
        let result = try await client(.returning(cardLines), configuration: config).scan(imageData: imageData)
        XCTAssertNil(result.bank)
        XCTAssertEqual(result.cardNumber.digits, "4111111111111111")
    }

    func testEmptyNetworkRulesYieldUnknownNetwork() async throws {
        var config = LocalFintechOCRConfiguration.default
        config.networkRules = []
        let result = try await client(.returning(cardLines), configuration: config).scan(imageData: imageData)
        XCTAssertEqual(result.network, .unknown)
    }

    func testOneConfusionTableControlsEveryComponent() async {
        var config = LocalFintechOCRConfiguration.default
        config.confusionTable = OCRConfusionTable(toDigit: [:], toLetter: [:])
        let lines = [RecognizedTextLine(text: "4111 1111 1111 111l", minX: 0, centerY: 0.5)]

        let error = await imageError(client(.returning(lines), configuration: config))
        XCTAssertEqual(error, .scan(.cardNumberNotFound))

        let text = try? client(.returning([]), configuration: config).scan(text: "M4ND1R1\n4111 1111 1111 1111")
        XCTAssertNil(text?.bank)
    }

    func testRowToleranceIsConfigurable() async throws {
        let lines = [
            RecognizedTextLine(text: "4111 1111", minX: 0.1, centerY: 0.50),
            RecognizedTextLine(text: "1111 1111", minX: 0.5, centerY: 0.45)
        ]

        let defaultError = await imageError(client(.returning(lines)))
        XCTAssertEqual(defaultError, .scan(.cardNumberNotFound))

        var wide = LocalFintechOCRConfiguration.default
        wide.rowTolerance = 0.1
        let result = try await client(.returning(lines), configuration: wide).scan(imageData: imageData)
        XCTAssertEqual(result.cardNumber.digits, "4111111111111111")
    }

    // MARK: - Concurrency and types

    func testConcurrentScansReturnIdenticalResults() async throws {
        let sut = client(.returning(cardLines))
        let data = imageData
        let expected = try await sut.scan(imageData: data)

        let results = await withTaskGroup(of: CardScanResult?.self) { group in
            for _ in 0..<20 {
                group.addTask { try? await sut.scan(imageData: data) }
            }
            var collected: [CardScanResult?] = []
            for await result in group { collected.append(result) }
            return collected
        }

        XCTAssertEqual(results.count, 20)
        XCTAssertTrue(results.allSatisfy { $0 == expected })
    }

    func testClientIsSendable() {
        let value: any Sendable = LocalFintechOCRClient()
        XCTAssertNotNil(value)
    }
}
