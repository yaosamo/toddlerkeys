import AppKit
import CoreGraphics
import SwiftUI

struct ToyKey: Identifiable, Equatable {
    let id: String
    let display: String
    let caption: String
    let sound: MappedSound
    var characters: [Character] = []
    var keyCodes: [UInt16] = []
    var flex: CGFloat = 1
    var showsCaption: Bool = true
}

struct KeyboardRow: Identifiable, Equatable {
    let id: String
    let height: CGFloat
    let keys: [ToyKey]
}

enum EffectKind: String, Equatable, CaseIterable {
    case boing, laser, duck, siren, splash, zap, pop, whistle, kick, crash
    case slideUp, slideDown, slideLeft, slideRight
    case fanfare, rewind, chord
    case sparkle, thump, giggle, magic, spark, wow, click
    case drip, bell, robot, honk, meow, cluck, coin, spring, wah, glass, ping

    var title: String {
        switch self {
        case .boing: return "Boing!"
        case .laser: return "Laser"
        case .duck: return "Quack"
        case .siren: return "Siren"
        case .splash: return "Splash"
        case .zap: return "Zap"
        case .pop: return "Pop"
        case .whistle: return "Tweet"
        case .kick: return "Boom"
        case .crash: return "Crash"
        case .slideUp: return "Whoop"
        case .slideDown: return "Whee"
        case .slideLeft: return "Swoop"
        case .slideRight: return "Sweep"
        case .fanfare: return "Tada!"
        case .rewind: return "Rewind"
        case .chord: return "Chord"
        case .sparkle: return "Sparkle"
        case .thump: return "Tick"
        case .giggle: return "Giggle"
        case .magic: return "Magic"
        case .spark: return "Spark"
        case .wow: return "Wow"
        case .click: return "Click"
        case .drip: return "Drip"
        case .bell: return "Ding"
        case .robot: return "Robot"
        case .honk: return "Honk"
        case .meow: return "Meow"
        case .cluck: return "Cluck"
        case .coin: return "Coin"
        case .spring: return "Spring"
        case .wah: return "Wah"
        case .glass: return "Glass"
        case .ping: return "Ping"
        }
    }

    var color: Color {
        switch self {
        case .boing: return Color(red: 1.00, green: 0.55, blue: 0.20)
        case .laser: return Color(red: 0.25, green: 0.88, blue: 0.45)
        case .duck: return Color(red: 1.00, green: 0.84, blue: 0.15)
        case .siren: return Color(red: 1.00, green: 0.32, blue: 0.32)
        case .splash: return Color(red: 0.25, green: 0.72, blue: 1.00)
        case .zap: return Color(red: 0.78, green: 0.45, blue: 1.00)
        case .pop: return Color(red: 1.00, green: 0.45, blue: 0.70)
        case .whistle: return Color(red: 0.40, green: 0.95, blue: 0.85)
        case .kick: return Color(red: 0.95, green: 0.38, blue: 0.22)
        case .crash: return Color(red: 0.95, green: 0.95, blue: 0.40)
        case .slideUp: return Color(red: 0.55, green: 0.75, blue: 1.00)
        case .slideDown: return Color(red: 0.45, green: 0.55, blue: 1.00)
        case .slideLeft: return Color(red: 0.70, green: 0.50, blue: 1.00)
        case .slideRight: return Color(red: 0.35, green: 0.85, blue: 0.70)
        case .fanfare: return Color(red: 1.00, green: 0.72, blue: 0.18)
        case .rewind: return Color(red: 0.85, green: 0.40, blue: 0.55)
        case .chord: return Color(red: 0.45, green: 0.82, blue: 0.55)
        case .sparkle: return Color(red: 1.00, green: 0.86, blue: 0.40)
        case .thump: return Color(red: 0.95, green: 0.82, blue: 0.35)
        case .giggle: return Color(red: 1.00, green: 0.58, blue: 0.78)
        case .magic: return Color(red: 0.62, green: 0.42, blue: 1.00)
        case .spark: return Color(red: 0.35, green: 0.92, blue: 0.95)
        case .wow: return Color(red: 1.00, green: 0.50, blue: 0.35)
        case .click: return Color(red: 0.70, green: 0.70, blue: 0.74)
        case .drip: return Color(red: 0.35, green: 0.68, blue: 1.00)
        case .bell: return Color(red: 1.00, green: 0.82, blue: 0.28)
        case .robot: return Color(red: 0.55, green: 0.80, blue: 0.45)
        case .honk: return Color(red: 1.00, green: 0.42, blue: 0.28)
        case .meow: return Color(red: 1.00, green: 0.62, blue: 0.35)
        case .cluck: return Color(red: 0.90, green: 0.55, blue: 0.20)
        case .coin: return Color(red: 1.00, green: 0.78, blue: 0.18)
        case .spring: return Color(red: 0.45, green: 0.88, blue: 0.40)
        case .wah: return Color(red: 0.85, green: 0.45, blue: 0.95)
        case .glass: return Color(red: 0.70, green: 0.88, blue: 1.00)
        case .ping: return Color(red: 0.55, green: 0.95, blue: 0.88)
        }
    }
}

