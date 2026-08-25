import XCTest
@testable import Aangilam

@MainActor
final class TranslationCoordinatorTests: XCTestCase {
    private var defaults: UserDefaults!
    private var secrets: InMemorySecretStore!
    private var settings: SettingsStore!
    private var reader: StubSelectedTextReader!
    private var clipboard: InMemoryClipboard!
    private var popup: NullPopupPresenter!

    override func setUp() async throws {
        defaults = UserDefaults(suiteName: "com.aangilam.tests.\(UUID().uuidString)")
        secrets = InMemorySecretStore()
        settings = SettingsStore(defaults: defaults, secrets: secrets)
        reader = StubSelectedTextReader()
        clipboard = InMemoryClipboard()
        popup = NullPopupPresenter()
    }

    override func tearDown() async throws {
        if let defaults {
            let suite = defaults.persistentDomain(forName: defaults.persistentDomainNames().last ?? "")
            _ = suite
        }
    }

    func testAppleProviderDoesNotRequireAPIKey() async {
        settings.providerKind = .apple
        reader.selectedText = MockTranslationService.swedishSample
        let coordinator = makeCoordinator()
        coordinator.translateSelection()
        await coordinator.waitForCurrentTask()
        if case let .translated(result) = coordinator.session {
            XCTAssertEqual(result.translatedText, MockTranslationService.swedishExpected)
        } else {
            XCTFail("Apple provider should translate without an API key, got \(coordinator.session)")
        }
    }

    func testNoAPIKeyShowsConfigurationMessage() async throws {
        settings.providerKind = .google
        reader.selectedText = MockTranslationService.swedishSample
        let coordinator = makeCoordinator()
        coordinator.translateSelection()
        await coordinator.waitForCurrentTask()
        XCTAssertEqual(coordinator.session, .apiKeyMissing)
    }

    func testNoSelectionAndEmptyClipboard() async {
        reader.selectedText = nil
        clipboard.stored = nil
        try? secrets.save("key")
        settings.refreshAPIKeyStatus()
        let coordinator = makeCoordinator()
        coordinator.translateSelection()
        await coordinator.waitForCurrentTask()
        XCTAssertEqual(coordinator.session, .noSelection)
    }

    func testClipboardFallbackIsOfferedNotAutoTranslated() async {
        reader.selectedText = nil
        clipboard.stored = MockTranslationService.swedishSample
        try? secrets.save("key")
        settings.refreshAPIKeyStatus()
        let coordinator = makeCoordinator()
        coordinator.translateSelection()
        await coordinator.waitForCurrentTask()
        XCTAssertEqual(coordinator.session, .clipboardFallbackAvailable(text: MockTranslationService.swedishSample))
    }

    func testTranslateClipboardFallback() async {
        reader.selectedText = nil
        clipboard.stored = MockTranslationService.swedishSample
        try? secrets.save("key")
        settings.refreshAPIKeyStatus()
        let coordinator = makeCoordinator()
        coordinator.translateClipboardFallback()
        await coordinator.waitForCurrentTask()
        if case let .translated(result) = coordinator.session {
            XCTAssertEqual(result.translatedText, MockTranslationService.swedishExpected)
            XCTAssertTrue(result.usedClipboardFallback)
        } else {
            XCTFail("Expected translated clipboard result, got \(coordinator.session)")
        }
    }

    func testSuccessfulSelectionTranslationDoesNotTouchClipboard() async {
        reader.selectedText = MockTranslationService.swedishSample
        clipboard.stored = "unrelated clipboard"
        let before = clipboard.snapshotChangeCount()
        try? secrets.save("key")
        settings.refreshAPIKeyStatus()
        let coordinator = makeCoordinator()
        coordinator.translateSelection()
        await coordinator.waitForCurrentTask()
        XCTAssertEqual(clipboard.snapshotChangeCount(), before)
        XCTAssertEqual(clipboard.stored, "unrelated clipboard")
        if case let .translated(result) = coordinator.session {
            XCTAssertEqual(result.translatedText, MockTranslationService.swedishExpected)
            XCTAssertFalse(result.usedClipboardFallback)
        } else {
            XCTFail("Expected translated result, got \(coordinator.session)")
        }
    }

