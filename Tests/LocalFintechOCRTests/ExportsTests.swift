//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import LocalFintechOCR // Intentionally NOT importing LocalFintechOCRCore.

final class ExportsTests: XCTestCase {

    func testFacadeReExportsCoreDomainTypes() {
        XCTAssertTrue(LuhnValidator.isValid("4111111111111111"))
        XCTAssertFalse(LuhnValidator.isValid("4111111111111112"))
    }
    
    func testFacadeReExportsLevenshteinDistance() {
        XCTAssertEqual(LevenshteinDistance.distance("kitten", "sitting"), 3)
    }
    
    func testFacadeReExportsOCRTextSanitizer() {
        XCTAssertEqual(OCRTextSanitizer.default.sanitize("M4ND1R1", as: .alphabetic), "MANDIRI")
    }
    
    func testFacadeReExportsCardNumberExtractor() {
        let results = CardNumberExtractor.default.extract(from: "4111 1111 1111 1111")
        XCTAssertEqual(results.first?.masked, "\u{2022}\u{2022}\u{2022}\u{2022} 1111")
    }
    
    func testFacadeReExportsExpiryAndNetworkTypes() throws {
        XCTAssertEqual(ExpiryDateParser.default.parse(from: "VALID THRU 12/34").first?.formatted, "12/34")
        let card = try XCTUnwrap(CardNumber(digits: "4111111111111111"))
        XCTAssertEqual(CardNetworkDetector.default.detect(card), .visa)
    }
    
    func testFacadeReExportsBankNameMatcher() {
        XCTAssertEqual(BankNameMatcher.default.match("M4ND1R1")?.bank.name, "MANDIRI")
    }
    
    func testFacadeReExportsCardScanPipeline() throws {
        let result = try CardScanPipeline.default.scan("4111 1111 1111 1111").get()
        XCTAssertEqual(result.network, .visa)
        XCTAssertEqual(result.cardNumber.masked, "\u{2022}\u{2022}\u{2022}\u{2022} 1111")
    }
}
