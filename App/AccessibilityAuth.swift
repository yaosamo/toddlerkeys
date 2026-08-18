import ApplicationServices
import AppKit
import CoreGraphics

enum AccessibilityAuth {
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    static var canListenToKeys: Bool {
        CGPreflightListenEventAccess()
    }

    static var canPostEvents: Bool {
        CGPreflightPostEventAccess()
    }

    static var canLockKeyboard: Bool {
        isTrusted && canListenToKeys
    }

    static func prompt() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
        if !canListenToKeys {
            CGRequestListenEventAccess()
        }
        if !canPostEvents {
            CGRequestPostEventAccess()
        }
    }

    static func openSettings() {
        let candidates = [
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent"
        ]
        for candidate in candidates {
            if let url = URL(string: candidate) {
                NSWorkspace.shared.open(url)
                return
            }
        }
    }
}
