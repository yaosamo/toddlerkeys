import Carbon
import CoreGraphics

enum GlobalHotKeyAction: Equatable {
    case toggleLock
    case twoMinutePlay
    case song(index: Int)
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

    static let songs: [GlobalHotKeyDescriptor] = [
        song(id: 11, keyCode: UInt32(kVK_ANSI_1), number: 1),
        song(id: 12, keyCode: UInt32(kVK_ANSI_2), number: 2),
        song(id: 13, keyCode: UInt32(kVK_ANSI_3), number: 3),
        song(id: 14, keyCode: UInt32(kVK_ANSI_4), number: 4),
        song(id: 15, keyCode: UInt32(kVK_ANSI_5), number: 5)
    ]

    static let all = [toggleLock, twoMinutePlay] + songs

    static func descriptor(id: UInt32) -> GlobalHotKeyDescriptor? {
        all.first { $0.id == id }
    }

    static func action(keyCode: Int64, flags: CGEventFlags) -> GlobalHotKeyAction? {
        let needed: CGEventFlags = [.maskAlternate, .maskCommand]
        let relevant = flags.intersection([.maskControl, .maskAlternate, .maskCommand, .maskShift])
        guard relevant == needed else { return nil }
        return all.first { keyCode == Int64($0.keyCode) }?.action
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

struct GlobalHotKeyGate {
    let minimumInterval: TimeInterval

    private var lastAction: GlobalHotKeyAction?
    private var lastAcceptedAt: TimeInterval?

    init(minimumInterval: TimeInterval = 0.4) {
        self.minimumInterval = minimumInterval
    }

    mutating func accept(_ action: GlobalHotKeyAction, at time: TimeInterval) -> Bool {
        if action == lastAction,
           let lastAcceptedAt,
           time - lastAcceptedAt < minimumInterval {
            return false
        }

        lastAction = action
        lastAcceptedAt = time
        return true
    }
}