    func testCopyPlacesTranslationOnClipboard() async {
        reader.selectedText = MockTranslationService.swedishSample
        clipboard.stored = "unrelated"
        try? secrets.save("key")
        settings.refreshAPIKeyStatus()
        let coordinator = makeCoordinator()
        coordinator.translateSelection()
        await coordinator.waitForCurrentTask()
        coordinator.copyTranslation()
        XCTAssertEqual(clipboard.stored, MockTranslationService.swedishExpected)
        XCTAssertTrue(coordinator.copiedConfirmation)
    }

    func testMissingAccessibilityPermission() async {
        reader.trusted = false
        reader.selectedText = nil
        settings.hasCompletedOnboarding = false
        settings.accessibilityPromptHandled = false
        try? secrets.save("key")
        settings.refreshAPIKeyStatus()
        let coordinator = makeCoordinator()
        coordinator.translateSelection()
        await coordinator.waitForCurrentTask()
        XCTAssertEqual(coordinator.session, .accessibilityPermissionRequired)
    }

    func testDoesNotNagWhenAccessibilityWasAlreadyHandled() async {
        reader.trusted = false
        reader.selectedText = nil
        settings.hasCompletedOnboarding = true
        settings.accessibilityPromptHandled = true
        try? secrets.save("key")
        settings.refreshAPIKeyStatus()
        let coordinator = makeCoordinator()
        coordinator.translateSelection()
        await coordinator.waitForCurrentTask()
        XCTAssertEqual(coordinator.session, .noSelection)
    }

    func testSelectionSucceedsEvenIfTrustCheckIsStale() async {
        reader.trusted = false
        reader.selectedText = MockTranslationService.swedishSample
        try? secrets.save("key")
        settings.refreshAPIKeyStatus()
        let coordinator = makeCoordinator()
        coordinator.translateSelection()
        await coordinator.waitForCurrentTask()
        if case let .translated(result) = coordinator.session {
            XCTAssertEqual(result.translatedText, MockTranslationService.swedishExpected)
        } else {
            XCTFail("Expected translation when selected text is available, got \(coordinator.session)")
        }
    }

    func testNetworkFailureShowsRetryState() async {
        reader.selectedText = MockTranslationService.swedishSample
        try? secrets.save("key")
        settings.refreshAPIKeyStatus()
        var mock = MockTranslationService()
        mock.shouldFailNetwork = true
        let coordinator = makeCoordinator(provider: mock)
        coordinator.translateSelection()
        await coordinator.waitForCurrentTask()
        if case .networkError = coordinator.session {
            // expected
        } else {
            XCTFail("Expected network error, got \(coordinator.session)")
        }
    }

    func testInvalidKeyState() async {
        reader.selectedText = MockTranslationService.swedishSample
        try? secrets.save("key")
        settings.refreshAPIKeyStatus()
        var mock = MockTranslationService()
        mock.shouldFailAuth = true
        let coordinator = makeCoordinator(provider: mock)
        coordinator.translateSelection()
        await coordinator.waitForCurrentTask()
        XCTAssertEqual(coordinator.session, .authenticationError)
    }

    private func makeCoordinator(provider: TranslationProviding? = nil) -> TranslationCoordinator {
        TranslationCoordinator(
            settings: settings,
            reader: reader,
            clipboard: clipboard,
            shortcutManager: GlobalShortcutManager(),
            provider: provider ?? MockTranslationService(),
            popup: popup
        )
    }
}

private extension UserDefaults {
    func persistentDomainNames() -> [String] {
        Array(dictionaryRepresentation().keys)
    }
}
