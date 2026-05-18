import Cocoa
import Foundation

// Trace breadcrumbs so we can verify execution reaches this point.
private func trace(_ msg: String) {
    let url = URL(fileURLWithPath: "/tmp/copypath-trace.log")
    let line = "[\(ISO8601DateFormatter().string(from: Date()))] main: \(msg)\n"
    guard let data = line.data(using: .utf8) else { return }
    if let fh = try? FileHandle(forWritingTo: url) {
        try? fh.seekToEnd()
        try? fh.write(contentsOf: data)
        try? fh.close()
    } else {
        try? data.write(to: url)
    }
}

trace("entered main.swift")
NSLog("CopyPath: main.swift entered")

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

trace("delegate assigned, calling run()")
NSLog("CopyPath: about to call run()")

app.run()
