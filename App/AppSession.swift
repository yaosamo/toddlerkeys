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
    private let log = Logger(subsystem: "com.yaosamo.lapki", category: "session")
    private var retryTask: Task<Void, Never>?
    private var playTimerTask: Task<Void, Never>?
    private var playSessionClock = PlaySessionClock(limit: .unlimited, startedAt: 0)
    private var refusalGate = RefusalGate()
    private var lockChordEchoGate = LockChordEchoGate()

    private init() {}

    func start() {
        locker.onHotKey = { [weak self] action in
            self?.handleHotKey(action, source: .lockedEventTap)
        }
        locker.onHotKeyKeyUp = { [weak self] keyCode in
            self?.lockChordEchoGate.clearOnKeyUp(
                keyCode,
                at: ProcessInfo.processInfo.systemUptime
            )
        }
        locker.onStroke = { [weak self] stroke in
            self?.playLocked(stroke)
        }
        locker.onTrackpadPress = { [weak self] in
            self?.handleTrackpadPress()
        }
        hotKey.onPressed = { [weak self] action in
            self?.handleHotKey(action, source: .global)
        }
        hotKey.register()
        playground.applyVoicePreference()
        refreshPermissions()
        log.info("Session started. AX=\(self.accessibilityTrusted, privacy: .public) listen=\(AccessibilityAuth.canListenToKeys, privacy: .public)")
    }

    private func handleHotKey(_ action: GlobalHotKeyAction, source: HotKeySource) {
        guard HotKeySourcePolicy.accepts(
            source: source,
            isLocked: isLocked,
            isKeyboardLocked: isKeyboardLocked
        ) else { return }

        let now = ProcessInfo.processInfo.systemUptime
        // The chord that flips lock state is often delivered twice: Carbon and
        // the event tap. Ignore the echo so lock→unlock or unlock→lock from
        // one physical press cannot bounce straight back.
        guard !lockChordEchoGate.shouldIgnore(action, at: now) else { return }

        let wasLocked = isLocked
        switch action {
        case .toggleLock:
            if isLocked {
                unlock()
            } else {
                lockAndShow()
            }
        case .twoMinutePlay:
            if isLocked {
                playground.clearSong()
                beginPlaySession(limit: .twoMinutes)
            } else {
                lockForTwoMinutes()
            }
        case .playSong:
            playSong()
        case .song(let index):
            guard SongBook.all.indices.contains(index) else { return }
            followSong(SongBook.all[index])
        }

        if wasLocked != isLocked,
           let keyCode = GlobalHotKeys.descriptor(action: action)?.keyCode {
            // Keep ignoring the other source's echo until this key is released
            // (or the short safety timeout). That way lock→unlock can be a
            // quick second press instead of waiting out a long debounce.
            lockChordEchoGate.suppressEcho(of: action, keyCode: keyCode, at: now)
        }
    }

    func lockAndShow() {
        playground.clearSong()
        lockAndShow(limit: .unlimited)
    }

    func lockForTwoMinutes() {
        playground.clearSong()
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
        playground.clearSong()
        playground.clearBursts()
        updateStatus()
        log.info("Unlocked")
    }

    func followSong(_ song: NurserySong) {
        switch SongHotKeyPolicy.effect(
            isLocked: isLocked,
            selectedSongID: playground.song?.id,
            requestedSongID: song.id
        ) {
        case .unlock:
            unlock()
        case .follow:
            playground.startSong(song)
            if !isLocked {
                lockAndShow(limit: .unlimited)
            }
        }
    }

    func stopFollowingSong() {
        playground.clearSong()
    }

    func playSong() {
        if isPlaytimeOver {
            refuse()
            return
        }
        guard playground.song != nil else { return }
        if !isLocked {
            lockAndShow(limit: .unlimited)
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
