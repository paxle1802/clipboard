import KeyboardShortcuts

// Define global keyboard shortcut names used throughout the app
extension KeyboardShortcuts.Name {
    static let toggleClipboardHistory = Self(
        "toggleClipboardHistory",
        default: .init(.v, modifiers: [.command, .shift])
    )
}
