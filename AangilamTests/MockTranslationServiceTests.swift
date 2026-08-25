import XCTest
@testable import Aangilam

final class MockTranslationServiceTests: XCTestCase {
    func testSwedishSample() async throws {
        let service = MockTranslationService()
        let result = try await service.translate(
            TranslationRequest(
                text: MockTranslationService.swedishSample,
                sourceLanguageCode: "auto",
                targetLanguageCode: "en"
            )
        )
        XCTAssertEqual(result.translatedText, MockTranslationService.swedishExpected)
        XCTAssertEqual(result.sourceLanguage.code, "sv")
        XCTAssertEqual(result.targetLanguage.code, "en")
    }

    func testGermanSample() async throws {
        let service = MockTranslationService()
        let result = try await service.translate(
            TranslationRequest(
                text: MockTranslationService.germanSample,
                sourceLanguageCode: "auto",
                targetLanguageCode: "en"
            )
        )
        XCTAssertEqual(result.translatedText, MockTranslationService.germanExpected)
        XCTAssertFalse(result.translatedText.isEmpty)
    }

    func testTamilSample() async throws {
        let service = MockTranslationService()
        let result = try await service.translate(
            TranslationRequest(
                text: MockTranslationService.tamilSample,
                sourceLanguageCode: "auto",
                targetLanguageCode: "en"
            )
        )
        XCTAssertEqual(result.translatedText, MockTranslationService.tamilExpected)
        XCTAssertEqual(result.sourceLanguage.code, "ta")
    }

    func testJapaneseSample() async throws {
        let service = MockTranslationService()
        let result = try await service.translate(
            TranslationRequest(
                text: MockTranslationService.japaneseSample,
                sourceLanguageCode: "auto",
                targetLanguageCode: "en"
            )
        )
        XCTAssertEqual(result.translatedText, MockTranslationService.japaneseExpected)
        XCTAssertEqual(result.sourceLanguage.code, "ja")
    }

    func testUnicodeIsNotCorrupted() async throws {
        let service = MockTranslationService()
        let input = "å ä ö é ü 日本語 தமிழ் 한국어"
        let result = try await service.translate(
            TranslationRequest(text: input, sourceLanguageCode: "auto", targetLanguageCode: "en")
        )
        XCTAssertTrue(result.originalText.contains("日本語"))
        XCTAssertTrue(result.originalText.contains("தமிழ்"))
        XCTAssertTrue(result.originalText.contains("한국어"))
        XCTAssertTrue(result.translatedText.contains("日本語"))
        XCTAssertTrue(result.translatedText.contains("தமிழ்"))
        XCTAssertTrue(result.translatedText.contains("한국어"))
    }

    func testMultilinePreservesNewlines() async throws {
        let service = MockTranslationService()
        let input = "Line one\nLine two\nLine three"
        let result = try await service.translate(
            TranslationRequest(text: input, sourceLanguageCode: "auto", targetLanguageCode: "en")
        )
        XCTAssertTrue(result.originalText.contains("\n"))
        XCTAssertTrue(result.translatedText.contains("\n"))
    }

    func testEmptyTextThrows() async {
        let service = MockTranslationService()
        do {
            _ = try await service.translate(
                TranslationRequest(text: "   \n", sourceLanguageCode: "auto", targetLanguageCode: "en")
            )
            XCTFail("Expected empty text to fail")
        } catch {
            XCTAssertEqual(error as? TranslationError, .emptyText)
        }
    }
}
