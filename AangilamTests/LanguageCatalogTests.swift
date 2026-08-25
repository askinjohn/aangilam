import XCTest
@testable import Aangilam

final class LanguageCatalogTests: XCTestCase {
    func testAutoDetectAndEnglishDefaults() {
        XCTAssertEqual(Language.autoDetect.code, "auto")
        XCTAssertEqual(LanguageCatalog.default.code, "en")
        XCTAssertEqual(LanguageCatalog.default.flag, "🇬🇧")
    }

    func testLooksUpSwedish() {
        XCTAssertEqual(LanguageCatalog.language(forCode: "sv").name, "Swedish")
    }

    func testGuessesTamil() {
        XCTAssertEqual(LanguageCatalog.guessLanguage(for: "வணக்கம்").code, "ta")
    }

    func testGuessesJapanese() {
        XCTAssertEqual(LanguageCatalog.guessLanguage(for: "こんにちは").code, "ja")
    }

    func testSourceListIncludesAutoDetectFirst() {
        XCTAssertEqual(LanguageCatalog.sourceLanguages.first, Language.autoDetect)
    }
}
