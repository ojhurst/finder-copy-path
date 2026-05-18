import Cocoa
import Foundation

private func trace(_ msg: String) {
    let url = URL(fileURLWithPath: "/tmp/copypath-trace.log")
    let line = "[\(ISO8601DateFormatter().string(from: Date()))] \(msg)\n"
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

trace("main.swift entered")

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

trace("delegate set, about to call run()")

app.run()
