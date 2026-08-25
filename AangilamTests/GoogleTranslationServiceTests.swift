import XCTest
@testable import Aangilam

final class GoogleTranslationServiceTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        URLProtocolStub.reset()
    }

    func testMissingAPIKey() async {
        let service = GoogleTranslationService(session: .shared, apiKeyProvider: { nil })
        do {
            _ = try await service.translate(
                TranslationRequest(text: "Hej", sourceLanguageCode: "auto", targetLanguageCode: "en")
            )
            XCTFail("Expected missing API key")
        } catch {
            XCTAssertEqual(error as? TranslationError, .missingAPIKey)
        }
    }

    func testSuccessfulTranslationParsing() async throws {
        URLProtocolStub.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/language/translate/v2")
            XCTAssertNil(request.value(forHTTPHeaderField: "X-Goog-Api-Key"))
            let body = """
            {"data":{"translations":[{"translatedText":"Hello","detectedSourceLanguage":"sv"}]}}
            """.data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, body)
        }
        let service = GoogleTranslationService(session: Self.stubbedSession(), apiKeyProvider: { "test-key" })
        let result = try await service.translate(
            TranslationRequest(text: "Hej", sourceLanguageCode: "auto", targetLanguageCode: "en")
        )
        XCTAssertEqual(result.translatedText, "Hello")
        XCTAssertEqual(result.sourceLanguage.code, "sv")
        XCTAssertEqual(result.targetLanguage.code, "en")
    }

    func testInvalidAPIKeyStatus() async {
        URLProtocolStub.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 403, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        let service = GoogleTranslationService(session: Self.stubbedSession(), apiKeyProvider: { "bad" })
        do {
            _ = try await service.translate(
                TranslationRequest(text: "Hej", sourceLanguageCode: "auto", targetLanguageCode: "en")
            )
            XCTFail("Expected invalid key")
        } catch {
            XCTAssertEqual(error as? TranslationError, .invalidAPIKey)
        }
    }

    func testRateLimitStatus() async {
        URLProtocolStub.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 429, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        let service = GoogleTranslationService(session: Self.stubbedSession(), apiKeyProvider: { "key" })
        do {
            _ = try await service.translate(
                TranslationRequest(text: "Hej", sourceLanguageCode: "auto", targetLanguageCode: "en")
            )
            XCTFail("Expected rate limit")
        } catch {
            XCTAssertEqual(error as? TranslationError, .rateLimited)
        }
    }

    func testServerErrorMapsToNetworkFailure() async {
        URLProtocolStub.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 503, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        let service = GoogleTranslationService(session: Self.stubbedSession(), apiKeyProvider: { "key" })
        do {
            _ = try await service.translate(
                TranslationRequest(text: "Hej", sourceLanguageCode: "auto", targetLanguageCode: "en")
            )
            XCTFail("Expected network failure")
        } catch {
            XCTAssertEqual(error as? TranslationError, .networkFailure)
        }
    }

    private static func stubbedSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        return URLSession(configuration: config)
    }
}

final class URLProtocolStub: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    static func reset() {
        requestHandler = nil
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = URLProtocolStub.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
