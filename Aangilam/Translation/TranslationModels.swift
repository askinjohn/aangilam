import Foundation

struct Language: Equatable, Hashable, Identifiable, Sendable {
    let code: String
    let name: String
    let flag: String

    var id: String { code }

    static let autoDetect = Language(code: "auto", name: "Auto Detect", flag: "🌐")
}

struct TranslationRequest: Equatable, Sendable {
    let text: String
    let sourceLanguageCode: String
    let targetLanguageCode: String

    var usesAutoDetect: Bool {
        sourceLanguageCode == Language.autoDetect.code || sourceLanguageCode.isEmpty
    }
}

struct TranslationResult: Equatable, Sendable {
    let originalText: String
    let translatedText: String
    let sourceLanguage: Language
    let targetLanguage: Language
    let usedClipboardFallback: Bool
}

enum TranslationProviderKind: String, CaseIterable, Identifiable, Sendable {
    case apple
    case google

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .apple: return "Apple Translation"
        case .google: return "Google Cloud Translation"
        }
    }

    var detail: String {
        switch self {
        case .apple: return "On-device, no API key. macOS downloads language models the first time you use a pair."
        case .google: return "Uses your Google Cloud Translation API key. Broader language coverage."
        }
    }

    static var defaultKind: TranslationProviderKind {
        if #available(macOS 15.0, *) {
            return .apple
        }
        return .google
    }
}

enum PopupDisplayMode: String, CaseIterable, Identifiable, Sendable {
    case originalAndTranslation
    case translationOnly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .originalAndTranslation: return "Original and translation"
        case .translationOnly: return "Translation only"
        }
    }
}

enum TranslationError: Error, Equatable {
    case missingAPIKey
    case invalidAPIKey
    case networkFailure
    case rateLimited
    case emptyText
    case unsupportedLanguage
    case unknown
}

enum SelectionSource: Equatable, Sendable {
    case accessibility
    case clipboard
}

struct SelectionRead: Equatable, Sendable {
    let text: String
    let source: SelectionSource
}

enum TranslationSessionState: Equatable {
    case idle
    case readingSelection
    case loading(original: String, usedClipboardFallback: Bool)
    case translated(TranslationResult)
    case noSelection
    case clipboardFallbackAvailable(text: String)
    case accessibilityPermissionRequired
    case apiKeyMissing
    case authenticationError
    case networkError(original: String, usedClipboardFallback: Bool)
    case rateLimited
    case unsupportedLanguage
    case unknownError(original: String, usedClipboardFallback: Bool)
    case shortcutConflict(display: String)

    var isVisible: Bool {
        self != .idle
    }
}

enum TextValidator {
    static func usableText(from raw: String?) -> String? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return trimmed
    }
}