enum MappedSound: Equatable {
    case note(midi: Int, name: String)
    case effect(EffectKind)

    var title: String {
        switch self {
        case .note(_, let name): return name
        case .effect(let kind): return kind.title
        }
    }

    var color: Color {
        switch self {
        case .note(let midi, _):
            let hue = Double((midi * 7) % 12) / 12.0
            return Color(hue: hue, saturation: 0.72, brightness: 0.96)
        case .effect(let kind):
            return kind.color
        }
    }
}

enum KeyMap {
    private static let modifierCodes: Set<UInt16> = [54, 55, 56, 57, 58, 59, 60, 61, 62, 63]

    static let visibleRows: [KeyboardRow] = [
        KeyboardRow(id: "fn", height: 34, keys: functionRow),
        KeyboardRow(id: "num", height: 46, keys: numberRow),
        KeyboardRow(id: "top", height: 46, keys: topRow),
        KeyboardRow(id: "home", height: 46, keys: homeRow),
        KeyboardRow(id: "bot", height: 46, keys: bottomRow),
        KeyboardRow(id: "mod", height: 46, keys: modifierRow)
    ]

    static var all: [ToyKey] {
        visibleRows.flatMap(\.keys) + hiddenKeys
    }

    static func toyKey(from event: NSEvent) -> ToyKey? {
        if event.type == .systemDefined {
            guard let press = MediaKey.press(from: event), press.isDown, !press.isRepeat else {
                return nil
            }
            return toyKey(mediaCode: press.code)
        }
        if event.type == .flagsChanged {
            return fromFlagsChanged(event)
        }
        if event.isARepeat { return nil }
        if shouldLetSystemHandle(event) { return nil }
        if modifierCodes.contains(event.keyCode) { return nil }

        if let raw = event.charactersIgnoringModifiers?.lowercased(), let ch = raw.first {
            if let match = all.first(where: { $0.characters.contains(ch) }) {
                return match
            }
        }

        if let match = all.first(where: { $0.keyCodes.contains(event.keyCode) }) {
            return match
        }

        return fallback(for: event)
    }

    static func toyKey(mediaCode: Int) -> ToyKey {
        let id = MediaKey.mappedKeyID(for: mediaCode)
        if let match = all.first(where: { $0.id == id }) {
            return match
        }
        return ToyKey(
            id: id,
            display: "▶",
            caption: "Media",
            sound: .effect(.pop),
            showsCaption: false
        )
    }

    static func toyKey(keyCode: UInt16, type: CGEventType, flags: CGEventFlags, isRepeat: Bool) -> ToyKey? {
        if isRepeat { return nil }
        switch type {
        case .flagsChanged:
            return fromFlags(keyCode: keyCode, flags: flags)
        case .keyDown:
            if modifierCodes.contains(keyCode) { return nil }
            if let match = all.first(where: { $0.keyCodes.contains(keyCode) }) {
                return match
            }
            return fallback(keyCode: keyCode)
        default:
            return nil
        }
    }

    static func shouldLetSystemHandle(_ event: NSEvent) -> Bool {
        guard event.type == .keyDown else { return false }
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        return flags.contains(.command) || flags.contains(.control) || flags.contains(.option)
    }

