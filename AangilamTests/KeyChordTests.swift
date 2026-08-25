import XCTest
@testable import Aangilam

final class KeyChordTests: XCTestCase {
    func testDefaultShortcutDisplay() {
        XCTAssertEqual(KeyChord.defaultTranslate.displayString, "⌘⇧T")
    }

    func testRecommendedAlternatives() {
        XCTAssertEqual(KeyChord.recommendedY.displayString, "⌘⇧Y")
        XCTAssertEqual(KeyChord.recommendedOptionT.displayString, "⌘⌥T")
        XCTAssertEqual(KeyChord.recommendedControlOptionT.displayString, "⌥⌃T")
    }

    func testRequiresNonShiftModifier() {
        let shiftOnly = KeyChord(keyCode: 17, carbonModifiers: UInt32(512)) // shiftKey is 512
        XCTAssertFalse(shiftOnly.hasRequiredModifier)
        XCTAssertTrue(KeyChord.defaultTranslate.hasRequiredModifier)
    }
}
