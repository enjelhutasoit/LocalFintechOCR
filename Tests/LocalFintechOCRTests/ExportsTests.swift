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
}
