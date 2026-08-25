import Foundation
import Combine

@MainActor
final class TranslationCoordinator: ObservableObject {
    @Published var session: TranslationSessionState = .idle
    @Published var copiedConfirmation = false
    @Published var shortcutConflict = false

    let settings: SettingsStore
    let popup: PopupPresenting

    private let reader: SelectedTextReading
    private let clipboard: ClipboardAccessing
    private let shortcutManager: GlobalShortcutManager
    private var provider: TranslationProviding
    private var currentTask: Task<Void, Never>?
    private var pendingOriginal: String = ""
    private var pendingUsedClipboard = false

    init(
        settings: SettingsStore,
        reader: SelectedTextReading? = nil,
        clipboard: ClipboardAccessing? = nil,
        shortcutManager: GlobalShortcutManager? = nil,
        provider: TranslationProviding? = nil,
        popup: PopupPresenting? = nil
    ) {
        self.settings = settings
        self.reader = reader ?? SelectedTextReader()
        self.clipboard = clipboard ?? ClipboardManager()
        self.shortcutManager = shortcutManager ?? GlobalShortcutManager()
        self.provider = provider ?? TranslationEngine.makeProvider(kind: settings.providerKind, secrets: settings.secrets)
        self.popup = popup ?? PopupController()
        self.popup.onClose = { [weak self] in
            self?.session = .idle
        }
        self.popup.onRequestSettings = { [weak self] in
            self?.openSettings()
        }
        self.popup.onRequestAccessibility = { [weak self] in
            self?.settings.markAccessibilityPromptHandled()
            SystemSettingsOpener.openAccessibility()
        }
        self.popup.onRestartApp = {
            SystemSettingsOpener.relaunchAangilam()
        }
        self.popup.onTranslateClipboard = { [weak self] in
            self?.translateClipboardFallback()
        }
        self.popup.onRetry = { [weak self] in
            self?.retry()
        }
        self.popup.onCopy = { [weak self] in
            self?.copyTranslation()
        }
        self.popup.onChangeShortcut = { [weak self] in
            self?.openSettings()
        }
    }

    func start() {
        shortcutManager.onPressed = { [weak self] in
            self?.translateSelection()
        }
        reregisterShortcut()
        prepareAppleRuntimeIfNeeded()
        popup.autoCloseEnabled = { [weak self] in
            self?.settings.autoClosePopup ?? false
        }
        popup.autoCloseInterval = { [weak self] in
            TimeInterval(self?.settings.popupTimeoutSeconds ?? 15)
        }
    }

    func stop() {
        shortcutManager.unregister()
        currentTask?.cancel()
        popup.close()
    }

    func reregisterShortcut() {
        let success = shortcutManager.register(settings.shortcut)
        shortcutConflict = !success
        if !success {
            session = .shortcutConflict(display: settings.shortcut.displayString)
            popup.present(session: session, copied: false)
        }
    }

    func translateSelection() {
        currentTask?.cancel()
        copiedConfirmation = false
        // Capture while the source app is still focused. Showing the popup first
        // steals focus and makes selection/Cmd+C miss the editor.
        let captured = reader.readSelectedText()
        session = .readingSelection
        popup.present(session: .loading(original: captured ?? "", usedClipboardFallback: false), copied: false)

        currentTask = Task { [weak self] in
            guard let self else { return }
            await self.performTranslation(forceClipboard: false, prefetched: captured)
        }
    }

    func waitForCurrentTask() async {
        await currentTask?.value
    }

    func translateClipboardFallback() {
        currentTask?.cancel()
        currentTask = Task { [weak self] in
            guard let self else { return }
            await self.performTranslation(forceClipboard: true, prefetched: nil)
        }
    }

    func retry() {
        currentTask?.cancel()
        currentTask = Task { [weak self] in
            guard let self else { return }
            if self.pendingOriginal.isEmpty {
                await self.performTranslation(forceClipboard: self.pendingUsedClipboard, prefetched: nil)
            } else {
                await self.translate(text: self.pendingOriginal, usedClipboardFallback: self.pendingUsedClipboard)
            }
        }
    }

