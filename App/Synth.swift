import AVFoundation
import Foundation

enum Synth {
    static let sampleRate: Double = 44_100

    static func buffer(for sound: MappedSound) -> AVAudioPCMBuffer {
        switch sound {
        case .note(let midi, _):
            return pluck(midi: midi, seconds: 0.72)
        case .effect(let kind):
            return effect(kind)
        }
    }

    private static func effect(_ kind: EffectKind) -> AVAudioPCMBuffer {
        switch kind {
        case .boing: return sweep(start: 720, end: 110, seconds: 0.38, bounce: true)
        case .laser: return sweep(start: 1700, end: 140, seconds: 0.28, harmonics: 5)
        case .duck: return duck()
        case .siren: return siren()
        case .splash: return noiseBurst(seconds: 0.42, startCutoff: 2800, endCutoff: 280, bright: false)
        case .zap: return zap()
        case .pop: return pop()
        case .whistle: return whistle()
        case .kick: return kick()
        case .crash: return noiseBurst(seconds: 0.7, startCutoff: 6000, endCutoff: 1200, bright: true)
        case .slideUp: return sweep(start: 380, end: 980, seconds: 0.34)
        case .slideDown: return sweep(start: 980, end: 320, seconds: 0.34)
        case .slideLeft: return sweep(start: 640, end: 360, seconds: 0.3)
        case .slideRight: return sweep(start: 640, end: 1100, seconds: 0.3)
        case .fanfare: return fanfare()
        case .rewind: return rewind()
        case .chord: return chord()
        }
    }

    private static func pluck(midi: Int, seconds: Double, start: Double = 0, gain: Double = 0.28) -> AVAudioPCMBuffer {
        let (buffer, left, right, frames) = allocate(seconds: seconds)
        addPluck(midi: midi, start: start, duration: seconds, gain: gain, left: left, right: right, frames: frames)
        return buffer
    }

    private static func addPluck(
        midi: Int,
        start: Double,
        duration: Double,
        gain: Double,
        left: UnsafeMutablePointer<Float>,
        right: UnsafeMutablePointer<Float>,
        frames: Int
    ) {
        let freq = midiToHz(midi)
        let startFrame = Int(start * sampleRate)
        let length = Int(duration * sampleRate)
        var phase = 0.0
        var clickNoise = Noise(seed: UInt32(midi &* 7919 + 17))
        let pan = (Double(midi % 12) / 11.0) * 0.45 - 0.225
        let leftGain = (1 - max(0, pan)) * gain
        let rightGain = (1 - max(0, -pan)) * gain

        for i in 0..<length {
            let frame = startFrame + i
            guard frame >= 0, frame < frames else { continue }
            let t = Double(i) / sampleRate
            let env = attackDecay(t, attack: 0.007, decay: 0.24)
            phase += (2 * .pi * freq) / sampleRate
            if phase > 2 * .pi { phase -= 2 * .pi * floor(phase / (2 * .pi)) }

            let tone =
                sin(phase)
                + 0.42 * sin(2 * phase)
                + 0.18 * sin(3 * phase)
                + 0.08 * sin(4 * phase)
            let click = i < Int(0.01 * sampleRate) ? Double(clickNoise.next()) * 0.18 * (1 - t / 0.01) : 0
            let sample = Float((tone * env + click) )
            left[frame] += sample * Float(leftGain)
            right[frame] += sample * Float(rightGain)
        }
    }

    private static func sweep(
        start: Double,
        end: Double,
        seconds: Double,
        bounce: Bool = false,
        harmonics: Int = 1
    ) -> AVAudioPCMBuffer {
        render(seconds: seconds) { t, phase in
            let progress = t / seconds
            let freq = start * pow(end / start, progress)
            let env = attackDecay(t, attack: 0.008, decay: seconds * 0.55)
            let am = bounce ? (0.55 + 0.45 * abs(sin(2 * .pi * 7 * t))) : 1
            var sample = 0.0
            for h in 1...harmonics {
                sample += sin(phase * Double(h)) / Double(h)
            }
            return sample * env * am * 0.32
        } advance: { t in
            let progress = t / seconds
            return start * pow(end / start, progress)
        }
    }

    private static func duck() -> AVAudioPCMBuffer {
        render(seconds: 0.4) { t, phase in
            let quack: Double
            if t < 0.16 {
                quack = attackDecay(t, attack: 0.012, decay: 0.07)
            } else if t > 0.18 {
                quack = attackDecay(t - 0.18, attack: 0.01, decay: 0.08)
            } else {
                quack = 0
            }
            let vibrato = 1 + 0.06 * sin(2 * .pi * 11 * t)
            let tone = sin(phase) + sin(3 * phase) / 3 + sin(5 * phase) / 6
            return tone * quack * vibrato * 0.28
        } advance: { t in
            300 + 35 * sin(2 * .pi * 8 * t)
        }
    }

    private static func siren() -> AVAudioPCMBuffer {
        render(seconds: 0.9) { t, phase in
            let env = attackSustainRelease(t, attack: 0.04, release: 0.16, total: 0.9)
            return sin(phase) * env * 0.26
        } advance: { t in
            620 + 260 * sin(2 * .pi * 2.4 * t)
        }
    }

    private static func whistle() -> AVAudioPCMBuffer {
        render(seconds: 0.52) { t, phase in
            let env = attackDecay(t, attack: 0.05, decay: 0.28)
            return sin(phase) * env * 0.24
        } advance: { t in
            880 + 720 * (t / 0.52) + 14 * sin(2 * .pi * 8 * t)
        }
    }

