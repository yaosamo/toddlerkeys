import AppKit
import CoreGraphics

enum MediaKey {
    static let systemDefinedType = CGEventType(rawValue: 14)!
    static let auxSubtype: Int16 = 8

    static let play = 16
    static let next = 17
    static let previous = 18
    static let fast = 19
    static let rewind = 20
    static let mute = 7
    static let soundUp = 0
    static let soundDown = 1
    static let brightnessUp = 2
    static let brightnessDown = 3
    static let illuminationUp = 21
    static let illuminationDown = 22
    static let illuminationToggle = 23

    struct Press {
        let code: Int
        let isDown: Bool
        let isRepeat: Bool
    }

    static func press(from event: CGEvent) -> Press? {
        guard event.type == systemDefinedType || event.type.rawValue == 14 else { return nil }
        guard let nsEvent = NSEvent(cgEvent: event) else { return nil }
        return press(from: nsEvent)
    }

    static func press(from event: NSEvent) -> Press? {
        guard event.type == .systemDefined, event.subtype.rawValue == auxSubtype else { return nil }
        let code = (event.data1 & 0xFFFF0000) >> 16
        let flags = event.data1 & 0x0000FFFF
        let state = (flags & 0xFF00) >> 8
        return Press(
            code: code,
            isDown: state == 0xA,
            isRepeat: (flags & 0x1) == 1
        )
    }

    static func mappedKeyID(for code: Int) -> String {
        switch code {
        case rewind, previous: return "f7"
        case play: return "f8"
        case fast, next: return "f9"
        case mute: return "f10"
        case soundDown: return "f11"
        case soundUp: return "f12"
        case brightnessDown: return "f1"
        case brightnessUp: return "f2"
        case illuminationDown, illuminationToggle: return "f5"
        case illuminationUp: return "f6"
        default: return "media-\(code)"
        }
    }
}
