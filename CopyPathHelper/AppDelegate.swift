import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    private var onboardingWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Trace.write("delegate: did-finish-launching fired")

        NSApp.setActivationPolicy(.regular)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Copy Path"
        window.isReleasedWhenClosed = false
        window.center()

        let label = NSTextField(labelWithString: "HELLO from Build 36")
        label.font = NSFont.systemFont(ofSize: 18, weight: .semibold)
        label.alignment = .center
        label.frame = NSRect(x: 0, y: 90, width: 360, height: 24)

        let view = NSView(frame: NSRect(x: 0, y: 0, width: 360, height: 200))
        view.addSubview(label)
        window.contentView = view

        window.makeKeyAndOrderFront(nil)
        onboardingWindow = window

        NSApp.activate(ignoringOtherApps: true)
        Trace.write("delegate: window presented")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }
}

enum Trace {
    static func write(_ msg: String) {
        // Write to the sandbox container's home directory (always allowed).
        let home = FileManager.default.homeDirectoryForCurrentUser
        let url = home.appendingPathComponent("copypath-trace.log")
        let line = "[\(ISO8601DateFormatter().string(from: Date()))] \(msg)\n"
        guard let data = line.data(using: .utf8) else { return }
        if let fh = try? FileHandle(forWritingTo: url) {
            try? fh.seekToEnd()
            try? fh.write(contentsOf: data)
            try? fh.close()
        } else {
            try? data.write(to: url)
        }
    }
}
