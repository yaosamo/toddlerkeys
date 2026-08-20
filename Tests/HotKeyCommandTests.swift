import Carbon
import CoreGraphics
import Darwin
import Foundation

private var failures = 0

private func expect(_ condition: @autoclosure () -> Bool, _ behavior: String) {
    guard condition() else {
        failures += 1
        fputs("FAIL: \(behavior)\n", stderr)
        return
    }
}

@main
private enum HotKeyCommandTests {
    static func main() {
        mapsLockCommands()
        mapsEverySongCommand()
        keepsRegistrationsUnique()
        ignoresUnknownCommands()
        dispatchesKnownCommandsOnly()
        preservesExactParentUnlockChord()
        mapsLockedEventTapCommands()
        ignoresLockedHotKeyRepeats()
        acceptsOneShortcutSourcePerSessionState()

        guard failures == 0 else { exit(1) }
        print("Global hotkey tests passed")
    }

    private static func mapsLockCommands() {
        expect(GlobalHotKeys.descriptor(id: 1)?.action == .toggleLock, "maps K to unlimited lock toggle")
        expect(GlobalHotKeys.descriptor(id: 2)?.action == .twoMinutePlay, "maps T to two-minute play")
        expect(GlobalHotKeys.descriptor(id: 2)?.displayName == "⌥⌘T", "shows the timer shortcut")
        expect(GlobalHotKeys.descriptor(id: 3)?.action == .playSong, "maps P to play the selected song")
        expect(GlobalHotKeys.descriptor(id: 3)?.displayName == "⌥⌘P", "shows the play-song shortcut")
    }

    private static func mapsEverySongCommand() {
        for index in 0..<5 {
            let descriptor = GlobalHotKeys.descriptor(id: UInt32(11 + index))
            expect(descriptor?.action == .song(index: index), "maps song shortcut \(index + 1)")
            expect(descriptor?.displayName == "⌥⌘\(index + 1)", "shows song shortcut \(index + 1)")
        }
    }

    private static func keepsRegistrationsUnique() {
        let ids = Set(GlobalHotKeys.all.map(\.id))
        let chords = Set(GlobalHotKeys.all.map { "\($0.carbonModifiers):\($0.keyCode)" })
        expect(ids.count == GlobalHotKeys.all.count, "uses a unique ID for every command")
        expect(chords.count == GlobalHotKeys.all.count, "uses a unique key chord for every command")
    }

    private static func ignoresUnknownCommands() {
        expect(GlobalHotKeys.descriptor(id: 999) == nil, "ignores unknown Carbon hotkey IDs")
    }

    private static func dispatchesKnownCommandsOnly() {
        let center = HotKeyCenter()
        var actions: [GlobalHotKeyAction] = []
        center.onPressed = { actions.append($0) }

        center.invoke(id: 2)
        center.invoke(id: 3)
        center.invoke(id: 13)
        center.invoke(id: 999)

        expect(actions == [.twoMinutePlay, .playSong, .song(index: 2)], "dispatches only registered commands")
    }

    private static func preservesExactParentUnlockChord() {
        let required: CGEventFlags = [.maskAlternate, .maskCommand]
        expect(ToggleHotKey.matches(keyCode: Int64(kVK_ANSI_K), flags: required), "accepts option-command-K")
        expect(
            !ToggleHotKey.matches(keyCode: Int64(kVK_ANSI_K), flags: required.union(.maskShift)),
            "rejects option-command-shift-K"
        )
        expect(
            !ToggleHotKey.matches(keyCode: Int64(kVK_ANSI_T), flags: required),
            "keeps option-command-T out of the unlock path"
        )
    }

    private static func mapsLockedEventTapCommands() {
        let required: CGEventFlags = [.maskAlternate, .maskCommand]
        expect(
            GlobalHotKeys.action(keyCode: Int64(kVK_ANSI_K), flags: required) == .toggleLock,
            "maps option-command-K inside the locked event tap"
        )
        expect(
            GlobalHotKeys.action(keyCode: Int64(kVK_ANSI_T), flags: required) == .twoMinutePlay,
            "maps option-command-T inside the locked event tap"
        )
        expect(
            GlobalHotKeys.action(keyCode: Int64(kVK_ANSI_P), flags: required) == .playSong,
            "maps option-command-P inside the locked event tap"
        )

        for (index, descriptor) in GlobalHotKeys.songs.enumerated() {
            expect(
                GlobalHotKeys.action(keyCode: Int64(descriptor.keyCode), flags: required) == .song(index: index),
                "maps option-command-\(index + 1) inside the locked event tap"
            )
        }

        expect(
            GlobalHotKeys.action(keyCode: Int64(kVK_ANSI_1), flags: required.union(.maskShift)) == nil,
            "rejects song chords with extra shift"
        )
        expect(
            GlobalHotKeys.action(keyCode: Int64(kVK_ANSI_1), flags: required.union(.maskControl)) == nil,
            "rejects song chords with extra control"
        )
        expect(
            GlobalHotKeys.action(keyCode: Int64(kVK_ANSI_A), flags: required) == nil,
            "rejects unrelated option-command keys"
        )
    }

    private static func ignoresLockedHotKeyRepeats() {
        let required: CGEventFlags = [.maskAlternate, .maskCommand]
        expect(
            GlobalHotKeys.action(
                keyCode: Int64(kVK_ANSI_1),
                flags: required,
                isRepeat: true
            ) == nil,
            "ignores repeated song key-down events"
        )
        expect(
            GlobalHotKeys.action(
                keyCode: Int64(kVK_ANSI_K),
                flags: required,
                isRepeat: true
            ) == nil,
            "ignores repeated lock-toggle key-down events"
        )
    }

    private static func acceptsOneShortcutSourcePerSessionState() {
        expect(
            HotKeySourcePolicy.accepts(source: .global, isLocked: false, isKeyboardLocked: false),
            "accepts the global source while unlocked"
        )
        expect(
            !HotKeySourcePolicy.accepts(source: .lockedEventTap, isLocked: false, isKeyboardLocked: false),
            "rejects the inactive event-tap source while unlocked"
        )
        expect(
            HotKeySourcePolicy.accepts(source: .lockedEventTap, isLocked: true, isKeyboardLocked: true),
            "accepts the event tap during a real keyboard lock"
        )
        expect(
            !HotKeySourcePolicy.accepts(source: .global, isLocked: true, isKeyboardLocked: true),
            "rejects duplicate global delivery during a real keyboard lock"
        )
        expect(
            HotKeySourcePolicy.accepts(source: .global, isLocked: true, isKeyboardLocked: false),
            "keeps the global source as a fallback when the event tap failed"
        )
    }
}
