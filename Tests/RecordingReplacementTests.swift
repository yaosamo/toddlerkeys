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

@MainActor
private final class RecordingSpy: RecordedSoundInstalling {
    private(set) var activeSamples: [Float] = []
    private(set) var installCount = 0

    func install(_ raw: [Float]) {
        activeSamples = raw
        installCount += 1
    }
}

@main
private enum RecordingReplacementTests {
    @MainActor
    static func main() {
        let sound = RecordingSpy()
        let controller = RecorderController(soundInstaller: sound)
        let firstTake: [Float] = [0.1, 0.2]
        let secondTake: [Float] = [-0.7, 0.4, 0.8]

        controller.acceptFinishedTake(firstTake)
        controller.acceptFinishedTake(secondTake)

        expect(sound.installCount == 2, "every finished take becomes active immediately")
        expect(sound.activeSamples == secondTake, "the second take replaces the first take")

        verifiesRealSoundBankReplacement()

        guard failures == 0 else { exit(1) }
        print("Recording replacement tests passed")
    }

    @MainActor
    private static func verifiesRealSoundBankReplacement() {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("mrblobsky-recording-test-\(UUID().uuidString)")
        let recordingURL = root.appendingPathComponent("voice.wav")
        let suiteName = "MrBlobsky.RecordingReplacementTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            expect(false, "creates isolated recording preferences")
            return
        }
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: root)
        }

        let sound = VoiceBank(recordingURL: recordingURL, userDefaults: defaults)
        let controller = RecorderController(soundInstaller: sound)
        let firstTake = [Float](repeating: 0.25, count: 2_205)
        let secondTake = [Float](repeating: -0.5, count: 2_205)

        controller.acceptFinishedTake(firstTake)
        let firstBuffer = sound.buffer(for: .note(midi: VoiceBank.rootMidi, name: "C"))
        controller.acceptFinishedTake(secondTake)
        let secondBuffer = sound.buffer(for: .note(midi: VoiceBank.rootMidi, name: "C"))
        let savedSamples = try? VoiceBank.readMono44100(url: recordingURL)

        expect(firstBuffer.floatChannelData?[0][1_000] ?? 0 > 0, "the first take reaches the sound bank")
        expect(secondBuffer.floatChannelData?[0][1_000] ?? 0 < 0, "the second take clears cached notes and replaces the first")
        expect(savedSamples?[1_000] ?? 0 < 0, "the replacement take overwrites the saved recording")
    }
}
