import SwiftUI
import AppKit

struct OnboardingView: View {
    var onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Aangilam")
                .font(.largeTitle.weight(.semibold))
            Text("Understand anything, instantly.")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Aangilam translates text you select anywhere on your Mac.")
                .fixedSize(horizontal: false, vertical: true)
            Text("To use \(KeyChord.defaultTranslate.displayString), Aangilam needs Accessibility permission.")
                .fixedSize(horizontal: false, vertical: true)
            Text("Apple Translation is on by default and does not need an API key. You can switch to Google Cloud Translation in Settings if you want.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Button("Open Accessibility Settings") {
                    SystemSettingsOpener.openAccessibility()
                }
                Spacer()
                Button("Continue") {
                    onDone()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 8)
        }
        .padding(28)
        .frame(width: 480)
    }
}

@MainActor
final class OnboardingWindowController {
    static let shared = OnboardingWindowController()
    private var window: NSWindow?

    func show(onDone: @escaping () -> Void) {
        let hosting = NSHostingController(rootView: OnboardingView {
            onDone()
            self.window?.close()
        })
        let window = NSWindow(contentViewController: hosting)
        window.title = "Welcome to Aangilam"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.center()
        window.delegate = OnboardingCloseDelegate.shared
        self.window = window
        SystemSettingsOpener.revealAppWindows()
        window.makeKeyAndOrderFront(nil)
    }
}

private final class OnboardingCloseDelegate: NSObject, NSWindowDelegate {
    static let shared = OnboardingCloseDelegate()
    func windowWillClose(_ notification: Notification) {
        DispatchQueue.main.async {
            SystemSettingsOpener.restoreMenuBarModeIfIdle()
        }
    }
}
