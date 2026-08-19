import AppKit
import SwiftUI

final class OverlayPanel {
    private var window: OverlayWindow?
    private var host: NSHostingController<PressOverlayView>?
    private var rootView: OverlayRootView?
    private var screenObserver: NSObjectProtocol?
    private var cursorHidden = false

    func show(session: AppSession) {
        let window = preparedWindow(session: session)
        layout(window)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(rootView)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.window?.makeFirstResponder(self.rootView)
        }
        hideCursor()
        observeScreens()
    }

    func hide() {
        window?.orderOut(nil)
        showCursor()
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
            self.screenObserver = nil
        }
    }

    private func preparedWindow(session: AppSession) -> OverlayWindow {
        if let window {
            return window
        }

        let root = OverlayRootView(frame: .zero)

        let host = NSHostingController(
            rootView: PressOverlayView(session: session, playground: session.playground)
        )
        host.view.wantsLayer = true
        host.view.layer?.backgroundColor = NSColor.clear.cgColor
        host.view.allowedTouchTypes = []
        host.view.autoresizingMask = [.width, .height]

        let window = OverlayWindow(
            contentRect: .zero,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.contentView = root
        host.view.frame = root.bounds
        root.addSubview(host.view)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = true
        window.hidesOnDeactivate = false
        window.isReleasedWhenClosed = false
        window.initialFirstResponder = root
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.assistiveTechHighWindow)))
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        window.title = "Mr.Blobsky Overlay"
        self.rootView = root
        self.host = host
        self.window = window
        return window
    }

    private func hideCursor() {
        guard !cursorHidden else { return }
        NSCursor.hide()
        cursorHidden = true
    }

    private func showCursor() {
        guard cursorHidden else { return }
        NSCursor.unhide()
        cursorHidden = false
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

private final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

private final class OverlayRootView: NSView {
    override var acceptsFirstResponder: Bool { true }
}
