import CoreGraphics
import Foundation
import os

struct LockedKeyStroke {
    let type: CGEventType
    let keyCode: UInt16
    let flags: CGEventFlags
    let isRepeat: Bool
    var mediaCode: Int? = nil
}

final class KeyboardLocker: @unchecked Sendable {
    var onUnlock: (() -> Void)?
    var onHotKey: ((GlobalHotKeyAction) -> Void)?
    var onStroke: ((LockedKeyStroke) -> Void)?
    var onTrackpadPress: (() -> Void)?

    private let log = Logger(subsystem: "com.yaosamo.mrblobsky", category: "lock")
    private let stateLock = NSLock()
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private var trackpadPressGate = TrackpadPressGate()

    private(set) var lastError: String?

    var isRunning: Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return tap != nil
    }

    func start() -> Bool {
        stop()
        lastError = nil

        let eventTypes: [CGEventType] = [
            .keyDown, .keyUp, .flagsChanged, MediaKey.systemDefinedType,
            .leftMouseDown, .leftMouseUp, .leftMouseDragged,
            .rightMouseDown, .rightMouseUp, .rightMouseDragged,
            .otherMouseDown, .otherMouseUp, .otherMouseDragged,
            .scrollWheel
        ]
        let mask = eventTypes.reduce(CGEventMask(0)) { mask, type in
            mask | (CGEventMask(1) << type.rawValue)
        }

        let locations: [CGEventTapLocation] = [.cghidEventTap, .cgSessionEventTap]
        var created: CFMachPort?
        for location in locations {
            created = CGEvent.tapCreate(
                tap: location,
                place: .headInsertEventTap,
                options: .defaultTap,
                eventsOfInterest: CGEventMask(mask),
                callback: keyboardLockCallback,
                userInfo: Unmanaged.passUnretained(self).toOpaque()
            )
            if created != nil {
                log.info("Event tap created at \(String(describing: location), privacy: .public)")
                break
            }
        }

        guard let tap = created else {
            lastError = "tapCreate returned nil (Accessibility / Input Monitoring)"
            log.error("\(self.lastError ?? "tap failed", privacy: .public)")
            return false
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        stateLock.lock()
        self.tap = tap
        self.source = source
        stateLock.unlock()
        return true
    }

    func stop() {
        stateLock.lock()
        let tap = self.tap
        let source = self.source
        self.tap = nil
        self.source = nil
        trackpadPressGate = TrackpadPressGate()
        stateLock.unlock()

        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
    }

    fileprivate func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            log.error("Event tap disabled (\(String(describing: type), privacy: .public)); re-enabling")
            reenable()
            return nil
        }

        if type == MediaKey.systemDefinedType || type.rawValue == 14 {
            if let press = MediaKey.press(from: event), press.isDown, !press.isRepeat {
                let stroke = LockedKeyStroke(
                    type: type,
                    keyCode: 0,
                    flags: event.flags,
                    isRepeat: false,
                    mediaCode: press.code
                )
                DispatchQueue.main.async { [weak self] in
                    self?.onStroke?(stroke)
                }
            }
            return nil
        }

        if type == .keyDown,
           let action = GlobalHotKeys.action(
            keyCode: event.getIntegerValueField(.keyboardEventKeycode),
            flags: event.flags
           ) {
            DispatchQueue.main.async { [weak self] in
                if action == .toggleLock {
                    self?.onUnlock?()
                } else {
                    self?.onHotKey?(action)
                }
            }
            return nil
        }

        if type == .keyDown || type == .flagsChanged {
            let stroke = LockedKeyStroke(
                type: type,
                keyCode: UInt16(truncatingIfNeeded: event.getIntegerValueField(.keyboardEventKeycode)),
                flags: event.flags,
                isRepeat: event.getIntegerValueField(.keyboardEventAutorepeat) != 0
            )
            DispatchQueue.main.async { [weak self] in
                self?.onStroke?(stroke)
            }
        }

        stateLock.lock()
        let acceptedTrackpadPress = trackpadPressGate.accept(
            type: type,
            at: ProcessInfo.processInfo.systemUptime
        )
        stateLock.unlock()
        if acceptedTrackpadPress {
            DispatchQueue.main.async { [weak self] in
                self?.onTrackpadPress?()
            }
        }

        return nil
    }

    private func reenable() {
        stateLock.lock()
        let tap = self.tap
        stateLock.unlock()
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
    }
}

private func keyboardLockCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon else {
        return Unmanaged.passUnretained(event)
    }
    return Unmanaged<KeyboardLocker>.fromOpaque(refcon).takeUnretainedValue().handle(type: type, event: event)
}
