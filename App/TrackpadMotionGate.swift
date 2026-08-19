import CoreGraphics
import Foundation

struct TrackpadMotionGate {
    private static let minimumInterval: TimeInterval = 0.04
    private static let minimumDistanceSquared: CGFloat = 14 * 14

    private var lastAcceptedPosition: CGPoint?
    private var lastAcceptedAt: TimeInterval?

    mutating func accept(position: CGPoint, at uptime: TimeInterval) -> Bool {
        guard position.x.isFinite, position.y.isFinite, uptime.isFinite else {
            return false
        }

        guard let lastAcceptedPosition, let lastAcceptedAt else {
            self.lastAcceptedPosition = position
            self.lastAcceptedAt = uptime
            return true
        }

        let deltaX = position.x - lastAcceptedPosition.x
        let deltaY = position.y - lastAcceptedPosition.y
        let distanceSquared = deltaX * deltaX + deltaY * deltaY
        guard uptime - lastAcceptedAt >= Self.minimumInterval,
              distanceSquared >= Self.minimumDistanceSquared else {
            return false
        }

        self.lastAcceptedPosition = position
        self.lastAcceptedAt = uptime
        return true
    }
}
