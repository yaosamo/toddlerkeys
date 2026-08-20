import AppKit
import AVFoundation
import SwiftUI

@MainActor
protocol RecordedSoundInstalling: AnyObject {
    func install(_ raw: [Float])
}

extension VoiceBank: RecordedSoundInstalling {}

@MainActor
final class RecordPanel: NSObject, NSWindowDelegate {
    static let shared = RecordPanel()

    private var window: NSWindow?
    private let controller = RecorderController()

    func show(playground: Playground) {
        controller.attach(playground: playground)
        let window = preparedWindow()
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.assistiveTechHighWindow)) + 6)
        NSApp.activate(ignoringOtherApps: true)
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    func hide() {
        controller.stopAndKeepTake()
        window?.orderOut(nil)
    }

    private func preparedWindow() -> NSWindow {
        if let window {
            return window
        }
        let host = NSHostingController(
            rootView: RecordView(controller: controller) { [weak self] in
                self?.hide()
            }
        )
        let window = NSWindow(contentViewController: host)
        window.title = "Record a Sound"
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.setContentSize(NSSize(width: 400, height: 470))
        self.window = window
        return window
    }

    func windowWillClose(_ notification: Notification) {
        controller.stopAndKeepTake()
    }
}

@MainActor
final class RecorderController: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording = false
    @Published var elapsed: Double = 0
    @Published var level: Double = 0
    @Published var hasPending = false
    @Published var permissionDenied = false
    @Published var errorMessage: String?
    @Published private(set) var pendingSamples: [Float] = []

    let limit = VoiceBank.maxSeconds

    private weak var playground: Playground?
    private let soundInstaller: any RecordedSoundInstalling
    private var recorder: AVAudioRecorder?
    private var tick: Timer?
    private var takeURL: URL?

    override convenience init() {
        self.init(soundInstaller: VoiceBank.shared)
    }

    init(soundInstaller: any RecordedSoundInstalling) {
        self.soundInstaller = soundInstaller
        super.init()
    }

    func attach(playground: Playground) {
        self.playground = playground
        errorMessage = nil
    }

    func toggleRecord() {
        if isRecording {
            stopRecorder()
        } else {
            Task { await startRecord() }
        }
    }

    func preview() {
        guard !pendingSamples.isEmpty, let playground else { return }
        playground.sound.playBuffer(VoiceBank.shared.previewBuffer(from: pendingSamples))
    }

    func forget() {
        VoiceBank.shared.clear()
        pendingSamples = []
        hasPending = false
        playground?.applyVoicePreference()
    }

    func setUsesVoice(_ on: Bool) {
        playground?.setUsesVoice(on)
    }

    func openMicrophoneSettings() {
        let candidates = [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone",
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Microphone"
        ]
        for value in candidates {
            if let url = URL(string: value), NSWorkspace.shared.open(url) {
                return
            }
        }
    }

    func stopAndKeepTake() {
        if isRecording {
            stopRecorder()
        }
        invalidateTick()
    }

    private func startRecord() async {
        errorMessage = nil
        permissionDenied = false
        let allowed = await requestMic()
        if !allowed {
            permissionDenied = true
            errorMessage = "Allow the microphone in System Settings to record a sound."
            return
        }

        stopRecorder()
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("lapki-\(UUID().uuidString).wav")
        takeURL = url
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]

        do {
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.delegate = self
            recorder.isMeteringEnabled = true
            guard recorder.prepareToRecord(), recorder.record(forDuration: limit) else {
                errorMessage = "Could not start the microphone."
                return
            }
            self.recorder = recorder
            elapsed = 0
            level = 0
            isRecording = true
            hasPending = false
            startTick()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func stopRecorder() {
        guard let recorder else {
            isRecording = false
            invalidateTick()
            return
        }
        recorder.stop()
    }

    private func startTick() {
        invalidateTick()
        tick = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.pulse()
            }
        }
        if let tick {
            RunLoop.main.add(tick, forMode: .common)
        }
    }

    private func pulse() {
        guard let recorder, recorder.isRecording else { return }
        recorder.updateMeters()
        let db = Double(recorder.averagePower(forChannel: 0))
        level = max(0, min(1, (db + 48) / 42))
        elapsed = recorder.currentTime
        if elapsed >= limit - 0.02 {
            stopRecorder()
        }
    }

    private func invalidateTick() {
        tick?.invalidate()
        tick = nil
    }

    private func finishTake(success: Bool) {
        invalidateTick()
        isRecording = false
        level = 0
        let recorder = self.recorder
        self.recorder = nil
        let url = recorder?.url ?? takeURL
        takeURL = nil

        guard success, let url else {
            if !success {
                errorMessage = "Recording did not finish."
            }
            return
        }

        do {
            let samples = try VoiceBank.readMono44100(url: url)
            try? FileManager.default.removeItem(at: url)
            if samples.isEmpty {
                errorMessage = "That take was empty. Try again a little closer to the mic."
                hasPending = false
                pendingSamples = []
                return
            }
            acceptFinishedTake(samples)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func acceptFinishedTake(_ samples: [Float]) {
        pendingSamples = samples
        hasPending = true
        elapsed = Double(samples.count) / Synth.sampleRate
        soundInstaller.install(samples)
        playground?.applyVoicePreference()
        errorMessage = nil
    }

    private func requestMic() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    continuation.resume(returning: granted)
                }
            }
        default:
            return false
        }
    }

    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            self.finishTake(success: flag)
        }
    }

    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            self.errorMessage = error?.localizedDescription ?? "Recording failed."
            self.finishTake(success: false)
        }
    }
}

