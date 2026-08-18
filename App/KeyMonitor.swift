import AppKit
import SwiftUI

struct KeyMonitor: NSViewRepresentable {
    var onEvent: (NSEvent) -> NSEvent?

    func makeCoordinator() -> Coordinator {
        Coordinator(onEvent: onEvent)
    }

    func makeNSView(context: Context) -> NSView {
        let view = FocusTrapView()
        context.coordinator.install()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.onEvent = onEvent
        DispatchQueue.main.async {
            nsView.window?.makeFirstResponder(nsView)
        }
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.tearDown()
    }

    final class Coordinator {
        var onEvent: (NSEvent) -> NSEvent?
        private var monitor: Any?

        init(onEvent: @escaping (NSEvent) -> NSEvent?) {
            self.onEvent = onEvent
        }

        func install() {
            guard monitor == nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                self?.onEvent(event) ?? event
            }
        }

        func tearDown() {
            if let monitor {
                NSEvent.removeMonitor(monitor)
            }
            monitor = nil
        }
    }
}

private final class FocusTrapView: NSView {
    override var acceptsFirstResponder: Bool { true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }
}
