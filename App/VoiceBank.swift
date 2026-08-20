import AVFoundation
import Foundation

@MainActor
final class VoiceBank: ObservableObject {
    static let shared = VoiceBank()
    static let rootMidi = 60
    static let maxSeconds = 2.5

    @Published private(set) var hasSample = false
    @Published var usesVoice: Bool {
        didSet { userDefaults.set(usesVoice, forKey: Self.usesVoiceKey) }
    }

    var shouldPlayVoice: Bool { usesVoice && hasSample }

    private static let usesVoiceKey = "Lapki.usesVoice"
    private static let legacyUsesVoiceKeys = [
        "MrBlobsky.usesVoice",
        "ToddlerKeys.usesVoice"
    ]
    private let recordingURL: URL
    private let userDefaults: UserDefaults
    private let migratesLegacyRecording: Bool
    private var samples: [Float] = []
    private var generation = 0
    private var cache: [CacheKey: AVAudioPCMBuffer] = [:]

    private convenience init() {
        self.init(
            recordingURL: Self.fileURL,
            userDefaults: .standard,
            migratesLegacyRecording: true
        )
    }

    init(recordingURL: URL, userDefaults: UserDefaults, migratesLegacyRecording: Bool = false) {
        self.recordingURL = recordingURL
        self.userDefaults = userDefaults
        self.migratesLegacyRecording = migratesLegacyRecording
        if userDefaults.object(forKey: Self.usesVoiceKey) == nil,
           let legacyKey = Self.legacyUsesVoiceKeys.first(where: { userDefaults.object(forKey: $0) != nil })
        {
            usesVoice = userDefaults.bool(forKey: legacyKey)
        } else {
            usesVoice = userDefaults.bool(forKey: Self.usesVoiceKey)
        }
        loadFromDisk()
    }

    func loadFromDisk() {
        if migratesLegacyRecording {
            Self.migrateLegacyRecordingIfNeeded()
        }
        guard FileManager.default.fileExists(atPath: recordingURL.path) else {
            samples = []
            hasSample = false
            cache.removeAll()
            return
        }
        do {
            let loaded = try Self.readMono44100(url: recordingURL)
            installInMemory(Self.prepare(loaded), persist: false)
        } catch {
            samples = []
            hasSample = false
            cache.removeAll()
        }
    }

    func install(_ raw: [Float]) {
        installInMemory(Self.prepare(raw), persist: true)
        usesVoice = hasSample
    }

    func clear() {
        samples = []
        hasSample = false
        usesVoice = false
        generation += 1
        cache.removeAll()
        try? FileManager.default.removeItem(at: recordingURL)
    }

    func previewBuffer(from raw: [Float]? = nil) -> AVAudioPCMBuffer {
        let source = raw.map(Self.prepare) ?? samples
        return render(source, recipe: Recipe(rate: 1, length: 1, gain: 0.95), capSeconds: Self.maxSeconds)
    }

    func buffer(for sound: MappedSound) -> AVAudioPCMBuffer {
        let key: CacheKey
        switch sound {
        case .note(let midi, _): key = .note(midi)
        case .effect(let kind): key = .effect(kind)
        }
        if let cached = cache[key] { return cached }

        let rendered: AVAudioPCMBuffer
        switch sound {
        case .note(let midi, _):
            rendered = render(samples, recipe: Self.noteRecipe(midi: midi))
        case .effect(let kind):
            rendered = render(samples, recipe: Self.effectRecipe(kind))
        }
        cache[key] = rendered
        return rendered
    }

    private func installInMemory(_ prepared: [Float], persist: Bool) {
        samples = prepared
        hasSample = prepared.count > Int(0.04 * Synth.sampleRate)
        generation += 1
        cache.removeAll()
        if persist, hasSample {
            try? Self.writeMono44100(samples, url: recordingURL)
        }
        if !hasSample {
            usesVoice = false
        }
    }

