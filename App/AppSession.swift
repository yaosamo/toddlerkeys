import AppKit
import os
import SwiftUI

@MainActor
final class AppSession: ObservableObject {
    static let shared = AppSession()

    let playground = Playground()

    @Published var isLocked = false
    @Published var isKeyboardLocked = false
    @Published var accessibilityTrusted = AccessibilityAuth.isTrusted
    @Published var lockStatus = "Idle"

    private let locker = KeyboardLocker()
    private let hotKey = HotKeyCenter()
    private let overlay = OverlayPanel()
    private let log = Logger(subsystem: "com.yaosamo.mrblobsky", category: "session")
    private var retryTask: Task<Void, Never>?
    private var lastHotKeyAt = Date.distantPast

    private init() {}

    func start() {
        locker.onUnlock = { [weak self] in
            self?.unlock()
        }
        locker.onStroke = { [weak self] stroke in
            self?.playLocked(stroke)
        }
        hotKey.onPressed = { [weak self] in
            self?.handleHotKey()
        }
        hotKey.register()
        playground.applyVoicePreference()
        refreshPermissions()
        log.info("Session started. AX=\(self.accessibilityTrusted, privacy: .public) listen=\(AccessibilityAuth.canListenToKeys, privacy: .public)")
    }

    func handleHotKey() {
        let now = Date()
        guard now.timeIntervalSince(lastHotKeyAt) > 0.4 else { return }
        lastHotKeyAt = now

        if isLocked {
            // If the tap is running it already handles unlock. This path is
            // for when the tap never started.
            if !isKeyboardLocked {
                unlock()
            }
            return
        }
        lockAndShow()
    }

    func toggle() {
        if isLocked {
            unlock()
        } else {
            lockAndShow()
        }
    }

    func lockAndShow() {
        refreshPermissions()
        if !AccessibilityAuth.canLockKeyboard {
            AccessibilityAuth.prompt()
            refreshPermissions()
        }

        isLocked = true
        playground.clearBursts()
        overlay.show(session: self)
        attemptTap()
        log.info("Lock requested. tap=\(self.isKeyboardLocked, privacy: .public) status=\(self.lockStatus, privacy: .public)")

        if !isKeyboardLocked {
            retryTapWhileLocked()
        }
    }

    func unlock() {
        retryTask?.cancel()
        retryTask = nil
        locker.stop()
        isKeyboardLocked = false
        isLocked = false
        overlay.hide()
        playground.stopSongPlayback()
        playground.clearBursts()
        updateStatus()
        log.info("Unlocked")
    }

    func followSong(_ song: NurserySong) {
        playground.startSong(song)
        if !isLocked {
            lockAndShow()
        }
    }

    func stopFollowingSong() {
        playground.clearSong()
    }

    func hearSong() {
        guard playground.song != nil else { return }
        if !isLocked {
            lockAndShow()
        }
        playground.hearSong()
    }

    func quit() {
        unlock()
        NSApp.terminate(nil)
    }

    func refreshPermissions() {
        accessibilityTrusted = AccessibilityAuth.isTrusted
        updateStatus()
    }

    func requestAccessibility() {
        AccessibilityAuth.prompt()
        AccessibilityAuth.openSettings()
        refreshPermissions()
        retryLockIfNeeded()
    }

    func retryLockIfNeeded() {
        refreshPermissions()
        guard isLocked, !isKeyboardLocked else { return }
        attemptTap()
    }

    private func attemptTap() {
        isKeyboardLocked = locker.start()
        updateStatus()
    }

    private func retryTapWhileLocked() {
        retryTask?.cancel()
        retryTask = Task { @MainActor in
            for _ in 0..<24 {
                try? await Task.sleep(nanoseconds: 750_000_000)
                if Task.isCancelled || !isLocked || isKeyboardLocked { return }
                refreshPermissions()
                attemptTap()
                if isKeyboardLocked {
                    log.info("Event tap started on retry")
                    return
                }
            }
        }
    }

    private func updateStatus() {
        if !isLocked {
            lockStatus = "Idle"
        } else if isKeyboardLocked {
            lockStatus = "Keyboard locked"
        } else if !accessibilityTrusted {
            lockStatus = "Needs Accessibility"
        } else if !AccessibilityAuth.canListenToKeys {
            lockStatus = "Needs Input Monitoring"
        } else {
            lockStatus = locker.lastError ?? "Waiting for keyboard permission"
        }
    }

    private func playLocked(_ stroke: LockedKeyStroke) {
        let key: ToyKey?
        if let mediaCode = stroke.mediaCode {
            key = KeyMap.toyKey(mediaCode: mediaCode)
        } else {
            key = KeyMap.toyKey(
                keyCode: stroke.keyCode,
                type: stroke.type,
                flags: stroke.flags,
                isRepeat: stroke.isRepeat
            )
        }
        guard let key else { return }
        playground.play(key)
    }
}
