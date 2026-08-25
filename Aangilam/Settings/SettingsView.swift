import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var coordinator: TranslationCoordinator

    var body: some View {
        TabView {
            TranslationSettingsPane()
                .tabItem { Label("Translation", systemImage: "globe") }
            ShortcutSettingsPane()
                .tabItem { Label("Shortcut", systemImage: "keyboard") }
            GeneralSettingsPane()
                .tabItem { Label("General", systemImage: "gearshape") }
            PrivacySettingsPane()
                .tabItem { Label("Privacy", systemImage: "lock.shield") }
        }
        .frame(width: 560, height: 460)
        .environmentObject(settings)
        .environmentObject(coordinator)
    }
}

private struct TranslationSettingsPane: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var coordinator: TranslationCoordinator
    @State private var apiKeyDraft = ""
    @State private var statusMessage = ""
    @State private var isTesting = false

    var body: some View {
        Form {
            Picker("Provider", selection: $settings.providerKind) {
                ForEach(TranslationProviderKind.allCases) { kind in
                    Text(kind.displayName).tag(kind)
                }
            }
            .onChange(of: settings.providerKind) { _, _ in
                coordinator.rebuildProvider()
                statusMessage = ""
            }

            Text(settings.providerKind.detail)
                .font(.callout)
                .foregroundStyle(.secondary)

            Picker("Source Language", selection: $settings.sourceLanguageCode) {
                ForEach(LanguageCatalog.sourceLanguages) { language in
                    Text("\(language.flag)  \(language.name)").tag(language.code)
                }
            }

            Picker("Target Language", selection: $settings.targetLanguageCode) {
                ForEach(LanguageCatalog.targetLanguages) { language in
                    Text("\(language.flag)  \(language.name)").tag(language.code)
                }
            }

            if settings.providerKind == .google {
            LabeledContent("API Key") {
                VStack(alignment: .leading, spacing: 8) {
                    if settings.apiKeyConfigured && apiKeyDraft.isEmpty {
                        SecureField("••••••••••••••••", text: $apiKeyDraft)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 280)
                        Text("Configured")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        SecureField(settings.apiKeyConfigured ? "Enter a new key to replace it" : "Not configured", text: $apiKeyDraft)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 280)
                        if !settings.apiKeyConfigured {
                            Text("Not configured")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            HStack {
                Button("Save") {
                    saveKey()
                }
                .disabled(apiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button("Test Connection") {
                    Task { await testConnection() }
                }
                .disabled(!settings.apiKeyConfigured || isTesting)

                Button("Remove API Key", role: .destructive) {
                    removeKey()
                }
                .disabled(!settings.apiKeyConfigured)
            }
            } else {
                Button("Test Apple Translation") {
                    Task { await testConnection() }
                }
                .disabled(isTesting)
            }

            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .onAppear {
            settings.refreshAPIKeyStatus()
        }
    }

    private func saveKey() {
        do {
            try settings.saveAPIKey(apiKeyDraft)
            apiKeyDraft = ""
            coordinator.rebuildProvider()
            statusMessage = "API key saved."
        } catch {
            statusMessage = "Couldn't save the API key."
        }
    }

    private func removeKey() {
        do {
            try settings.removeAPIKey()
            apiKeyDraft = ""
            coordinator.rebuildProvider()
            statusMessage = "API key removed."
        } catch {
            statusMessage = "Couldn't remove the API key."
        }
    }

    private func testConnection() async {
        isTesting = true
        defer { isTesting = false }
        do {
            try await coordinator.testConnection()
            statusMessage = "Connection succeeded."
        } catch TranslationError.invalidAPIKey {
            statusMessage = "Your translation API key is invalid."
        } catch TranslationError.networkFailure {
            statusMessage = "Unable to connect to the translation service."
        } catch TranslationError.missingAPIKey {
            statusMessage = "Translation isn't configured yet."
        } catch {
            statusMessage = "Something went wrong while translating."
        }
    }
}

private struct ShortcutSettingsPane: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var coordinator: TranslationCoordinator
    @State private var isRecording = false

    var body: some View {
        Form {
            LabeledContent("Translate Selection") {
                Text(settings.shortcut.displayString)
                    .font(.title2.monospaced())
            }

            ShortcutRecorderView(isRecording: $isRecording) { chord in
                settings.shortcut = chord
                coordinator.reregisterShortcut()
                isRecording = false
            }

            Button(isRecording ? "Press a new shortcut…" : "Change Shortcut") {
                isRecording = true
            }

            Text("Recommended alternatives: ⌘⇧Y, ⌘⌥T, ⌃⌥T")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
        .padding(20)
    }
}

private struct GeneralSettingsPane: View {
    @EnvironmentObject private var settings: SettingsStore

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { settings.launchAtLogin },
            set: { newValue in
                if LoginItemManager.setEnabled(newValue) {
                    settings.launchAtLogin = newValue
                }
            }
        )
    }

    var body: some View {
        Form {
            Toggle("Launch at Login", isOn: launchAtLoginBinding)

            Picker("Popup shows", selection: $settings.popupDisplayMode) {
                ForEach(PopupDisplayMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }

            Toggle("Automatically close popup", isOn: $settings.autoClosePopup)

            if settings.autoClosePopup {
                Stepper(value: $settings.popupTimeoutSeconds, in: 5...60, step: 1) {
                    Text("Popup timeout  \(settings.popupTimeoutSeconds) seconds")
                }
            }
        }
        .formStyle(.grouped)
        .padding(20)
    }
}

private struct PrivacySettingsPane: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Privacy")
                .font(.title3.weight(.semibold))
            Text("Aangilam only accesses selected text when you request a translation. It does not continuously monitor your clipboard or Slack.")
                .fixedSize(horizontal: false, vertical: true)
            Text("Apple Translation runs on your Mac and does not send text to Google. If you choose Google Cloud Translation, text is sent to Google only after you press the translate shortcut. Aangilam does not keep a remote translation history and does not send analytics.")
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowController()
    private var window: NSWindow?

    func show(settings: SettingsStore, coordinator: TranslationCoordinator) {
        if window == nil {
            let hosting = NSHostingController(
                rootView: SettingsView()
                    .environmentObject(settings)
                    .environmentObject(coordinator)
            )
            let window = NSWindow(contentViewController: hosting)
            window.title = "Aangilam Settings"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.setContentSize(NSSize(width: 560, height: 460))
            window.center()
            self.window = window
        }
        SystemSettingsOpener.revealAppWindows()
        window?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        DispatchQueue.main.async {
            SystemSettingsOpener.restoreMenuBarModeIfIdle()
        }
    }
}
