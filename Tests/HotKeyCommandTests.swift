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

        guard failures == 0 else { exit(1) }
        print("Global hotkey tests passed")
    }

    private static func mapsLockCommands() {
        expect(GlobalHotKeys.descriptor(id: 1)?.action == .toggleLock, "maps K to unlimited lock toggle")
        expect(GlobalHotKeys.descriptor(id: 2)?.action == .twoMinutePlay, "maps T to two-minute play")
        expect(GlobalHotKeys.descriptor(id: 2)?.displayName == "⌥⌘T", "shows the timer shortcut")
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
        center.invoke(id: 13)
        center.invoke(id: 999)

        expect(actions == [.twoMinutePlay, .song(index: 2)], "dispatches only registered commands")
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
}