    static func noteName(_ midi: Int) -> String {
        let names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let name = names[((midi % 12) + 12) % 12]
        let octave = midi / 12 - 1
        return "\(name)\(octave)"
    }

    private static func fromFlagsChanged(_ event: NSEvent) -> ToyKey? {
        var flags: CGEventFlags = []
        let nsFlags = event.modifierFlags
        if nsFlags.contains(.shift) { flags.insert(.maskShift) }
        if nsFlags.contains(.control) { flags.insert(.maskControl) }
        if nsFlags.contains(.option) { flags.insert(.maskAlternate) }
        if nsFlags.contains(.command) { flags.insert(.maskCommand) }
        if nsFlags.contains(.function) { flags.insert(.maskSecondaryFn) }
        if nsFlags.contains(.capsLock) { flags.insert(.maskAlphaShift) }
        return fromFlags(keyCode: event.keyCode, flags: flags)
    }

    private static var lastCapsLockOn: Bool?

    private static func fromFlags(keyCode: UInt16, flags: CGEventFlags) -> ToyKey? {
        guard let key = all.first(where: { $0.keyCodes.contains(keyCode) }) else {
            return nil
        }
        if keyCode == 57 {
            let isOn = flags.contains(.maskAlphaShift)
            let changed = lastCapsLockOn.map { $0 != isOn } ?? true
            lastCapsLockOn = isOn
            return changed ? key : nil
        }

        let isDown: Bool
        switch keyCode {
        case 56, 60: isDown = flags.contains(.maskShift)
        case 59, 62: isDown = flags.contains(.maskControl)
        case 58, 61: isDown = flags.contains(.maskAlternate)
        case 55, 54: isDown = flags.contains(.maskCommand)
        case 63: isDown = flags.contains(.maskSecondaryFn)
        default: isDown = false
        }
        return isDown ? key : nil
    }

    private static func fallback(for event: NSEvent) -> ToyKey {
        let raw = event.charactersIgnoringModifiers?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let display = raw.isEmpty ? "•" : String(raw.prefix(2)).uppercased()
        var key = fallback(keyCode: event.keyCode)
        key = ToyKey(
            id: key.id,
            display: display,
            caption: key.caption,
            sound: key.sound,
            characters: key.characters,
            keyCodes: key.keyCodes,
            flex: key.flex,
            showsCaption: false
        )
        return key
    }

    private static func fallback(keyCode: UInt16) -> ToyKey {
        let code = Int(keyCode)
        let midi = 48 + (code % 24)
        return ToyKey(
            id: "code-\(code)",
            display: "•",
            caption: "Key",
            sound: .note(midi: midi, name: noteName(midi)),
            keyCodes: [keyCode],
            showsCaption: false
        )
    }

    private static let functionRow: [ToyKey] = {
        let fKeys: [(String, UInt16, Int)] = [
            ("f1", 122, 72), ("f2", 120, 74), ("f3", 99, 76), ("f4", 118, 79),
            ("f5", 96, 81), ("f6", 97, 84), ("f7", 98, 86), ("f8", 100, 88),
            ("f9", 101, 91), ("f10", 109, 93), ("f11", 103, 96), ("f12", 111, 98)
        ]
        var row: [ToyKey] = [
            key("esc", display: "esc", caption: "Sparkle", sound: .effect(.sparkle), codes: [53], flex: 1.25, captioned: false)
        ]
        row += fKeys.map { id, code, midi in
            key(
                id,
                display: id.uppercased(),
                caption: noteName(midi),
                sound: .note(midi: midi, name: noteName(midi)),
                codes: [code],
                captioned: false
            )
        }
        return row
    }()

