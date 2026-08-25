import SwiftUI

struct TranslationPopupView: View {
    @ObservedObject var model: PopupModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            content
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1)
        )
        .background(appleTranslationHook)
        .onExitCommand {
            model.onDismiss?()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Aangilam translation")
    }

    @ViewBuilder
    private var appleTranslationHook: some View {
        if #available(macOS 15.0, *) {
            AppleTranslationHostView()
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Text("Aangilam")
                .font(.headline)
                .foregroundStyle(Color(nsColor: .labelColor))
            Spacer(minLength: 8)
            Button {
                model.onDismiss?()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(nsColor: .secondaryLabelColor))
                    .frame(width: 18, height: 18)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Close")
            .keyboardShortcut(.cancelAction)
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var content: some View {
        switch model.session {
        case .idle, .readingSelection:
            loadingView(original: nil)
        case let .loading(original, usedClipboardFallback):
            VStack(alignment: .leading, spacing: 6) {
                if usedClipboardFallback { fallbackBadge }
                loadingView(original: original.isEmpty ? nil : original)
            }
        case let .translated(result):
            translatedView(result)
        case .noSelection:
            messageView(
                title: "No text selected",
                detail: "Select some text and press \(KeyChord.defaultTranslate.displayString).",
                primary: nil,
                secondary: nil
            )
        case let .clipboardFallbackAvailable(text):
            clipboardFallbackView(text)
        case .accessibilityPermissionRequired:
            messageView(
                title: "Accessibility permission needed",
                detail: "Turn on Aangilam in Privacy & Security → Accessibility, then press ⌘⇧T again. If it is already listed, you do not need to grant it again.",
                primary: ("Open System Settings", { model.onOpenAccessibility?() }),
                secondary: ("Restart Aangilam", { model.onRestartApp?() })
            )
        case .apiKeyMissing:
            messageView(
                title: "Translation isn’t configured yet",
                detail: "Add your Google Cloud Translation API key in Settings to start translating.",
                primary: ("Open Settings", { model.onOpenSettings?() }),
                secondary: nil
            )
        case .authenticationError:
            messageView(
                title: "Your translation API key is invalid",
                detail: "Update the key in Settings and try again.",
                primary: ("Open Settings", { model.onOpenSettings?() }),
                secondary: nil
            )
        case .networkError:
            messageView(
                title: "Unable to connect to the translation service",
                detail: "Check your connection, then try again.",
                primary: ("Retry", { model.onRetry?() }),
                secondary: nil
            )
        case .rateLimited:
            messageView(
                title: "Translation limit reached",
                detail: "Check your Google Cloud Translation account.",
                primary: ("Retry", { model.onRetry?() }),
                secondary: nil
            )
        case .unsupportedLanguage:
            messageView(
                title: "This language pair isn’t available on Apple Translation",
                detail: "Choose Google Cloud Translation in Settings, or pick another language.",
                primary: ("Open Settings", { model.onOpenSettings?() }),
                secondary: nil
            )
        case .unknownError:
            messageView(
                title: "Something went wrong while translating",
                detail: "You can try again in a moment.",
                primary: ("Retry", { model.onRetry?() }),
                secondary: nil
            )
        case let .shortcutConflict(display):
            messageView(
                title: "\(display) is unavailable because another application is using it.",
                detail: "Recommended alternatives: ⌘⇧Y, ⌘⌥T, or ⌃⌥T.",
                primary: ("Change Shortcut", { model.onChangeShortcut?() }),
                secondary: nil
            )
        }
    }

    private func loadingView(original: String?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.small)
                Text("Translating…")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color(nsColor: .labelColor))
            }
            if let original {
                ScrollView {
                    Text(original)
                        .font(.body)
                        .foregroundStyle(Color(nsColor: .labelColor))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel("Translating")
    }

    private func translatedView(_ result: TranslationResult) -> some View {
        VStack(spacing: 10) {
            if result.usedClipboardFallback {
                fallbackBadge
            }
            Group {
                if model.displayMode == .translationOnly {
                    textColumn(language: result.targetLanguage, text: result.translatedText)
                } else {
                    HStack(alignment: .top, spacing: 12) {
                        textColumn(language: result.sourceLanguage, text: result.originalText)
                        textColumn(language: result.targetLanguage, text: result.translatedText)
                    }
                }
            }
            HStack {
                Spacer()
                Button(model.copied ? "Copied ✓" : "Copy") {
                    model.onCopy?()
                }
                .keyboardShortcut(.defaultAction)
                .accessibilityLabel(model.copied ? "Copied" : "Copy translation")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func textColumn(language: Language, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            languageHeader(language)
            ScrollView {
                Text(text)
                    .font(.body)
                    .foregroundStyle(Color(nsColor: .labelColor))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private func clipboardFallbackView(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("I couldn’t access the selected text. I found text in your clipboard and can translate that instead.")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color(nsColor: .labelColor))
                .fixedSize(horizontal: false, vertical: true)
            Text(text)
                .font(.body)
                .foregroundStyle(Color(nsColor: .labelColor))
                .lineLimit(5)
                .textSelection(.enabled)
            HStack {
                Spacer()
                Button("Translate Clipboard") {
                    model.onTranslateClipboard?()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
    }

    private func messageView(title: String, detail: String, primary: (String, () -> Void)?, secondary: (String, () -> Void)?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color(nsColor: .labelColor))
                .fixedSize(horizontal: false, vertical: true)
            Text(detail)
                .font(.body)
                .foregroundStyle(Color(nsColor: .labelColor))
                .fixedSize(horizontal: false, vertical: true)
            if primary != nil || secondary != nil {
                HStack(spacing: 8) {
                    Spacer()
                    if let secondary {
                        Button(secondary.0, action: secondary.1)
                    }
                    if let primary {
                        Button(primary.0, action: primary.1)
                            .keyboardShortcut(.defaultAction)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func languageHeader(_ language: Language) -> some View {
        HStack {
            Text(language.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(nsColor: .labelColor))
            Spacer()
            Text(language.flag)
                .accessibilityHidden(true)
        }
    }

    private var fallbackBadge: some View {
        Text("Using clipboard text")
            .font(.caption.weight(.medium))
            .foregroundStyle(Color(nsColor: .labelColor))
    }
}
