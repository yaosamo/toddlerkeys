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
private enum PlaySessionClockTests {
    static func main() {
        twoMinuteSessionStartsWithFullCountdown()
        twoMinuteSessionShowsFinalSecond()
        twoMinuteSessionExpiresAtDeadline()
        unlimitedSessionNeverExpires()
        refusalFeedbackRejectsRapidRepeats()
        refusalFeedbackAcceptsExactBoundary()

        guard failures == 0 else { exit(1) }
        print("Play session tests passed")
    }

    private static func twoMinuteSessionStartsWithFullCountdown() {
        let clock = PlaySessionClock(limit: .twoMinutes, startedAt: 40)
        expect(clock.state(at: 40) == .active(secondsRemaining: 120), "starts at two minutes")
    }

    private static func twoMinuteSessionShowsFinalSecond() {
        let clock = PlaySessionClock(limit: .twoMinutes, startedAt: 40)
        expect(clock.state(at: 159.01) == .active(secondsRemaining: 1), "shows one second before expiry")
    }

    private static func twoMinuteSessionExpiresAtDeadline() {
        let clock = PlaySessionClock(limit: .twoMinutes, startedAt: 40)
        expect(clock.state(at: 160) == .expired, "expires exactly at 120 seconds")
    }

    private static func unlimitedSessionNeverExpires() {
        let clock = PlaySessionClock(limit: .unlimited, startedAt: 40)
        expect(clock.state(at: 4_000) == .unlimited, "keeps unlimited sessions unlimited")
    }

    private static func refusalFeedbackRejectsRapidRepeats() {
        var gate = RefusalGate(minimumInterval: 0.65)
        expect(gate.accept(at: 10), "accepts the first refusal")
        expect(!gate.accept(at: 10.2), "throttles rapid refusal feedback")
        expect(gate.accept(at: 10.7), "accepts a later refusal")
    }

    private static func refusalFeedbackAcceptsExactBoundary() {
        var gate = RefusalGate(minimumInterval: 0.65)
        _ = gate.accept(at: 10)
        expect(gate.accept(at: 10.65), "accepts feedback at the throttle boundary")
    }
}
