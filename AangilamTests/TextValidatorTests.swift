import XCTest
@testable import Aangilam

final class TextValidatorTests: XCTestCase {
    func testTrimsWhitespace() {
        XCTAssertEqual(TextValidator.usableText(from: "  hello  \n"), "hello")
    }

    func testRejectsEmpty() {
        XCTAssertNil(TextValidator.usableText(from: "   "))
        XCTAssertNil(TextValidator.usableText(from: nil))
        XCTAssertNil(TextValidator.usableText(from: "\n\t"))
    }

    func testKeepsInnerNewlines() {
        XCTAssertEqual(TextValidator.usableText(from: " a\nb "), "a\nb")
    }
}
