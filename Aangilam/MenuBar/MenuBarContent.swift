import SwiftUI
import AppKit

struct MenuBarContent: View {
    @EnvironmentObject private var coordinator: TranslationCoordinator
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        Button("Translate Selection") {
            coordinator.translateSelection()
        }
        .keyboardShortcut(
            KeyEquivalent(Character(settings.shortcut.keyEquivalent)),
            modifiers: settings.shortcut.eventModifiers
        )

        Divider()

        Button("Settings…") {
            coordinator.openSettings()
        }
        .keyboardShortcut(",", modifiers: .command)

        Button("About Aangilam") {
            AboutWindowController.shared.show()
        }

        Divider()

        Button("Quit Aangilam") {
            NSApplication.shared.terminate(nil)
        }
    }
}
