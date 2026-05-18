import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    private var onboardingWindow: NSWindow?

    static func main() {
        let trace = "[\(ISO8601DateFormatter().string(from: Date()))] static main entered\n"
        try? trace.data(using: .utf8)?.write(to: URL(fileURLWithPath: "/tmp/copypath-trace.log"))

        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("CopyPath: applicationDidFinishLaunching fired")
        trace("applicationDidFinishLaunching fired")

        NSApp.setActivationPolicy(.regular)
        presentOnboardingWindow()
        NSApp.activate(ignoringOtherApps: true)

        trace("delegate finished setup")
    }

    private func trace(_ msg: String) {
        let url = URL(fileURLWithPath: "/tmp/copypath-trace.log")
        let line = "[\(ISO8601DateFormatter().string(from: Date()))] AD: \(msg)\n"
        if let data = line.data(using: .utf8) {
            if let fh = try? FileHandle(forWritingTo: url) {
                try? fh.seekToEnd()
                try? fh.write(contentsOf: data)
                try? fh.close()
            } else {
                try? data.write(to: url)
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    // MARK: - Onboarding window

    private func presentOnboardingWindow() {
        let W: CGFloat = 480
        let H: CGFloat = 500

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: W, height: H),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Copy Path"
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .moveToActiveSpace]
        window.center()

        let content = NSView(frame: NSRect(x: 0, y: 0, width: W, height: H))

        // Title
        let title = NSTextField(labelWithString: "One more step")
        title.font = NSFont.systemFont(ofSize: 22, weight: .semibold)
        title.alignment = .center
        title.frame = NSRect(x: 0, y: 450, width: W, height: 28)
        content.addSubview(title)

        // Subtitle
        let subtitle = NSTextField(wrappingLabelWithString:
            "Copy Path is installed but not turned on yet. Click below to open System Settings, then find this entry:")
        subtitle.font = NSFont.systemFont(ofSize: 13)
        subtitle.alignment = .center
        subtitle.textColor = .secondaryLabelColor
        subtitle.frame = NSRect(x: 40, y: 395, width: W - 80, height: 50)
        content.addSubview(subtitle)

        // Screenshot — visual cue of what to find in Settings
        if let path = Bundle.main.path(forResource: "onboarding-target", ofType: "png"),
           let image = NSImage(contentsOfFile: path) {
            let imgW: CGFloat = 400
            let imgH: CGFloat = imgW * (image.size.height / image.size.width)
            let imgView = NSImageView(frame: NSRect(x: (W - imgW) / 2, y: 305, width: imgW, height: imgH))
            imgView.image = image
            imgView.imageScaling = .scaleProportionallyDown
            imgView.imageAlignment = .alignCenter
            imgView.wantsLayer = true
            imgView.layer?.cornerRadius = 10
            imgView.layer?.masksToBounds = true
            imgView.layer?.borderWidth = 1
            imgView.layer?.borderColor = NSColor.separatorColor.cgColor
            content.addSubview(imgView)
        }

        // Instructions — what to do once they see that row
        let instructions = NSTextField(wrappingLabelWithString:
            "1.  Click the ⓘ icon next to that row\n2.  Flip the toggle on\n3.  Close this window")
        instructions.font = NSFont.systemFont(ofSize: 13)
        instructions.alignment = .left
        instructions.frame = NSRect(x: 130, y: 140, width: 220, height: 65)
        content.addSubview(instructions)

        // Action button
        let button = NSButton(title: "Open System Settings",
                              target: self,
                              action: #selector(openSettings))
        button.bezelStyle = .rounded
        button.controlSize = .large
        button.keyEquivalent = "\r"
        button.frame = NSRect(x: (W - 200) / 2, y: 85, width: 200, height: 32)
        content.addSubview(button)

        // Footer
        let status = NSTextField(labelWithString: "Once it's on, right-click any file in Finder to test.")
        status.font = NSFont.systemFont(ofSize: 12)
        status.alignment = .center
        status.textColor = .tertiaryLabelColor
        status.frame = NSRect(x: 0, y: 45, width: W, height: 18)
        content.addSubview(status)

        window.contentView = content
        window.makeKeyAndOrderFront(nil)
        onboardingWindow = window
    }

    @objc private func openSettings() {
        // Try the URL we know works on macOS 13–26, then fall back to opening
        // System Settings at its top level if the specific pane is unavailable.
        let candidates = [
            "x-apple.systempreferences:com.apple.ExtensionsPreferences",
            "x-apple.systempreferences:",
        ]
        for raw in candidates {
            if let url = URL(string: raw), NSWorkspace.shared.open(url) {
                return
            }
        }
    }
}
