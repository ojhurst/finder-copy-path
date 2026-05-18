import Cocoa

Trace.write("main.swift: entered")

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

Trace.write("main.swift: delegate set, calling run()")

app.run()
