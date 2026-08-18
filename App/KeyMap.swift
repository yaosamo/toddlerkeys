import AppKit
import SwiftUI

struct ToyKey: Identifiable, Equatable {
    let id: String
    let display: String
    let caption: String
    let sound: MappedSound
    var characters: [Character] = []
    var keyCodes: [UInt16] = []
    var flex: CGFloat = 1
}

enum EffectKind: String, Equatable, CaseIterable {
    case boing
    case laser
    case duck
    case siren
    case splash
    case zap
    case pop
    case whistle
    case kick
    case crash
    case slideUp
    case slideDown
    case slideLeft
    case slideRight
    case fanfare
    case rewind
    case chord

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
    static let numberRow: [ToyKey] = [
        effectKey("1", display: "1", caption: "Boing", .boing),
        effectKey("2", display: "2", caption: "Laser", .laser),
        effectKey("3", display: "3", caption: "Quack", .duck),
        effectKey("4", display: "4", caption: "Siren", .siren),
        effectKey("5", display: "5", caption: "Splash", .splash),
        effectKey("6", display: "6", caption: "Zap", .zap),
        effectKey("7", display: "7", caption: "Pop", .pop),
        effectKey("8", display: "8", caption: "Tweet", .whistle),
        effectKey("9", display: "9", caption: "Boom", .kick),
        effectKey("0", display: "0", caption: "Crash", .crash)
    ]

    static let topRow: [ToyKey] = letterRow([
        ("q", 74, "D5"),
        ("w", 76, "E5"),
        ("e", 79, "G5"),
        ("r", 81, "A5"),
        ("t", 84, "C6"),
        ("y", 86, "D6"),
        ("u", 88, "E6"),
        ("i", 91, "G6"),
        ("o", 93, "A6"),
        ("p", 96, "C7")
    ])

    static let homeRow: [ToyKey] = letterRow([
        ("a", 64, "E4"),
        ("s", 67, "G4"),
        ("d", 69, "A4"),
        ("f", 72, "C5"),
        ("g", 74, "D5"),
        ("h", 76, "E5"),
        ("j", 79, "G5"),
        ("k", 81, "A5"),
        ("l", 84, "C6")
    ])

    static let bottomRow: [ToyKey] = letterRow([
        ("z", 60, "C4"),
        ("x", 62, "D4"),
        ("c", 64, "E4"),
        ("v", 67, "G4"),
        ("b", 69, "A4"),
        ("n", 72, "C5"),
        ("m", 74, "D5")
    ])

    static let space = ToyKey(
        id: "space",
        display: "SPACE",
        caption: "Boom",
        sound: .effect(.kick),
        characters: [" "],
        keyCodes: [49],
        flex: 6
    )

    static let extraKeys: [ToyKey] = [
        ToyKey(id: "return", display: "⏎", caption: "Tada", sound: .effect(.fanfare), keyCodes: [36, 76]),
        ToyKey(id: "tab", display: "⇥", caption: "Chord", sound: .effect(.chord), keyCodes: [48]),
        ToyKey(id: "delete", display: "⌫", caption: "Rewind", sound: .effect(.rewind), keyCodes: [51, 117]),
        ToyKey(id: "up", display: "↑", caption: "Whoop", sound: .effect(.slideUp), keyCodes: [126]),
        ToyKey(id: "down", display: "↓", caption: "Whee", sound: .effect(.slideDown), keyCodes: [125]),
        ToyKey(id: "left", display: "←", caption: "Swoop", sound: .effect(.slideLeft), keyCodes: [123]),
        ToyKey(id: "right", display: "→", caption: "Sweep", sound: .effect(.slideRight), keyCodes: [124])
    ]

    static var visibleRows: [[ToyKey]] {
        [numberRow, topRow, homeRow, bottomRow, [space]]
    }

    static var all: [ToyKey] {
        numberRow + topRow + homeRow + bottomRow + [space] + extraKeys
    }

    static func toyKey(from event: NSEvent) -> ToyKey? {
        if event.isARepeat { return nil }
        if shouldLetSystemHandle(event) { return nil }

        if let raw = event.charactersIgnoringModifiers?.lowercased(), let ch = raw.first {
            if let match = all.first(where: { $0.characters.contains(ch) }) {
                return match
            }
        }

        return all.first(where: { $0.keyCodes.contains(event.keyCode) })
    }

    static func shouldLetSystemHandle(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        return flags.contains(.command) || flags.contains(.control) || flags.contains(.option)
    }

    private static func letterRow(_ items: [(String, Int, String)]) -> [ToyKey] {
        items.map { id, midi, name in
            ToyKey(
                id: id,
                display: id.uppercased(),
                caption: name,
                sound: .note(midi: midi, name: name),
                characters: [Character(id)]
            )
        }
    }

    private static func effectKey(_ id: String, display: String, caption: String, _ kind: EffectKind) -> ToyKey {
        ToyKey(
            id: id,
            display: display,
            caption: caption,
            sound: .effect(kind),
            characters: [Character(id)]
        )
    }
}
