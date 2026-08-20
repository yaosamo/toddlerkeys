import CoreGraphics
import Foundation

struct TrackpadPressGate {
    private static let minimumInterval: TimeInterval = 0.18
    private var lastAcceptedAt: TimeInterval?

    mutating func accept(type: CGEventType, at uptime: TimeInterval) -> Bool {
        switch type {
        case .leftMouseDown, .rightMouseDown, .otherMouseDown:
            break
        default:
            return false
        }

        if let lastAcceptedAt,
           uptime - lastAcceptedAt < Self.minimumInterval {
            return false
        }
        lastAcceptedAt = uptime
        return true
    }
}
