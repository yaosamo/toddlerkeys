import Carbon
import CoreGraphics

enum ToggleHotKey {
    static let keyCode = UInt32(kVK_ANSI_K)
    static let carbonModifiers = UInt32(optionKey | cmdKey)
    static let displayName = "⌥⌘K"

    static func matches(keyCode: Int64, flags: CGEventFlags) -> Bool {
        let needed: CGEventFlags = [.maskAlternate, .maskCommand]
        let relevant = flags.intersection([.maskControl, .maskAlternate, .maskCommand, .maskShift])
        return keyCode == Int64(Self.keyCode) && relevant == needed
    }
}
