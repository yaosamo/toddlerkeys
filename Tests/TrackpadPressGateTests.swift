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
private enum TrackpadPressGateTests {
    static func main() {
        acceptsMouseDownEvents()
        rejectsNonPressEvents()
        collapsesClusteredButtonEvents()
        acceptsLaterPresses()

        guard failures == 0 else { exit(1) }
        print("TrackpadPressGate tests passed")
    }

    private static func acceptsMouseDownEvents() {
        for type in [CGEventType.leftMouseDown, .rightMouseDown, .otherMouseDown] {
            var gate = TrackpadPressGate()
            expect(gate.accept(type: type, at: 10), "accepts \(type) as a real press")
        }
    }

    private static func rejectsNonPressEvents() {
        let rejected: [CGEventType] = [
            .keyDown, .flagsChanged, .leftMouseUp, .leftMouseDragged,
            .rightMouseUp, .rightMouseDragged, .otherMouseUp,
            .otherMouseDragged, .scrollWheel
        ]
        for type in rejected {
            var gate = TrackpadPressGate()
            expect(!gate.accept(type: type, at: 10), "rejects \(type)")
        }
    }

    private static func collapsesClusteredButtonEvents() {
        var gate = TrackpadPressGate()
        expect(gate.accept(type: .leftMouseDown, at: 10), "accepts the first press")
        expect(
            !gate.accept(type: .rightMouseDown, at: 10.05),
            "collapses simultaneous mouse-button events into one surprise"
        )
    }

    private static func acceptsLaterPresses() {
        var gate = TrackpadPressGate()
        expect(gate.accept(type: .leftMouseDown, at: 10), "accepts the first timed press")
        expect(gate.accept(type: .leftMouseDown, at: 10.19), "accepts a later intentional press")
    }
}
