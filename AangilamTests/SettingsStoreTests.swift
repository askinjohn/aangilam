import XCTest
@testable import Aangilam

@MainActor
final class SettingsStoreTests: XCTestCase {
    func testDefaults() {
        let defaults = UserDefaults(suiteName: "com.aangilam.settings.\(UUID().uuidString)")!
        let secrets = InMemorySecretStore()
        let store = SettingsStore(defaults: defaults, secrets: secrets)
        XCTAssertEqual(store.sourceLanguageCode, "auto")
        XCTAssertEqual(store.targetLanguageCode, "en")
        XCTAssertEqual(store.shortcut, .defaultTranslate)
        XCTAssertFalse(store.launchAtLogin)
        XCTAssertFalse(store.autoClosePopup)
        XCTAssertEqual(store.popupTimeoutSeconds, 15)
        XCTAssertEqual(store.providerKind, TranslationProviderKind.defaultKind)
        XCTAssertEqual(store.popupDisplayMode, .originalAndTranslation)
    }

    func testPopupDisplayModePersists() {
        let suite = "com.aangilam.settings.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let first = SettingsStore(defaults: defaults, secrets: InMemorySecretStore())
        first.popupDisplayMode = .translationOnly
        let second = SettingsStore(defaults: defaults, secrets: InMemorySecretStore())
        XCTAssertEqual(second.popupDisplayMode, .translationOnly)
    }

    func testProviderKindPersists() {
        let suite = "com.aangilam.settings.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let first = SettingsStore(defaults: defaults, secrets: InMemorySecretStore())
        first.providerKind = .google
        let second = SettingsStore(defaults: defaults, secrets: InMemorySecretStore())
        XCTAssertEqual(second.providerKind, .google)
    }

    func testAPIKeyStaysInSecretStore() throws {
        let defaults = UserDefaults(suiteName: "com.aangilam.settings.\(UUID().uuidString)")!
        let secrets = InMemorySecretStore()
        let store = SettingsStore(defaults: defaults, secrets: secrets)
        try store.saveAPIKey("  abc-123  ")
        XCTAssertTrue(store.apiKeyConfigured)
        XCTAssertEqual(secrets.read(), "abc-123")
        XCTAssertNil(defaults.string(forKey: "apiKey"))
        try store.removeAPIKey()
        XCTAssertFalse(store.apiKeyConfigured)
        XCTAssertNil(secrets.read())
    }

    func testPopupTimeoutClamped() {
        let defaults = UserDefaults(suiteName: "com.aangilam.settings.\(UUID().uuidString)")!
        let store = SettingsStore(defaults: defaults, secrets: InMemorySecretStore())
        store.popupTimeoutSeconds = 2
        XCTAssertEqual(store.popupTimeoutSeconds, 5)
        store.popupTimeoutSeconds = 90
        XCTAssertEqual(store.popupTimeoutSeconds, 60)
    }
}
