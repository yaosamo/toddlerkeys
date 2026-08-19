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
        acceptsFirstMotionSample()
        rejectsTinyPointerJitter()
        throttlesRapidMotionEvents()
        acceptsMeaningfulLaterMotion()
        rejectsInvalidMotionCoordinates()

        guard failures == 0 else { exit(1) }
        print("Trackpad interaction tests passed")
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

    private static func acceptsFirstMotionSample() {
        var gate = TrackpadMotionGate()
        expect(
            gate.accept(position: CGPoint(x: 120, y: 80), at: 10),
            "accepts the first valid pointer position"
        )
    }

    private static func rejectsTinyPointerJitter() {
        var gate = TrackpadMotionGate()
        _ = gate.accept(position: CGPoint(x: 100, y: 100), at: 10)
        expect(
            !gate.accept(position: CGPoint(x: 105, y: 104), at: 10.1),
            "rejects motion that is too small to feel intentional"
        )
    }

    private static func throttlesRapidMotionEvents() {
        var gate = TrackpadMotionGate()
        _ = gate.accept(position: CGPoint(x: 0, y: 0), at: 10)
        expect(
            !gate.accept(position: CGPoint(x: 100, y: 0), at: 10.01),
            "rejects an event flood even after a large move"
        )
    }

    private static func acceptsMeaningfulLaterMotion() {
        var gate = TrackpadMotionGate()
        _ = gate.accept(position: CGPoint(x: 0, y: 0), at: 10)
        expect(
            gate.accept(position: CGPoint(x: 24, y: 0), at: 10.05),
            "accepts a paced move that travels far enough"
        )
    }

    private static func rejectsInvalidMotionCoordinates() {
        var gate = TrackpadMotionGate()
        expect(
            !gate.accept(position: CGPoint(x: CGFloat.nan, y: 0), at: 10),
            "rejects a non-finite horizontal coordinate"
        )
        expect(
            !gate.accept(position: CGPoint(x: 0, y: CGFloat.infinity), at: 10),
            "rejects a non-finite vertical coordinate"
        )
    }
}
