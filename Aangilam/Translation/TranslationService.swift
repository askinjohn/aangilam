import Foundation

protocol TranslationProviding: Sendable {
    func translate(_ request: TranslationRequest) async throws -> TranslationResult
    func testConnection() async throws
}

protocol SecretStoring: Sendable {
    func save(_ secret: String) throws
    func read() -> String?
    func delete() throws
    func hasSecret() -> Bool
}

enum TranslationEngine {
    static func makeProvider(
        kind: TranslationProviderKind,
        secrets: SecretStoring,
        session: URLSession = .shared
    ) -> TranslationProviding {
        #if DEBUG
        if ProcessInfo.processInfo.environment["AANGILAM_USE_MOCK"] == "1" {
            return MockTranslationService()
        }
        #endif
        switch kind {
        case .apple:
            if #available(macOS 15.0, *) {
                return AppleTranslationService()
            }
            return GoogleTranslationService(session: session, apiKeyProvider: { secrets.read() })
        case .google:
            return GoogleTranslationService(session: session, apiKeyProvider: { secrets.read() })
        }
    }
}
