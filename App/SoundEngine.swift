import AVFoundation
import Foundation

@MainActor
final class SoundEngine {
    private let engine = AVAudioEngine()
    private let format = AVAudioFormat(standardFormatWithSampleRate: Synth.sampleRate, channels: 2)!
    private var players: [AVAudioPlayerNode] = []
    private var nextPlayer = 0
    private let poolSize = 32

    init() {
        engine.mainMixerNode.outputVolume = 0.8
        for _ in 0..<poolSize {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            players.append(player)
        }
        startIfNeeded()
    }

    func play(_ sound: MappedSound, instrument: Instrument = .piano) {
        startIfNeeded()
        let buffer: AVAudioPCMBuffer
        if instrument == .voice, VoiceBank.shared.hasSample {
            buffer = VoiceBank.shared.buffer(for: sound)
        } else {
            let builtIn = instrument == .voice ? Instrument.piano : instrument
            buffer = Synth.buffer(for: sound, instrument: builtIn)
        }
        playBuffer(buffer)
    }

    func playBuffer(_ buffer: AVAudioPCMBuffer) {
        startIfNeeded()
        guard engine.isRunning else { return }
        let player = players[nextPlayer]
        nextPlayer = (nextPlayer + 1) % poolSize
        if player.isPlaying {
            player.stop()
        }
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        player.play()
    }

    func playWelcome() {
        play(.effect(.chord), instrument: .piano)
    }

    private func startIfNeeded() {
        guard !engine.isRunning else { return }
        engine.prepare()
        do {
            try engine.start()
        } catch {
            return
        }
    }
}
