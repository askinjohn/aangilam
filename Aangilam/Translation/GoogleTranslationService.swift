import Foundation

struct GoogleTranslationService: TranslationProviding {
    private let session: URLSession
    private let apiKeyProvider: @Sendable () -> String?

    private let translateURL = URL(string: "https://translation.googleapis.com/language/translate/v2")!

    init(session: URLSession = .shared, apiKeyProvider: @escaping @Sendable () -> String?) {
        self.session = session
        self.apiKeyProvider = apiKeyProvider
    }

    func translate(_ request: TranslationRequest) async throws -> TranslationResult {
        guard let apiKey = apiKeyProvider(), !apiKey.isEmpty else {
            throw TranslationError.missingAPIKey
        }
        guard TextValidator.usableText(from: request.text) != nil else {
            throw TranslationError.emptyText
        }

        var payload: [String: Any] = [
            "q": request.text,
            "target": request.targetLanguageCode,
            "format": "text"
        ]
        if !request.usesAutoDetect {
            payload["source"] = request.sourceLanguageCode
        }

        var components = URLComponents(url: translateURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        guard let url = components?.url else { throw TranslationError.unknown }

        let body = try JSONSerialization.data(withJSONObject: payload)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = body
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 20

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw TranslationError.networkFailure
        }

        try Self.throwIfHTTPError(response: response, data: data)

        let decoded: GoogleTranslateResponse
        do {
            decoded = try JSONDecoder().decode(GoogleTranslateResponse.self, from: data)
        } catch {
            throw TranslationError.unknown
        }

        guard let translation = decoded.data?.translations.first, let translated = translation.translatedText else {
            throw TranslationError.unknown
        }

        let sourceCode = translation.detectedSourceLanguage
            ?? (request.usesAutoDetect ? LanguageCatalog.guessLanguage(for: request.text).code : request.sourceLanguageCode)

        return TranslationResult(
            originalText: request.text,
            translatedText: translated,
            sourceLanguage: LanguageCatalog.language(forCode: sourceCode),
            targetLanguage: LanguageCatalog.language(forCode: request.targetLanguageCode),
            usedClipboardFallback: false
        )
    }

    func testConnection() async throws {
        _ = try await translate(
            TranslationRequest(text: "OK", sourceLanguageCode: "en", targetLanguageCode: "en")
        )
    }

    static func throwIfHTTPError(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw TranslationError.unknown
        }

        switch http.statusCode {
        case 200...299:
            return
        case 401, 403:
            throw TranslationError.invalidAPIKey
        case 400:
            if looksLikeInvalidKey(data) {
                throw TranslationError.invalidAPIKey
            }
            throw TranslationError.unknown
        case 429:
            throw TranslationError.rateLimited
        case 500...599:
            throw TranslationError.networkFailure
        default:
            throw TranslationError.unknown
        }
    }

    private static func looksLikeInvalidKey(_ data: Data) -> Bool {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let error = json["error"] as? [String: Any] else {
            return false
        }
        let status = (error["status"] as? String)?.uppercased() ?? ""
        let message = (error["message"] as? String)?.lowercased() ?? ""
        return status.contains("UNAUTH") ||
            status == "PERMISSION_DENIED" ||
            message.contains("api key") ||
            message.contains("invalid")
    }
}

private struct GoogleTranslateResponse: Decodable {
    let data: GoogleTranslateData?
}

private struct GoogleTranslateData: Decodable {
    let translations: [GoogleTranslation]
}

private struct GoogleTranslation: Decodable {
    let translatedText: String?
    let detectedSourceLanguage: String?
}
