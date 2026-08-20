import Carbon
import CoreGraphics

enum GlobalHotKeyAction: Equatable {
    case toggleLock
    case twoMinutePlay
    case playSong
    case song(index: Int)
}

enum HotKeySource: Equatable {
    case global
    case lockedEventTap
}

enum HotKeySourcePolicy {
    static func accepts(source: HotKeySource, isLocked: Bool, isKeyboardLocked: Bool) -> Bool {
        if !isLocked {
            return source == .global
        }
        if isKeyboardLocked {
            return source == .lockedEventTap
        }
        return source == .global
    }
}

enum SongHotKeyEffect: Equatable {
    case unlock
    case follow
}

enum SongHotKeyPolicy {
    /// Same song while locked unlocks; any other song selects/follows (and locks if needed).
    static func effect(isLocked: Bool, selectedSongID: String?, requestedSongID: String) -> SongHotKeyEffect {
        if isLocked, selectedSongID == requestedSongID {
            return .unlock
        }
        return .follow
    }
}

/// Ignores the duplicate delivery of the chord that just flipped lock state.
/// On that key's key-up, suppression shrinks to a tiny tail so the next press
/// can unlock immediately without waiting out a long debounce.
struct LockChordEchoGate {
    private var action: GlobalHotKeyAction?
    private var keyCode: UInt32?
    private var until: TimeInterval = 0

    mutating func suppressEcho(
        of action: GlobalHotKeyAction,
        keyCode: UInt32,
        at time: TimeInterval,
        for interval: TimeInterval = 0.15
    ) {
        self.action = action
        self.keyCode = keyCode
        self.until = time + interval
    }

    mutating func clear() {
        action = nil
        keyCode = nil
        until = 0
    }

    mutating func clearOnKeyUp(_ keyCode: UInt32, at time: TimeInterval, tail: TimeInterval = 0.05) {
        guard self.keyCode == keyCode, action != nil else { return }
        // Keep a short tail for deferred main-queue echoes after release.
        until = time + tail
    }

    func shouldIgnore(_ action: GlobalHotKeyAction, at time: TimeInterval) -> Bool {
        guard let suppressed = self.action else { return false }
        return action == suppressed && time < until
    }
}

struct GlobalHotKeyDescriptor: Equatable {
    let id: UInt32
    let keyCode: UInt32
    let carbonModifiers: UInt32
    let displayName: String
    let action: GlobalHotKeyAction
}

enum GlobalHotKeys {
    private static let modifiers = UInt32(optionKey | cmdKey)

    static let toggleLock = GlobalHotKeyDescriptor(
        id: 1,
        keyCode: UInt32(kVK_ANSI_K),
        carbonModifiers: modifiers,
        displayName: "⌥⌘K",
        action: .toggleLock
    )

    static let twoMinutePlay = GlobalHotKeyDescriptor(
        id: 2,
        keyCode: UInt32(kVK_ANSI_T),
        carbonModifiers: modifiers,
        displayName: "⌥⌘T",
        action: .twoMinutePlay
    )

    static let playSong = GlobalHotKeyDescriptor(
        id: 3,
        keyCode: UInt32(kVK_ANSI_P),
        carbonModifiers: modifiers,
        displayName: "⌥⌘P",
        action: .playSong
    )

    static let songs: [GlobalHotKeyDescriptor] = [
        song(id: 11, keyCode: UInt32(kVK_ANSI_1), number: 1),
        song(id: 12, keyCode: UInt32(kVK_ANSI_2), number: 2),
        song(id: 13, keyCode: UInt32(kVK_ANSI_3), number: 3),
        song(id: 14, keyCode: UInt32(kVK_ANSI_4), number: 4),
        song(id: 15, keyCode: UInt32(kVK_ANSI_5), number: 5)
    ]

    static let all = [toggleLock, twoMinutePlay, playSong] + songs

    static func descriptor(id: UInt32) -> GlobalHotKeyDescriptor? {
        all.first { $0.id == id }
    }

    static func descriptor(action: GlobalHotKeyAction) -> GlobalHotKeyDescriptor? {
        all.first { $0.action == action }
    }

    static func descriptor(keyCode: Int64, flags: CGEventFlags) -> GlobalHotKeyDescriptor? {
        let needed: CGEventFlags = [.maskAlternate, .maskCommand]
        let relevant = flags.intersection([.maskControl, .maskAlternate, .maskCommand, .maskShift])
        guard relevant == needed else { return nil }
        return all.first { keyCode == Int64($0.keyCode) }
    }

    static func action(
        keyCode: Int64,
        flags: CGEventFlags,
        isRepeat: Bool = false
    ) -> GlobalHotKeyAction? {
        guard !isRepeat else { return nil }
        return descriptor(keyCode: keyCode, flags: flags)?.action
    }

    private static func song(id: UInt32, keyCode: UInt32, number: Int) -> GlobalHotKeyDescriptor {
        GlobalHotKeyDescriptor(
            id: id,
            keyCode: keyCode,
            carbonModifiers: modifiers,
            displayName: "⌥⌘\(number)",
            action: .song(index: number - 1)
        )
    }
}

enum ToggleHotKey {
    static let keyCode = GlobalHotKeys.toggleLock.keyCode
    static let carbonModifiers = GlobalHotKeys.toggleLock.carbonModifiers
    static let displayName = GlobalHotKeys.toggleLock.displayName

    static func matches(keyCode: Int64, flags: CGEventFlags) -> Bool {
        GlobalHotKeys.action(keyCode: keyCode, flags: flags) == .toggleLock
    }
}
