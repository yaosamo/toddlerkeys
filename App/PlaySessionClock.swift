import Foundation

enum PlaySessionLimit: Equatable {
    case unlimited
    case twoMinutes

    fileprivate var duration: TimeInterval? {
        switch self {
        case .unlimited: nil
        case .twoMinutes: 120
        }
    }
}

enum PlaySessionState: Equatable {
    case unlimited
    case active(secondsRemaining: Int)
    case expired
}

struct PlaySessionClock {
    private let deadline: TimeInterval?

    init(limit: PlaySessionLimit, startedAt: TimeInterval) {
        deadline = limit.duration.map { startedAt + $0 }
    }

    func state(at uptime: TimeInterval) -> PlaySessionState {
        guard let deadline else { return .unlimited }
        let remaining = deadline - uptime
        guard remaining > 0 else { return .expired }
        return .active(secondsRemaining: max(1, Int(ceil(remaining))))
    }
}

struct RefusalGate {
    let minimumInterval: TimeInterval
    private var lastAcceptedAt: TimeInterval?

    init(minimumInterval: TimeInterval = 0.65) {
        self.minimumInterval = minimumInterval
    }

    mutating func accept(at uptime: TimeInterval) -> Bool {
        if let lastAcceptedAt, uptime - lastAcceptedAt < minimumInterval {
            return false
        }
        lastAcceptedAt = uptime
        return true
    }
}
