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
    @Published private(set) var playSessionState: PlaySessionState = .unlimited
    @Published private(set) var refusalTick = 0

    var isPlaytimeOver: Bool { playSessionState == .expired }

    var playTimeStatus: String? {
        switch playSessionState {
        case .unlimited:
            return nil
        case .active(let secondsRemaining):
            let minutes = secondsRemaining / 60
            let seconds = secondsRemaining % 60
            return String(format: "Play time %d:%02d", minutes, seconds)
        case .expired:
            return "Play time over • still locked"
        }
    }

    private let locker = KeyboardLocker()
    private let hotKey = HotKeyCenter()
    private let overlay = OverlayPanel()
    private let log = Logger(subsystem: "com.yaosamo.mrblobsky", category: "session")
    private var retryTask: Task<Void, Never>?
    private var playTimerTask: Task<Void, Never>?
    private var playSessionClock = PlaySessionClock(limit: .unlimited, startedAt: 0)
    private var refusalGate = RefusalGate()
    private var lastHotKeyAt = Date.distantPast

    private init() {}

    func start() {
        locker.onUnlock = { [weak self] in
            self?.unlock()
        }
        locker.onStroke = { [weak self] stroke in
            self?.playLocked(stroke)
        }
        locker.onTrackpadPress = { [weak self] in
            self?.handleTrackpadPress()
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

    func lockAndShow() {
        lockAndShow(limit: .unlimited)
    }

    func lockForTwoMinutes() {
        lockAndShow(limit: .twoMinutes)
    }

    private func lockAndShow(limit: PlaySessionLimit) {
        refreshPermissions()
        if !AccessibilityAuth.canLockKeyboard {
            AccessibilityAuth.prompt()
            refreshPermissions()
        }

        isLocked = true
        playground.clearBursts()
        beginPlaySession(limit: limit)
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
        playTimerTask?.cancel()
        playTimerTask = nil
        playSessionClock = PlaySessionClock(limit: .unlimited, startedAt: 0)
        playSessionState = .unlimited
        refusalGate = RefusalGate()
        refusalTick = 0
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

    private func beginPlaySession(limit: PlaySessionLimit) {
        playTimerTask?.cancel()
        playTimerTask = nil
        refusalGate = RefusalGate()
        refusalTick = 0

        let now = ProcessInfo.processInfo.systemUptime
        playSessionClock = PlaySessionClock(limit: limit, startedAt: now)
        playSessionState = playSessionClock.state(at: now)
        guard limit == .twoMinutes else { return }

        playTimerTask = Task { @MainActor [weak self] in
            while let self, !Task.isCancelled, self.isLocked {
                try? await Task.sleep(nanoseconds: 250_000_000)
                if Task.isCancelled { return }
                self.refreshPlaySession()
                if self.isPlaytimeOver { return }
            }
        }
    }

    private func refreshPlaySession() {
        let nextState = playSessionClock.state(at: ProcessInfo.processInfo.systemUptime)
        guard nextState != playSessionState else { return }
        playSessionState = nextState
        guard nextState == .expired else { return }

        playground.stopSongPlayback()
        playground.clearBursts()
        refuse()
        log.info("Two-minute play session expired; input remains locked")
    }

    private func handleTrackpadPress() {
        if isPlaytimeOver {
            refuse()
        } else {
            playground.playTrackpad()
        }
    }

    private func refuse() {
        guard refusalGate.accept(at: ProcessInfo.processInfo.systemUptime) else { return }
        refusalTick += 1
        playground.refuse()
    }

    private func playLocked(_ stroke: LockedKeyStroke) {
        if isPlaytimeOver {
            if !stroke.isRepeat {
                refuse()
            }
            return
        }

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