    func copyTranslation() {
        guard case let .translated(result) = session else { return }
        clipboard.writeString(result.translatedText)
        copiedConfirmation = true
        popup.present(session: session, copied: true)
        Task {
            try? await Task.sleep(nanoseconds: 900_000_000)
            copiedConfirmation = false
            if case .translated = session {
                popup.present(session: session, copied: false)
            }
        }
    }

    func dismiss() {
        currentTask?.cancel()
        session = .idle
        popup.close()
    }

    func openSettings() {
        popup.close()
        session = .idle
        SettingsWindowController.shared.show(settings: settings, coordinator: self)
    }

    func rebuildProvider() {
        provider = TranslationEngine.makeProvider(kind: settings.providerKind, secrets: settings.secrets)
        settings.refreshAPIKeyStatus()
        prepareAppleRuntimeIfNeeded()
    }

    private func prepareAppleRuntimeIfNeeded() {
        guard settings.providerKind == .apple else { return }
        if #available(macOS 15.0, *) {
            AppleTranslationRuntime.ensureFallbackHost()
        }
    }

    func testConnection() async throws {
        try await provider.testConnection()
    }

    private func performTranslation(forceClipboard: Bool, prefetched: String?) async {
        settings.refreshAPIKeyStatus()

        let selection: SelectionRead?
        if forceClipboard {
            if let clip = clipboard.readString() {
                selection = SelectionRead(text: clip, source: .clipboard)
            } else {
                selection = nil
            }
        } else if let selected = prefetched ?? reader.readSelectedText() {
            settings.markAccessibilityPromptHandled()
            selection = SelectionRead(text: selected, source: .accessibility)
        } else if let clip = clipboard.readString() {
            session = .clipboardFallbackAvailable(text: clip)
            popup.present(session: session, copied: false)
            return
        } else if settings.shouldPromptForAccessibility && !reader.isAccessibilityTrusted(prompt: false) {
            session = .accessibilityPermissionRequired
            popup.present(session: session, copied: false)
            return
        } else {
            selection = nil
        }

        guard let selection else {
            session = .noSelection
            popup.present(session: session, copied: false)
            return
        }

        if settings.providerKind == .google {
            settings.refreshAPIKeyStatus()
            if !settings.apiKeyConfigured {
                session = .apiKeyMissing
                popup.present(session: session, copied: false)
                return
            }
        }

        await translate(text: selection.text, usedClipboardFallback: selection.source == .clipboard)
    }

    private func translate(text: String, usedClipboardFallback: Bool) async {
        pendingOriginal = text
        pendingUsedClipboard = usedClipboardFallback
        session = .loading(original: text, usedClipboardFallback: usedClipboardFallback)
        popup.present(session: session, copied: false)

        let request = TranslationRequest(
            text: text,
            sourceLanguageCode: settings.sourceLanguageCode,
            targetLanguageCode: settings.targetLanguageCode
        )

        do {
            var result = try await provider.translate(request)
            result = TranslationResult(
                originalText: result.originalText,
                translatedText: result.translatedText,
                sourceLanguage: result.sourceLanguage,
                targetLanguage: result.targetLanguage,
                usedClipboardFallback: usedClipboardFallback
            )
            if Task.isCancelled { return }
            session = .translated(result)
            popup.present(session: session, copied: false)
        } catch let error as TranslationError {
            if Task.isCancelled { return }
            switch error {
            case .missingAPIKey:
                session = .apiKeyMissing
            case .invalidAPIKey:
                session = .authenticationError
            case .networkFailure:
                session = .networkError(original: text, usedClipboardFallback: usedClipboardFallback)
            case .rateLimited:
                session = .rateLimited
            case .emptyText:
                session = .noSelection
            case .unsupportedLanguage:
                session = .unsupportedLanguage
            case .unknown:
                session = .unknownError(original: text, usedClipboardFallback: usedClipboardFallback)
            }
            popup.present(session: session, copied: false)
        } catch {
            if Task.isCancelled { return }
            session = .unknownError(original: text, usedClipboardFallback: usedClipboardFallback)
            popup.present(session: session, copied: false)
        }
    }
}
