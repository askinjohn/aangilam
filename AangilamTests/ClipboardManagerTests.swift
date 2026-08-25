import XCTest
@testable import Aangilam

final class ClipboardManagerTests: XCTestCase {
    func testInMemoryClipboardDoesNotReadUntilAsked() {
        let clipboard = InMemoryClipboard()
        clipboard.stored = "secret"
        XCTAssertEqual(clipboard.readString(), "secret")
        XCTAssertEqual(clipboard.snapshotChangeCount(), 0)
        clipboard.writeString("copied")
        XCTAssertEqual(clipboard.snapshotChangeCount(), 1)
        XCTAssertEqual(clipboard.readString(), "copied")
    }

    func testIgnoresBlankClipboardText() {
        let clipboard = InMemoryClipboard()
        clipboard.stored = "   "
        XCTAssertNil(clipboard.readString())
    }
}