    private static func pop() -> AVAudioPCMBuffer {
        render(seconds: 0.09) { t, phase in
            let env = exp(-t / 0.025)
            return sin(phase) * env * 0.36
        } advance: { _ in
            190
        }
    }

    private static func kick() -> AVAudioPCMBuffer {
        var noise = Noise(seed: 0xB00B)
        return render(seconds: 0.3) { t, phase in
            let env = exp(-t / 0.09)
            let click = t < 0.01 ? Double(noise.next()) * (1 - t / 0.01) * 0.22 : 0
            return (sin(phase) * env + click) * 0.42
        } advance: { t in
            150 * exp(-18 * t) + 38
        }
    }

    private static func zap() -> AVAudioPCMBuffer {
        var noise = Noise(seed: 0x5A5A)
        return render(seconds: 0.2) { t, phase in
            let env = exp(-t / 0.06)
            let hiss = t < 0.035 ? Double(noise.next()) * (1 - t / 0.035) * 0.35 : 0
            return (sin(phase) * env + hiss) * 0.3
        } advance: { t in
            980 * exp(-16 * t) + 70
        }
    }

    private static func rewind() -> AVAudioPCMBuffer {
        render(seconds: 0.34) { t, phase in
            let env = attackDecay(t, attack: 0.01, decay: 0.2)
            let stutter = (t * 28).truncatingRemainder(dividingBy: 1) < 0.62 ? 1.0 : 0.15
            let tone = sin(phase) + sin(2 * phase) / 2
            return tone * env * stutter * 0.26
        } advance: { t in
            1400 * pow(0.18, t / 0.34)
        }
    }

    private static func noiseBurst(seconds: Double, startCutoff: Double, endCutoff: Double, bright: Bool) -> AVAudioPCMBuffer {
        var noise = Noise(seed: bright ? 0xC0FFEE : 0x51A51)
        var low = 0.0
        return render(seconds: seconds) { t, _ in
            let cutoff = startCutoff * pow(endCutoff / startCutoff, t / seconds)
            let coeff = min(0.99, cutoff / (cutoff + sampleRate / (2 * .pi)))
            let white = Double(noise.next())
            low += coeff * (white - low)
            let raw = bright ? (white - low) : low
            let env = attackDecay(t, attack: 0.006, decay: seconds * 0.45)
            return raw * env * (bright ? 0.28 : 0.34)
        } advance: { _ in
            0
        }
    }

    private static func fanfare() -> AVAudioPCMBuffer {
        let seconds = 0.62
        let (buffer, left, right, frames) = allocate(seconds: seconds)
        let notes = [(72, 0.00), (76, 0.11), (79, 0.22), (84, 0.34)]
        for (midi, start) in notes {
            addPluck(midi: midi, start: start, duration: 0.38, gain: 0.2, left: left, right: right, frames: frames)
        }
        saturate(left, right, frames: frames)
        return buffer
    }

    private static func chord() -> AVAudioPCMBuffer {
        let seconds = 0.7
        let (buffer, left, right, frames) = allocate(seconds: seconds)
        for midi in [60, 64, 67, 72] {
            addPluck(midi: midi, start: 0, duration: seconds, gain: 0.16, left: left, right: right, frames: frames)
        }
        saturate(left, right, frames: frames)
        return buffer
    }

    private static func render(
        seconds: Double,
        sample: (_ t: Double, _ phase: Double) -> Double,
        advance: (_ t: Double) -> Double
    ) -> AVAudioPCMBuffer {
        let (buffer, left, right, frames) = allocate(seconds: seconds)
        var phase = 0.0
        for i in 0..<frames {
            let t = Double(i) / sampleRate
            let freq = advance(t)
            phase += (2 * .pi * freq) / sampleRate
            if phase > 2 * .pi { phase -= 2 * .pi * floor(phase / (2 * .pi)) }
            let value = Float(tanh(sample(t, phase)))
            left[i] = value
            right[i] = value
        }
        return buffer
    }

    private static func allocate(seconds: Double) -> (AVAudioPCMBuffer, UnsafeMutablePointer<Float>, UnsafeMutablePointer<Float>, Int) {
        let frames = max(1, Int(sampleRate * seconds))
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frames))!
        buffer.frameLength = AVAudioFrameCount(frames)
        let channels = buffer.floatChannelData!
        memset(channels[0], 0, frames * MemoryLayout<Float>.size)
        memset(channels[1], 0, frames * MemoryLayout<Float>.size)
        return (buffer, channels[0], channels[1], frames)
    }

    private static func saturate(_ left: UnsafeMutablePointer<Float>, _ right: UnsafeMutablePointer<Float>, frames: Int) {
        for i in 0..<frames {
            left[i] = tanh(left[i])
            right[i] = tanh(right[i])
        }
    }

    private static func attackDecay(_ t: Double, attack: Double, decay: Double) -> Double {
        if t < 0 { return 0 }
        if t < attack { return t / attack }
        return exp(-(t - attack) / decay)
    }

    private static func attackSustainRelease(_ t: Double, attack: Double, release: Double, total: Double) -> Double {
        if t < 0 { return 0 }
        if t < attack { return t / attack }
        let releaseStart = max(attack, total - release)
        if t < releaseStart { return 1 }
        return max(0, 1 - (t - releaseStart) / release)
    }

    private static func midiToHz(_ midi: Int) -> Double {
        440 * pow(2.0, Double(midi - 69) / 12.0)
    }
}

private struct Noise {
    var state: UInt32

    init(seed: UInt32) {
        state = seed == 0 ? 1 : seed
    }

    mutating func next() -> Float {
        state = state &* 1_664_525 &+ 1_013_904_223
        let signed = Int32(bitPattern: state)
        return Float(signed) / Float(Int32.max)
    }
}
