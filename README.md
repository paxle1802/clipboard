# ClipboardManager

Lightweight macOS menu bar clipboard history manager built with SwiftUI.

## Features

- **Clipboard Monitoring**: Polls `NSPasteboard` every 500ms, captures text, images, RTF, HTML, and file URLs
- **Searchable History**: Real-time search across all clipboard items
- **Click-to-Paste**: Click any item to copy it back to clipboard
- **Global Hotkey**: Configurable shortcut (default: Cmd+Shift+V) via [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts)
- **Keyboard Navigation**: Arrow keys to select, Enter to paste, Esc to dismiss
- **Context Menu**: Copy, copy as plain text, delete
- **Image Compression**: Large images auto-compressed, thumbnails for list display
- **Privacy Aware**: Ignores password manager entries and concealed clipboard types
- **Settings**: Hotkey recorder, launch at login, configurable max history items

## Requirements

- macOS 14.0+ (Sonoma)
- Xcode 16+

## Build

```bash
cd ClipboardManager
xcodegen generate
xcodebuild -project ClipboardManager.xcodeproj -scheme ClipboardManager -configuration Debug build
```

Or open `ClipboardManager.xcodeproj` in Xcode and run.

## Architecture

```
ClipboardManagerApp (SwiftUI, LSUIElement)
  ├── MenuBarExtra (.window style popup)
  │     └── PopupContentView
  │           ├── Search bar
  │           ├── ClipboardItemRow list (LazyVStack)
  │           └── Footer (item count, settings, clear all)
  ├── ClipboardMonitor (Timer 500ms → NSPasteboard.changeCount)
  ├── ClipboardStore (@Observable, in-memory, 500 item soft limit)
  └── Settings (KeyboardShortcuts.Recorder, launch at login)
```
