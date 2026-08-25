import Foundation

struct MockTranslationService: TranslationProviding {
    static let swedishSample = "Kan vi ta det här på mötet imorgon?"
    static let swedishExpected = "Can we discuss this in tomorrow's meeting?"
    static let germanSample = "Wie geht es dir?"
    static let germanExpected = "How are you?"
    static let tamilSample = "வணக்கம், இன்று சந்திக்கலாமா?"
    static let tamilExpected = "Hello, shall we meet today?"
    static let japaneseSample = "こんにちは、元気ですか？"
    static let japaneseExpected = "Hello, how are you?"

    var shouldFailNetwork = false
    var shouldFailAuth = false
    var shouldFailRateLimit = false
    var delayNanoseconds: UInt64 = 0

    func translate(_ request: TranslationRequest) async throws -> TranslationResult {
        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }
        if shouldFailNetwork { throw TranslationError.networkFailure }
        if shouldFailAuth { throw TranslationError.invalidAPIKey }
        if shouldFailRateLimit { throw TranslationError.rateLimited }

        let text = request.text
        guard TextValidator.usableText(from: text) != nil else {
            throw TranslationError.emptyText
        }

        let translated: String
        switch normalized(text) {
        case normalized(Self.swedishSample):
            translated = Self.swedishExpected
        case normalized(Self.germanSample):
            translated = Self.germanExpected
        case normalized(Self.tamilSample):
            translated = Self.tamilExpected
        case normalized(Self.japaneseSample):
            translated = Self.japaneseExpected
        default:
            translated = mockFallback(for: text, target: request.targetLanguageCode)
        }

        let detected = request.usesAutoDetect
            ? LanguageCatalog.guessLanguage(for: text)
            : LanguageCatalog.language(forCode: request.sourceLanguageCode)

        return TranslationResult(
            originalText: text,
            translatedText: translated,
            sourceLanguage: detected == Language.autoDetect ? LanguageCatalog.language(forCode: "en") : detected,
            targetLanguage: LanguageCatalog.language(forCode: request.targetLanguageCode),
            usedClipboardFallback: false
        )
    }

    func testConnection() async throws {
        if shouldFailNetwork { throw TranslationError.networkFailure }
        if shouldFailAuth { throw TranslationError.invalidAPIKey }
        _ = try await translate(
            TranslationRequest(text: "OK", sourceLanguageCode: "en", targetLanguageCode: "en")
        )
    }

    private func normalized(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func mockFallback(for text: String, target: String) -> String {
        if target == "en" || target.isEmpty {
            return text
        }
        return text
    }
}