    private static let numberRow: [ToyKey] = [
        key("grave", display: "`", caption: "Robot", sound: .effect(.robot), chars: "`~", codes: [50], captioned: false),
        effect("1", display: "1", caption: "Boing", .boing, codes: [18]),
        effect("2", display: "2", caption: "Laser", .laser, codes: [19]),
        effect("3", display: "3", caption: "Quack", .duck, codes: [20]),
        effect("4", display: "4", caption: "Siren", .siren, codes: [21]),
        effect("5", display: "5", caption: "Splash", .splash, codes: [23]),
        effect("6", display: "6", caption: "Zap", .zap, codes: [22]),
        effect("7", display: "7", caption: "Pop", .pop, codes: [26]),
        effect("8", display: "8", caption: "Tweet", .whistle, codes: [28]),
        effect("9", display: "9", caption: "Boom", .kick, codes: [25]),
        effect("0", display: "0", caption: "Crash", .crash, codes: [29]),
        key("-", display: "-", caption: "Drip", sound: .effect(.drip), chars: "-_", codes: [27], captioned: false),
        key("=", display: "=", caption: "Ding", sound: .effect(.bell), chars: "=+", codes: [24], captioned: false),
        key("delete", display: "⌫", caption: "Rewind", sound: .effect(.rewind), codes: [51], flex: 1.55, captioned: false)
    ]

    private static let topRow: [ToyKey] = [
        key("tab", display: "tab", caption: "Chord", sound: .effect(.chord), chars: "\t", codes: [48], flex: 1.45, captioned: false)
    ] + letterRow([
        ("q", 12, 74), ("w", 13, 76), ("e", 14, 79), ("r", 15, 81), ("t", 17, 84),
        ("y", 16, 86), ("u", 32, 88), ("i", 34, 91), ("o", 31, 93), ("p", 35, 96)
    ]) + [
        key("[", display: "[", caption: "Glass", sound: .effect(.glass), chars: "[{", codes: [33], captioned: false),
        key("]", display: "]", caption: "Ping", sound: .effect(.ping), chars: "]}", codes: [30], captioned: false),
        key("\\", display: "\\", caption: "Honk", sound: .effect(.honk), chars: "\\", codes: [42], flex: 1.3, captioned: false)
    ]

    private static let homeRow: [ToyKey] = [
        key("caps", display: "caps", caption: "Giggle", sound: .effect(.giggle), codes: [57], flex: 1.75, captioned: false)
    ] + letterRow([
        ("a", 0, 64), ("s", 1, 67), ("d", 2, 69), ("f", 3, 72), ("g", 5, 74),
        ("h", 4, 76), ("j", 38, 79), ("k", 40, 81), ("l", 37, 84)
    ]) + [
        key(";", display: ";", caption: "Cluck", sound: .effect(.cluck), chars: ";:", codes: [41], captioned: false),
        key("'", display: "'", caption: "Meow", sound: .effect(.meow), chars: "'\"", codes: [39], captioned: false),
        key("return", display: "return", caption: "Tada", sound: .effect(.fanfare), codes: [36], flex: 1.85, captioned: false)
    ]

    private static let bottomRow: [ToyKey] = [
        key("lshift", display: "shift", caption: "Thump", sound: .effect(.thump), codes: [56], flex: 2.25, captioned: false)
    ] + letterRow([
        ("z", 6, 60), ("x", 7, 62), ("c", 8, 64), ("v", 9, 67), ("b", 11, 69),
        ("n", 45, 72), ("m", 46, 74)
    ]) + [
        key(",", display: ",", caption: "Spring", sound: .effect(.spring), chars: ",<", codes: [43], captioned: false),
        key(".", display: ".", caption: "Coin", sound: .effect(.coin), chars: ".>", codes: [47], captioned: false),
        key("/", display: "/", caption: "Wah", sound: .effect(.wah), chars: "/?", codes: [44], captioned: false),
        key("rshift", display: "shift", caption: "Thump", sound: .effect(.thump), codes: [60], flex: 2.35, captioned: false)
    ]

