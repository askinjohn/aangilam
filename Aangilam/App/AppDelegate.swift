import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let settings: SettingsStore
    let coordinator: TranslationCoordinator

    override init() {
        InstanceGuard.terminateOtherInstances()
        let settings = SettingsStore.shared
        self.settings = settings
        self.coordinator = TranslationCoordinator(settings: settings)
        super.init()
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        InstanceGuard.terminateOtherInstances()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        coordinator.start()

        if settings.launchAtLogin && !LoginItemManager.isEnabled {
            LoginItemManager.setEnabled(true)
        }

        if !settings.hasCompletedOnboarding {
            OnboardingWindowController.shared.show {
                self.settings.hasCompletedOnboarding = true
                self.settings.markAccessibilityPromptHandled()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        coordinator.stop()
    }
}