    private func render(_ source: [Float], recipe: Recipe, capSeconds: Double = 1.85) -> AVAudioPCMBuffer {
        let primary = bake(source, recipe: recipe, capSeconds: capSeconds)
        var mix = primary
        if let layerRate = recipe.layerRate {
            let layered = bake(
                source,
                recipe: Recipe(
                    rate: layerRate,
                    reverse: recipe.reverse,
                    start: recipe.start,
                    length: min(recipe.length, 0.7),
                    gain: recipe.layerGain
                ),
                capSeconds: capSeconds
            )
            if layered.count > mix.count {
                mix.append(contentsOf: repeatElement(0, count: layered.count - mix.count))
            }
            for i in 0..<layered.count {
                mix[i] += layered[i]
            }
        }

        let frames = max(1, mix.count)
        let format = AVAudioFormat(standardFormatWithSampleRate: Synth.sampleRate, channels: 2)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frames))!
        buffer.frameLength = AVAudioFrameCount(frames)
        let left = buffer.floatChannelData![0]
        let right = buffer.floatChannelData![1]
        for i in 0..<frames {
            let sample = tanh(mix[i])
            left[i] = sample
            right[i] = sample
        }
        return buffer
    }

    private func bake(_ source: [Float], recipe: Recipe, capSeconds: Double) -> [Float] {
        guard !source.isEmpty else { return [0] }
        let count = source.count
        let start = min(0.92, max(0, recipe.start))
        let length = min(1, max(0.05, recipe.length))
        let startIdx = Int(Double(count) * start)
        let span = max(8, Int(Double(count) * length))
        let endIdx = min(count, startIdx + span)
        var slice = Array(source[startIdx..<endIdx])
        if recipe.reverse { slice.reverse() }

        let rate = min(3.6, max(0.38, recipe.rate))
        let maxFrames = max(32, Int(Synth.sampleRate * capSeconds))
        var wave = Self.resample(slice, rate: rate, maxFrames: maxFrames)
        if recipe.repeats > 1 {
            let gap = [Float](repeating: 0, count: max(0, Int(recipe.gap * Synth.sampleRate)))
            var tiled: [Float] = []
            tiled.reserveCapacity(min(maxFrames, (wave.count + gap.count) * recipe.repeats))
            for i in 0..<recipe.repeats {
                if i > 0 { tiled.append(contentsOf: gap) }
                tiled.append(contentsOf: wave)
                if tiled.count >= maxFrames { break }
            }
            if tiled.count > maxFrames {
                tiled = Array(tiled.prefix(maxFrames))
            }
            wave = tiled
        }

        Self.fade(&wave, attack: 0.004, release: 0.012)
        if recipe.gain != 1 {
            for i in 0..<wave.count {
                wave[i] *= recipe.gain
            }
        }
        return wave
    }

    private static func noteRecipe(midi: Int) -> Recipe {
        let raw = midi - rootMidi
        let semitones = min(19, max(-12, raw))
        let extra = max(0, raw - 19)
        return Recipe(
            rate: pow(2.0, Double(semitones) / 12.0),
            start: min(0.4, Double(extra) * 0.035),
            length: extra > 0 ? 0.42 : 1,
            gain: 0.94
        )
    }

    private static func effectRecipe(_ kind: EffectKind) -> Recipe {
        switch kind {
        case .boing:
            return Recipe(rate: 0.74, length: 0.8, repeats: 2, gap: 0.045, layerRate: 1.42)
        case .laser:
            return Recipe(rate: 1.7, reverse: true, length: 0.85)
        case .duck:
            return Recipe(rate: 1.18, start: 0.04, length: 0.38, repeats: 2, gap: 0.07)
        case .siren:
            return Recipe(rate: 0.78, length: 1, layerRate: 1.12)
        case .splash:
            return Recipe(rate: 0.92, reverse: true)
        case .zap:
            return Recipe(rate: 2.15, start: 0.02, length: 0.22)
        case .pop:
            return Recipe(rate: 1.35, length: 0.12, gain: 1.0)
        case .whistle:
            return Recipe(rate: 2.0, start: 0.1, length: 0.55)
        case .kick:
            return Recipe(rate: 0.5, length: 0.7, gain: 1.0)
        case .crash:
            return Recipe(rate: 0.86, reverse: true, gain: 0.88)
        case .slideUp:
            return Recipe(rate: 1.26, start: 0.05, length: 0.7)
        case .slideDown:
            return Recipe(rate: 0.68, start: 0.08, length: 0.75)
        case .slideLeft:
            return Recipe(rate: 0.8, reverse: true, length: 0.65)
        case .slideRight:
            return Recipe(rate: 1.38, length: 0.65)
        case .fanfare:
            return Recipe(rate: 1.0, length: 0.55, repeats: 2, gap: 0.08, layerRate: 1.26)
        case .rewind:
            return Recipe(rate: 1.45, reverse: true)
        case .chord:
            return Recipe(rate: 1.0, layerRate: 1.5, layerGain: 0.62)
        case .sparkle:
            return Recipe(rate: 2.4, start: 0.15, length: 0.28)
        case .thump:
            return Recipe(rate: 0.62, length: 0.2, gain: 1.0)
        case .giggle:
            return Recipe(rate: 1.55, start: 0.08, length: 0.28, repeats: 2, gap: 0.05)
        case .magic:
            return Recipe(rate: 1.8, reverse: true, start: 0.1, length: 0.6, layerRate: 2.3)
        case .spark:
            return Recipe(rate: 1.9, length: 0.18)
        case .wow:
            return Recipe(rate: 1.08, length: 0.9)
        case .click:
            return Recipe(rate: 1.6, length: 0.07, gain: 1.0)
        case .drip:
            return Recipe(rate: 1.85, start: 0.2, length: 0.16)
        case .bell:
            return Recipe(rate: 1.5, start: 0.05, length: 0.55)
        case .robot:
            return Recipe(rate: 0.56, length: 0.7, gain: 0.9)
        case .honk:
            return Recipe(rate: 0.72, length: 0.5)
        case .meow:
            return Recipe(rate: 1.28, start: 0.12, length: 0.55)
        case .cluck:
            return Recipe(rate: 1.42, length: 0.12, repeats: 2, gap: 0.04)
        case .coin:
            return Recipe(rate: 2.1, start: 0.05, length: 0.16, repeats: 2, gap: 0.05, layerRate: 2.6)
        case .spring:
            return Recipe(rate: 0.7, reverse: true, repeats: 2, gap: 0.03)
        case .wah:
            return Recipe(rate: 0.9, start: 0.08, length: 0.7, layerRate: 1.2)
        case .glass:
            return Recipe(rate: 2.2, start: 0.18, length: 0.4)
        case .ping:
            return Recipe(rate: 2.0, start: 0.25, length: 0.2)
        }
    }

    private static func prepare(_ raw: [Float]) -> [Float] {
        guard !raw.isEmpty else { return [] }
        let trimmed = trim(raw)
        var samples = trimmed.isEmpty ? raw : trimmed
        let cap = Int(maxSeconds * Synth.sampleRate)
        if samples.count > cap {
            samples = Array(samples.prefix(cap))
        }
        var peak: Float = 0
        for sample in samples {
            peak = max(peak, abs(sample))
        }
        if peak > 0.004 {
            let scale = 0.94 / peak
            for i in 0..<samples.count {
                samples[i] *= scale
            }
        }
        fade(&samples, attack: 0.006, release: 0.02)
        return samples
    }

    private static func trim(_ raw: [Float]) -> [Float] {
        let threshold: Float = 0.02
        var start = 0
        var end = raw.count - 1
        while start < raw.count, abs(raw[start]) < threshold { start += 1 }
        while end > start, abs(raw[end]) < threshold { end -= 1 }
        guard end > start else { return raw }
        let pad = Int(0.018 * Synth.sampleRate)
        start = max(0, start - pad)
        end = min(raw.count - 1, end + pad)
        if end - start < Int(0.05 * Synth.sampleRate) { return raw }
        return Array(raw[start...end])
    }

    private static func resample(_ source: [Float], rate: Double, maxFrames: Int) -> [Float] {
        let n = source.count
        guard n > 1, rate > 0.001 else {
            return Array(source.prefix(maxFrames))
        }
        let outCount = min(maxFrames, max(1, Int((Double(n) / rate).rounded(.toNearestOrAwayFromZero))))
        var out = [Float](repeating: 0, count: outCount)
        for i in 0..<outCount {
            let pos = Double(i) * rate
            let i0 = Int(pos)
            let frac = Float(pos - Double(i0))
            let s0 = source[min(i0, n - 1)]
            let s1 = source[min(i0 + 1, n - 1)]
            out[i] = s0 + (s1 - s0) * frac
        }
        return out
    }

    private static func fade(_ samples: inout [Float], attack: Double, release: Double) {
        let n = samples.count
        guard n > 8 else { return }
        let a = max(1, Int(attack * Synth.sampleRate))
        let r = max(1, Int(release * Synth.sampleRate))
        for i in 0..<min(a, n) {
            samples[i] *= Float(i) / Float(a)
        }
        for i in 0..<min(r, n) {
            samples[n - 1 - i] *= Float(i) / Float(r)
        }
    }

    static var fileURL: URL {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return root.appendingPathComponent("Lapki/voice.wav")
    }

    private static var legacyFileURLs: [URL] {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return [
            root.appendingPathComponent("MrBlobsky/voice.wav"),
            root.appendingPathComponent("ToddlerKeys/voice.wav")
        ]
    }

    private static func migrateLegacyRecordingIfNeeded() {
        let dest = fileURL
        let files = FileManager.default
        guard !files.fileExists(atPath: dest.path) else { return }
        guard let legacy = legacyFileURLs.first(where: { files.fileExists(atPath: $0.path) }) else { return }
        try? files.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? files.copyItem(at: legacy, to: dest)
    }

    static func readMono44100(url: URL) throws -> [Float] {
        let file = try AVAudioFile(forReading: url)
        let format = file.processingFormat
        let frames = AVAudioFrameCount(file.length)
        guard frames > 0, let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else {
            return []
        }
        try file.read(into: buffer)
        return mono44100(from: buffer)
    }

    static func writeMono44100(_ samples: [Float], url: URL) throws {
        let folder = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
        let format = AVAudioFormat(standardFormatWithSampleRate: Synth.sampleRate, channels: 1)!
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)) else {
            return
        }
        buffer.frameLength = AVAudioFrameCount(samples.count)
        samples.withUnsafeBufferPointer { src in
            if let base = src.baseAddress {
                buffer.floatChannelData![0].update(from: base, count: samples.count)
            }
        }
        let file = try AVAudioFile(forWriting: url, settings: format.settings)
        try file.write(from: buffer)
    }

    static func mono44100(from buffer: AVAudioPCMBuffer) -> [Float] {
        let srcFormat = buffer.format
        let dstFormat = AVAudioFormat(standardFormatWithSampleRate: Synth.sampleRate, channels: 1)!
        if srcFormat.channelCount == 1,
           srcFormat.sampleRate == Synth.sampleRate,
           srcFormat.commonFormat == .pcmFormatFloat32,
           let data = buffer.floatChannelData
        {
            return Array(UnsafeBufferPointer(start: data[0], count: Int(buffer.frameLength)))
        }

        guard let converter = AVAudioConverter(from: srcFormat, to: dstFormat) else {
            return []
        }
        let ratio = Synth.sampleRate / srcFormat.sampleRate
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 64
        guard let out = AVAudioPCMBuffer(pcmFormat: dstFormat, frameCapacity: capacity) else {
            return []
        }
        var error: NSError?
        var supplied = false
        converter.convert(to: out, error: &error) { _, status in
            if supplied {
                status.pointee = .endOfStream
                return nil
            }
            supplied = true
            status.pointee = .haveData
            return buffer
        }
        guard let data = out.floatChannelData else { return [] }
        return Array(UnsafeBufferPointer(start: data[0], count: Int(out.frameLength)))
    }

    private enum CacheKey: Hashable {
        case note(Int)
        case effect(EffectKind)
    }

    private struct Recipe {
        var rate: Double = 1
        var reverse: Bool = false
        var start: Double = 0
        var length: Double = 1
        var gain: Float = 0.92
        var repeats: Int = 1
        var gap: Double = 0
        var layerRate: Double?
        var layerGain: Float = 0.55
    }
}