    private static let modifierRow: [ToyKey] = [
        key("fn", display: "fn", caption: "Click", sound: .effect(.click), codes: [63], flex: 1.1, captioned: false),
        key("lctrl", display: "ctrl", caption: "Spark", sound: .effect(.spark), codes: [59], flex: 1.15, captioned: false),
        key("lopt", display: "opt", caption: "Magic", sound: .effect(.magic), codes: [58], flex: 1.15, captioned: false),
        key("lcmd", display: "⌘", caption: "Wow", sound: .effect(.wow), codes: [55], flex: 1.4, captioned: false),
        key("space", display: "space", caption: "Boom", sound: .effect(.kick), chars: " ", codes: [49], flex: 5.6, captioned: false),
        key("rcmd", display: "⌘", caption: "Wow", sound: .effect(.wow), codes: [54], flex: 1.4, captioned: false),
        key("ropt", display: "opt", caption: "Magic", sound: .effect(.magic), codes: [61], flex: 1.15, captioned: false),
        key("left", display: "←", caption: "Swoop", sound: .effect(.slideLeft), codes: [123], captioned: false),
        key("down", display: "↓", caption: "Whee", sound: .effect(.slideDown), codes: [125], captioned: false),
        key("up", display: "↑", caption: "Whoop", sound: .effect(.slideUp), codes: [126], captioned: false),
        key("right", display: "→", caption: "Sweep", sound: .effect(.slideRight), codes: [124], captioned: false)
    ]

    private static let hiddenKeys: [ToyKey] = [
        key("fwd-delete", display: "⌦", caption: "Zap", sound: .effect(.zap), codes: [117], captioned: false),
        key("kp-enter", display: "⏎", caption: "Tada", sound: .effect(.fanfare), codes: [76], captioned: false),
        key("kp-clear", display: "clr", caption: "Crash", sound: .effect(.crash), codes: [71], captioned: false),
        key("kp-plus", display: "+", caption: "Ding", sound: .effect(.bell), chars: "+", codes: [69], captioned: false),
        key("kp-minus", display: "-", caption: "Drip", sound: .effect(.drip), codes: [78], captioned: false),
        key("kp-multiply", display: "*", caption: "Sparkle", sound: .effect(.sparkle), chars: "*", codes: [67], captioned: false),
        key("kp-divide", display: "/", caption: "Wah", sound: .effect(.wah), codes: [75], captioned: false),
        key("kp-equals", display: "=", caption: "Ding", sound: .effect(.bell), codes: [81], captioned: false),
        key("kp-decimal", display: ".", caption: "Coin", sound: .effect(.coin), codes: [65], captioned: false),
        key("home", display: "home", caption: "Chord", sound: .effect(.chord), codes: [115], captioned: false),
        key("end", display: "end", caption: "Rewind", sound: .effect(.rewind), codes: [119], captioned: false),
        key("pageup", display: "pgup", caption: "Whoop", sound: .effect(.slideUp), codes: [116], captioned: false),
        key("pagedown", display: "pgdn", caption: "Whee", sound: .effect(.slideDown), codes: [121], captioned: false),
        key("help", display: "help", caption: "Sparkle", sound: .effect(.sparkle), codes: [114], captioned: false),
        key("f13", display: "F13", caption: noteName(100), sound: .note(midi: 100, name: noteName(100)), codes: [105], captioned: false),
        key("f14", display: "F14", caption: noteName(103), sound: .note(midi: 103, name: noteName(103)), codes: [107], captioned: false),
        key("f15", display: "F15", caption: noteName(105), sound: .note(midi: 105, name: noteName(105)), codes: [113], captioned: false),
        key("iso", display: "§", caption: "Robot", sound: .effect(.robot), chars: "§±", codes: [10], captioned: false)
    ]

    private static func letterRow(_ items: [(String, UInt16, Int)]) -> [ToyKey] {
        items.map { id, code, midi in
            key(
                id,
                display: id.uppercased(),
                caption: noteName(midi),
                sound: .note(midi: midi, name: noteName(midi)),
                chars: id,
                codes: [code]
            )
        }
    }

    private static func effect(
        _ id: String,
        display: String,
        caption: String,
        _ kind: EffectKind,
        codes: [UInt16]
    ) -> ToyKey {
        key(id, display: display, caption: caption, sound: .effect(kind), chars: id, codes: codes)
    }

    private static func key(
        _ id: String,
        display: String,
        caption: String,
        sound: MappedSound,
        chars: String = "",
        codes: [UInt16] = [],
        flex: CGFloat = 1,
        captioned: Bool = true
    ) -> ToyKey {
        ToyKey(
            id: id,
            display: display,
            caption: caption,
            sound: sound,
            characters: Array(chars),
            keyCodes: codes,
            flex: flex,
            showsCaption: captioned
        )
    }
}
