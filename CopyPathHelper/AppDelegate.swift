import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Minimal container app — exists only to host the Finder Sync Extension.
        // Hide from Dock since there's no UI.
        NSApp.setActivationPolicy(.accessory)
    }
}
