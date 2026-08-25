import SwiftUI

@main
struct AangilamApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Aangilam", image: "MenuBarIcon") {
            MenuBarContent()
                .environmentObject(appDelegate.coordinator)
                .environmentObject(appDelegate.settings)
        }
        .menuBarExtraStyle(.menu)
    }
}
