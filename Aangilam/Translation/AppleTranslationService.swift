import AppKit
import SwiftUI
import Translation

@available(macOS 15.0, *)
struct AppleTranslationService: TranslationProviding {
    func translate(_ request: TranslationRequest) async throws -> TranslationResult {
        try await AppleTranslationRuntime.shared.translate(request)
    }

    func testConnection() async throws {
        _ = try await translate(
            TranslationRequest(text: "OK", sourceLanguageCode: "en", targetLanguageCode: "en")
        )
    }
}

@available(macOS 15.0, *)
@MainActor
final class AppleTranslationRuntime {
    static let shared = AppleTranslationRuntime()

    func translate(_ request: TranslationRequest) async throws -> TranslationResult {
        guard TextValidator.usableText(from: request.text) != nil else {
            throw TranslationError.emptyText
        }

        // The visible popup (or a fallback host window) must be on-screen so
        // SwiftUI's translationTask can deliver a session.
        AppleTranslationRuntime.ensureFallbackHost()

        let source: Locale.Language? = request.usesAutoDetect
            ? nil
            : Locale.Language(identifier: Self.appleLanguageCode(request.sourceLanguageCode))
        let target = Locale.Language(identifier: Self.appleLanguageCode(request.targetLanguageCode))

        if let source {
            let availability = LanguageAvailability()
            let status = await availability.status(from: source, to: target)
            if status == .unsupported {
                throw TranslationError.unsupportedLanguage
            }
        }

        let translated = try await AppleTranslationHostModel.shared.translate(
            text: request.text,
            source: source,
            target: target
        )
        let detected = request.usesAutoDetect
            ? LanguageCatalog.guessLanguage(for: request.text)
            : LanguageCatalog.language(forCode: request.sourceLanguageCode)

        return TranslationResult(
            originalText: request.text,
            translatedText: translated,
            sourceLanguage: detected == Language.autoDetect ? LanguageCatalog.language(forCode: "en") : detected,
            targetLanguage: LanguageCatalog.language(forCode: request.targetLanguageCode),
            usedClipboardFallback: false
        )
    }

    static func ensureFallbackHost() {
        FallbackHost.shared.install()
    }

    static func appleLanguageCode(_ code: String) -> String {
        switch code {
        case "zh": return "zh-Hans"
        case "zh-TW": return "zh-Hant"
        default: return code
        }
    }
}

@available(macOS 15.0, *)
@MainActor
final class AppleTranslationHostModel: ObservableObject {
    static let shared = AppleTranslationHostModel()

    @Published var configuration: TranslationSession.Configuration?

    private var continuation: CheckedContinuation<String, Error>?
    private var pendingText: String?
    private var isHandling = false

    func translate(text: String, source: Locale.Language?, target: Locale.Language) async throws -> String {
        if let leftover = continuation {
            leftover.resume(throwing: CancellationError())
            continuation = nil
        }
        pendingText = text
        configuration = nil
        await Task.yield()

        return try await withThrowingTaskGroup(of: String.self) { group in
            group.addTask { @MainActor in
                try await withCheckedThrowingContinuation { continuation in
                    self.continuation = continuation
                    self.configuration = TranslationSession.Configuration(source: source, target: target)
                }
            }
            group.addTask {
                try await Task.sleep(nanoseconds: 25_000_000_000)
                await MainActor.run {
                    self.finish(.failure(TranslationError.unknown))
                }
                throw TranslationError.unknown
            }
            let value = try await group.next()!
            group.cancelAll()
            return value
        }
    }

    func handle(session: TranslationSession) async {
        guard !isHandling, let text = pendingText else { return }
        isHandling = true
        defer { isHandling = false }
        do {
            // translate() also downloads models if needed. prepareTranslation() can
            // wait forever if its download UI is attached to a hidden window.
            let response = try await session.translate(text)
            finish(.success(response.targetText))
        } catch {
            finish(.failure(Self.mapError(error)))
        }
    }

    fileprivate func finish(_ result: Result<String, Error>) {
        pendingText = nil
        guard let continuation else { return }
        self.continuation = nil
        continuation.resume(with: result)
    }

    private static func mapError(_ error: Error) -> Error {
        if error is CancellationError { return TranslationError.unknown }
        let text = String(describing: error).lowercased()
        if text.contains("unsupport") || text.contains("not available") {
            return TranslationError.unsupportedLanguage
        }
        return TranslationError.unknown
    }
}

@available(macOS 15.0, *)
struct AppleTranslationHostView: View {
    @ObservedObject private var model = AppleTranslationHostModel.shared

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .translationTask(model.configuration) { session in
                await model.handle(session: session)
            }
    }
}

@available(macOS 15.0, *)
@MainActor
private final class FallbackHost {
    static let shared = FallbackHost()
    private var window: NSPanel?

    func install() {
        if window != nil { return }
        let hosting = NSHostingView(rootView: AppleTranslationHostView())
        let panel = NSPanel(
            contentRect: NSRect(x: 80, y: 80, width: 20, height: 20),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.alphaValue = 0.0
        panel.ignoresMouseEvents = true
        panel.backgroundColor = .clear
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = hosting
        panel.orderFrontRegardless()
        window = panel
    }
}