private struct RecordView: View {
    @ObservedObject var controller: RecorderController
    @ObservedObject var voice = VoiceBank.shared
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Record a Sound")
                .font(.system(size: 20, weight: .bold))
            Text("Say a word, tap the table, or make a silly noise. Lapki turns that clip into every key — higher, lower, backwards, chopped.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            meter

            if let errorMessage = controller.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12))
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                Button(controller.isRecording ? "Stop" : "Record") {
                    controller.toggleRecord()
                }

                Button("Preview") {
                    controller.preview()
                }
                .disabled(!controller.hasPending || controller.isRecording)
            }

            if voice.hasSample {
                Divider()
                HStack {
                    Text(voice.usesVoice ? "Using your recording." : "Using built-in sounds.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(voice.usesVoice ? "Use Built-in" : "Use My Sound") {
                        controller.setUsesVoice(!voice.usesVoice)
                    }
                }
                Button("Forget My Sound", role: .destructive) {
                    controller.forget()
                }
            }

            Text("Each new clip replaces the last one. It stays on this Mac and is never uploaded.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            HStack {
                if controller.permissionDenied {
                    Button("Open Microphone Settings…") {
                        controller.openMicrophoneSettings()
                    }
                }
                Spacer()
                Button("Close") { onClose() }
            }
        }
        .padding(22)
        .frame(width: 400)
    }

    private var meter: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.08))
                    Capsule()
                        .fill(controller.isRecording ? Color.red.opacity(0.8) : Color.accentColor)
                        .frame(width: max(8, geo.size.width * fill))
                }
            }
            .frame(height: 10)

            HStack {
                Text(statusLine)
                Spacer()
                Text(timeLine)
            }
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(nsColor: .controlBackgroundColor)))
    }

    private var fill: CGFloat {
        if controller.isRecording {
            return CGFloat(min(1, max(controller.elapsed / controller.limit, controller.level * 0.35)))
        }
        if controller.hasPending {
            return CGFloat(min(1, controller.elapsed / controller.limit))
        }
        return 0.04
    }

    private var statusLine: String {
        if controller.isRecording { return "Listening…" }
        if controller.hasPending { return "New sound saved" }
        if voice.hasSample { return "A sound is already saved" }
        return "Ready to record"
    }

    private var timeLine: String {
        let current = min(controller.limit, controller.elapsed)
        return String(format: "%.1f / %.1fs", current, controller.limit)
    }
}
