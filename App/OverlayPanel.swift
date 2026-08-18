import AppKit
import SwiftUI

final class OverlayPanel {
    private var window: NSWindow?
    private var screenObserver: NSObjectProtocol?

    func show(session: AppSession) {
        let window = preparedWindow(session: session)
        layout(window)
        window.orderFrontRegardless()
        observeScreens()
    }

    func hide() {
        window?.orderOut(nil)
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
            self.screenObserver = nil
        }
    }

    private func preparedWindow(session: AppSession) -> NSWindow {
        if let window {
            return window
        }

        let host = NSHostingController(
            rootView: PressOverlayView(session: session, playground: session.playground)
        )
        host.view.wantsLayer = true
        host.view.layer?.backgroundColor = NSColor.clear.cgColor

        let window = NSWindow(contentViewController: host)
        window.styleMask = [.borderless, .fullSizeContentView]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.hidesOnDeactivate = false
        window.isReleasedWhenClosed = false
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.assistiveTechHighWindow)))
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        window.title = "Mr.Blobsky Overlay"
        self.window = window
        return window
    }

    private func layout(_ window: NSWindow) {
        let frame = NSScreen.screens.reduce(CGRect.null) { $0.union($1.frame) }
        if !frame.isNull, !frame.isInfinite {
            window.setFrame(frame, display: true)
        } else if let screen = NSScreen.main {
            window.setFrame(screen.visibleFrame, display: true)
        }
    }

    private func observeScreens() {
        guard screenObserver == nil else { return }
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self, let window = self.window else { return }
            self.layout(window)
        }
    }
}
