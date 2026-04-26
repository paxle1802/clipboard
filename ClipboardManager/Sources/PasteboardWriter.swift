import AppKit

// Writes clipboard items back to NSPasteboard, closes panel, auto-pastes
@MainActor
struct PasteboardWriter {
    // Copy item to clipboard, close panel, auto-paste into previous app
    static func selectItem(
        _ item: ClipboardItem, monitor: ClipboardMonitor?
    ) {
        writeToClipboard(item, monitor: monitor)
        dismissAndPaste()
    }

    // Copy plain text only, close panel, auto-paste
    static func selectItemAsPlainText(
        _ item: ClipboardItem, monitor: ClipboardMonitor?
    ) {
        writeToClipboard(item, monitor: monitor, forcePlainText: true)
        dismissAndPaste()
    }

    // Copy to clipboard only (context menu "Copy")
    static func copyItem(
        _ item: ClipboardItem, monitor: ClipboardMonitor?
    ) {
        writeToClipboard(item, monitor: monitor)
    }

    // MARK: - Clipboard write

    private static func writeToClipboard(
        _ item: ClipboardItem, monitor: ClipboardMonitor?,
        forcePlainText: Bool = false
    ) {
        let pb = NSPasteboard.general

        if forcePlainText || item.contentType == .text
            || item.contentType == .rtf || item.contentType == .html
        {
            let text = item.textContent ?? item.preview
            pb.declareTypes([.string], owner: nil)
            pb.setString(text, forType: .string)
        } else if item.contentType == .image, let data = item.imageData {
            pb.declareTypes([.png], owner: nil)
            pb.setData(data, forType: .png)
        } else if item.contentType == .fileURL, let urls = item.fileURLs {
            pb.clearContents()
            pb.writeObjects(urls as [NSURL])
        }

        monitor?.syncChangeCount()
    }

    // MARK: - Dismiss and auto-paste

    private static func dismissAndPaste() {
        // 1. Close panel
        for window in NSApp.windows where window.isVisible && window is NSPanel {
            window.orderOut(nil)
        }

        // 2. Activate previous app
        SharedState.shared.panelController?.activatePreviousApp()

        // 3. Wait for focus, then invoke Paste via Accessibility menu API
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            performPasteViaMenu()
        }
    }

    // Find and click Edit > Paste in the frontmost app's menu bar
    // Uses Accessibility API — no keystroke simulation needed
    private static func performPasteViaMenu() {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            return
        }
        let appElement = AXUIElementCreateApplication(frontApp.processIdentifier)

        // Get menu bar
        var menuBarRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            appElement, kAXMenuBarAttribute as CFString, &menuBarRef
        ) == .success, let menuBar = menuBarRef else { return }

        // Iterate menu bar items to find Edit menu
        var childrenRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            menuBar as! AXUIElement, kAXChildrenAttribute as CFString,
            &childrenRef
        ) == .success, let menus = childrenRef as? [AXUIElement] else {
            return
        }

        for menu in menus {
            var titleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(
                menu, kAXTitleAttribute as CFString, &titleRef)
            guard let title = titleRef as? String else { continue }

            // Match "Edit" menu (English/Vietnamese/other locales)
            if title == "Edit" || title == "Sửa" || title == "編集" {
                // Open the Edit menu
                AXUIElementPerformAction(menu, kAXPressAction as CFString)

                // Small delay for menu to open
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    clickPasteMenuItem(in: menu)
                }
                return
            }
        }

        // Fallback: if no Edit menu found, try CGEvent as last resort
        fallbackCGEventPaste()
    }

    // Find and click "Paste" item inside the Edit menu
    private static func clickPasteMenuItem(in editMenu: AXUIElement) {
        var subMenuRef: CFTypeRef?
        // Get the submenu children of the Edit menu
        guard AXUIElementCopyAttributeValue(
            editMenu, kAXChildrenAttribute as CFString, &subMenuRef
        ) == .success, let subMenus = subMenuRef as? [AXUIElement] else {
            fallbackCGEventPaste()
            return
        }

        for subMenu in subMenus {
            var itemsRef: CFTypeRef?
            AXUIElementCopyAttributeValue(
                subMenu, kAXChildrenAttribute as CFString, &itemsRef)
            guard let items = itemsRef as? [AXUIElement] else { continue }

            for item in items {
                var itemTitle: CFTypeRef?
                AXUIElementCopyAttributeValue(
                    item, kAXTitleAttribute as CFString, &itemTitle)
                if let name = itemTitle as? String,
                   name == "Paste" || name == "Dán" || name == "ペースト"
                    || name == "貼上"
                {
                    AXUIElementPerformAction(
                        item, kAXPressAction as CFString)
                    return
                }
            }
        }

        // If Paste not found, fallback to CGEvent
        fallbackCGEventPaste()
    }

    // Last resort: CGEvent Cmd+V
    private static func fallbackCGEventPaste() {
        let source = CGEventSource(stateID: .combinedSessionState)
        guard let down = CGEvent(
            keyboardEventSource: source, virtualKey: 9, keyDown: true),
              let up = CGEvent(
            keyboardEventSource: source, virtualKey: 9, keyDown: false)
        else { return }
        down.flags = .maskCommand
        up.flags = .maskCommand
        down.post(tap: .cgAnnotatedSessionEventTap)
        up.post(tap: .cgAnnotatedSessionEventTap)
    }
}
