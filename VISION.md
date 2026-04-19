# Finder Copy Path — Vision

## What This Is
A macOS Finder extension that adds "Copy Path" to the right-click menu, always visible.

## The Problem
macOS already has "Copy as Pathname" in the right-click menu, but it only appears when you hold Option while the menu is open. Almost nobody knows that. The result is a daily friction every time you need to paste a file path into a chat, a script, a prompt, or a config file.

## What It Does Today
- Adds a "Copy Path" item to the Finder right-click menu on any file or folder
- Always visible — no modifier key required
- Copies the full POSIX path to the clipboard
- Multiple files selected → one path per line

## What It Is NOT
- Not a quoted/escaped variant. The unquoted POSIX path is what gets pasted into Claude Code, chats, prompts, and most other places. The quoted version is only useful pasting into a Terminal command, which is a rare manual case.
- Not a relative-path tool. Always absolute.
- Not a custom format tool. No URL encoding, no `file://` prefix, no Markdown link wrapping.

## Where It's Going
This is basically done once it ships. It does one thing and does it well. If a future need shows up — quoted path, file:// URL, Markdown link — add a second menu item then, not before.

The context menu item that should have been there from the start.
