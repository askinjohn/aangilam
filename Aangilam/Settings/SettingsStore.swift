import Foundation
import Combine

@MainActor
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    private enum Keys {
        static let sourceLanguage = "sourceLanguageCode"
        static let targetLanguage = "targetLanguageCode"
        static let shortcutKeyCode = "shortcutKeyCode"
        static let shortcutModifiers = "shortcutModifiers"
        static let launchAtLogin = "launchAtLogin"
        static let autoClosePopup = "autoClosePopup"
        static let popupTimeout = "popupTimeout"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let accessibilityPromptHandled = "accessibilityPromptHandled"
        static let providerKind = "translationProviderKind"
        static let popupDisplayMode = "popupDisplayMode"
    }

    @Published var providerKind: TranslationProviderKind {
        didSet { defaults.set(providerKind.rawValue, forKey: Keys.providerKind) }
    }

    @Published var sourceLanguageCode: String {
        didSet { defaults.set(sourceLanguageCode, forKey: Keys.sourceLanguage) }
    }

    @Published var targetLanguageCode: String {
        didSet { defaults.set(targetLanguageCode, forKey: Keys.targetLanguage) }
    }

    @Published var shortcut: KeyChord {
        didSet {
            defaults.set(Int(shortcut.keyCode), forKey: Keys.shortcutKeyCode)
            defaults.set(Int(shortcut.carbonModifiers), forKey: Keys.shortcutModifiers)
        }
    }

    @Published var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: Keys.launchAtLogin) }
    }

    @Published var popupDisplayMode: PopupDisplayMode {
        didSet { defaults.set(popupDisplayMode.rawValue, forKey: Keys.popupDisplayMode) }
    }

    @Published var autoClosePopup: Bool {
        didSet { defaults.set(autoClosePopup, forKey: Keys.autoClosePopup) }
    }

    @Published var popupTimeoutSeconds: Int {
        didSet {
            let clamped = min(60, max(5, popupTimeoutSeconds))
            if clamped != popupTimeoutSeconds {
                popupTimeoutSeconds = clamped
            } else {
                defaults.set(popupTimeoutSeconds, forKey: Keys.popupTimeout)
            }
        }
    }

    @Published var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding) }
    }

    @Published var accessibilityPromptHandled: Bool {
        didSet { defaults.set(accessibilityPromptHandled, forKey: Keys.accessibilityPromptHandled) }
    }

    @Published var apiKeyConfigured: Bool = false

    let secrets: SecretStoring
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard, secrets: SecretStoring = KeychainManager()) {
        self.defaults = defaults
        self.secrets = secrets

        if let stored = defaults.string(forKey: Keys.providerKind),
           let kind = TranslationProviderKind(rawValue: stored) {
            providerKind = kind
        } else {
            providerKind = .defaultKind
        }
        sourceLanguageCode = defaults.string(forKey: Keys.sourceLanguage) ?? Language.autoDetect.code
        targetLanguageCode = defaults.string(forKey: Keys.targetLanguage) ?? "en"

        let storedCode = defaults.object(forKey: Keys.shortcutKeyCode) as? Int
        let storedMods = defaults.object(forKey: Keys.shortcutModifiers) as? Int
        if let storedCode, let storedMods {
            shortcut = KeyChord(keyCode: UInt32(storedCode), carbonModifiers: UInt32(storedMods))
        } else {
            shortcut = .defaultTranslate
        }

        launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        if let stored = defaults.string(forKey: Keys.popupDisplayMode),
           let mode = PopupDisplayMode(rawValue: stored) {
            popupDisplayMode = mode
        } else {
            popupDisplayMode = .originalAndTranslation
        }
        autoClosePopup = defaults.bool(forKey: Keys.autoClosePopup)

        let timeout = defaults.object(forKey: Keys.popupTimeout) as? Int ?? 15
        popupTimeoutSeconds = min(60, max(5, timeout))
        let onboardingDone = defaults.bool(forKey: Keys.hasCompletedOnboarding)
        hasCompletedOnboarding = onboardingDone
        accessibilityPromptHandled = defaults.bool(forKey: Keys.accessibilityPromptHandled) || onboardingDone
        apiKeyConfigured = false
    }

    var shouldPromptForAccessibility: Bool {
        !accessibilityPromptHandled && !hasCompletedOnboarding
    }

    func markAccessibilityPromptHandled() {
        accessibilityPromptHandled = true
    }

    var sourceLanguage: Language {
        LanguageCatalog.language(forCode: sourceLanguageCode)
    }

    var targetLanguage: Language {
        LanguageCatalog.language(forCode: targetLanguageCode)
    }

    func refreshAPIKeyStatus() {
        apiKeyConfigured = secrets.hasSecret()
    }

    func saveAPIKey(_ key: String) throws {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        try secrets.save(trimmed)
        refreshAPIKeyStatus()
    }

    func removeAPIKey() throws {
        try secrets.delete()
        refreshAPIKeyStatus()
    }
}
