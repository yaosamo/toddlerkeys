import AppKit
import SwiftUI

struct Burst: Identifiable, Equatable {
    let id: UUID
    let stickerName: String
    let display: String
    let color: Color
    let startX: CGFloat
    let startY: CGFloat
    let endX: CGFloat
    let endY: CGFloat
    let size: CGFloat
    let rotation: Double
    let duration: Double
}

struct TrackpadSpark: Identifiable, Equatable {
    let id: UUID
    let position: CGPoint
    let hue: Double
    let size: CGFloat
    let rotation: Double
}

@MainActor
final class Playground: ObservableObject {
    @Published var bursts: [Burst] = []
    @Published var litKeyID: String?
    @Published var hasPlayed = false
    @Published var song: NurserySong?
    @Published var songIndex = 0
    @Published var songCompleted = false
    @Published var instrument: Instrument = .piano
    @Published var bounceTick = 0
    @Published var trackpadTick = 0
    @Published var trackpadPosition = CGPoint(x: 0.5, y: 0.5)
    @Published var trackpadSparks: [TrackpadSpark] = []
    @Published var hasMovedTrackpad = false

    let sound = SoundEngine()
    private var demoTask: Task<Void, Never>?
    private var celebrateTask: Task<Void, Never>?
    private var trackpadSurpriseIndex = 0
    private var trackpadMotionIndex = 0

    private static let trackpadSurprises: [ToyKey] = [
        ToyKey(id: "trackpad-sparkle", display: "✨", caption: "Sparkle", sound: .effect(.sparkle), showsCaption: false),
        ToyKey(id: "trackpad-pop", display: "●", caption: "Pop", sound: .effect(.pop), showsCaption: false),
        ToyKey(id: "trackpad-giggle", display: "☺", caption: "Giggle", sound: .effect(.giggle), showsCaption: false),
        ToyKey(id: "trackpad-magic", display: "★", caption: "Magic", sound: .effect(.magic), showsCaption: false),
        ToyKey(id: "trackpad-wow", display: "!", caption: "Wow", sound: .effect(.wow), showsCaption: false),
        ToyKey(id: "trackpad-meow", display: "♡", caption: "Meow", sound: .effect(.meow), showsCaption: false)
    ]

    var nextKeyID: String? {
        guard let song, !songCompleted, songIndex < song.notes.count else { return nil }
        return song.notes[songIndex].keyID
    }

    func handle(event: NSEvent) -> NSEvent? {
        if event.type == .systemDefined {
            if let key = KeyMap.toyKey(from: event) {
                play(key)
            }
            return nil
        }
        let passThrough = event.type == .flagsChanged || KeyMap.shouldLetSystemHandle(event)
        if let key = KeyMap.toyKey(from: event) {
            play(key)
        }
        return passThrough ? event : nil
    }

    func play(_ key: ToyKey, countsForSong: Bool = true, burstOrigin: CGPoint? = nil) {
        sound.play(key.sound, instrument: instrument)
        litKeyID = key.id
        hasPlayed = true
        bounceTick += 1

        let burst = makeBurst(for: key, origin: burstOrigin)
        bursts.append(burst)
        if bursts.count > 28 {
            bursts.removeFirst(bursts.count - 28)
        }

        if countsForSong {
            registerSongHit(key)
        }

        let burstID = burst.id
        let keyID = key.id
        let lifetime = burst.duration + 1.35
        DispatchQueue.main.asyncAfter(deadline: .now() + lifetime) { [weak self] in
            guard let self else { return }
            self.bursts.removeAll { $0.id == burstID }
            if self.litKeyID == keyID {
                self.litKeyID = nil
            }
        }
    }

    func playTrackpad() {
        let surprises = Self.trackpadSurprises
        let surprise = surprises[trackpadSurpriseIndex % surprises.count]
        trackpadSurpriseIndex = (trackpadSurpriseIndex + 1) % surprises.count
        trackpadTick += 1
        play(surprise, countsForSong: false, burstOrigin: trackpadPosition)
    }

    func moveTrackpad(to position: CGPoint) {
        let clamped = CGPoint(
            x: min(1, max(0, position.x)),
            y: min(1, max(0, position.y))
        )
        trackpadPosition = clamped
        hasMovedTrackpad = true

        let index = trackpadMotionIndex
        trackpadMotionIndex += 1
        let spark = TrackpadSpark(
            id: UUID(),
            position: clamped,
            hue: (
                Double(clamped.x) * 0.68
                + Double(clamped.y) * 0.14
                + Double(index % 5) * 0.035
            ).truncatingRemainder(dividingBy: 1),
            size: CGFloat(19 + index % 4 * 4),
            rotation: Double(index % 12) * 29
        )
        trackpadSparks.append(spark)
        if trackpadSparks.count > 32 {
            trackpadSparks.removeFirst(trackpadSparks.count - 32)
        }

        let sparkID = spark.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.82) { [weak self] in
            self?.trackpadSparks.removeAll { $0.id == sparkID }
        }
    }

    func clearBursts() {
        bursts.removeAll()
        hasPlayed = false
        litKeyID = nil
        bounceTick = 0
        trackpadTick = 0
        trackpadSurpriseIndex = 0
        trackpadPosition = CGPoint(x: 0.5, y: 0.5)
        trackpadSparks.removeAll()
        hasMovedTrackpad = false
        trackpadMotionIndex = 0
    }

    func startSong(_ newSong: NurserySong) {
        demoTask?.cancel()
        celebrateTask?.cancel()
        song = newSong
        songIndex = 0
        songCompleted = false
    }

    func clearSong() {
        demoTask?.cancel()
        celebrateTask?.cancel()
        song = nil
        songIndex = 0
        songCompleted = false
    }

    func hearSong() {
        guard let song else { return }
        demoTask?.cancel()
        celebrateTask?.cancel()
        songCompleted = false
        songIndex = 0

        demoTask = Task { @MainActor in
            for (index, step) in song.notes.enumerated() {
                if Task.isCancelled { return }
                songIndex = index
                if let key = KeyMap.all.first(where: { $0.id == step.keyID }) {
                    play(key, countsForSong: false)
                }
                let nanoseconds = UInt64(max(0.26, step.beats * 0.4) * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanoseconds)
            }
            if !Task.isCancelled {
                songIndex = 0
            }
        }
    }

    func applyVoicePreference() {
        instrument = VoiceBank.shared.shouldPlayVoice ? .voice : .piano
    }

    func setUsesVoice(_ on: Bool) {
        VoiceBank.shared.usesVoice = on && VoiceBank.shared.hasSample
        applyVoicePreference()
    }

    func welcome() {
        sound.playWelcome()
    }

    func stopSongPlayback() {
        demoTask?.cancel()
        celebrateTask?.cancel()
    }

    private func registerSongHit(_ key: ToyKey) {
        guard let song, !songCompleted, songIndex < song.notes.count else { return }
        guard key.id == song.notes[songIndex].keyID else { return }

        songIndex += 1
        if songIndex >= song.notes.count {
            songCompleted = true
            celebrateTask?.cancel()
            celebrateTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 280_000_000)
                if Task.isCancelled { return }
                sound.play(.effect(.fanfare), instrument: instrument)
                try? await Task.sleep(nanoseconds: 1_800_000_000)
                if Task.isCancelled { return }
                songIndex = 0
                songCompleted = false
            }
        }
    }

    private func makeBurst(for key: ToyKey, origin: CGPoint? = nil) -> Burst {
        let seed = abs(key.id.hashValue)
        let originJitterX = CGFloat((seed % 11) - 5) / 140
        let originJitterY = CGFloat(((seed / 11) % 9) - 4) / 160
        let baseAngle = Double((seed % 150) + 15) * .pi / 180
        let angle = baseAngle + Double.random(in: -0.42...0.42)
        let distance = 0.28 + CGFloat(seed % 18) / 18 * 0.22 + CGFloat.random(in: -0.05...0.06)
        let baseOrigin = origin ?? CGPoint(x: 0.50, y: 0.58)
        let startX = min(
            0.94,
            max(0.06, baseOrigin.x + originJitterX + CGFloat.random(in: -0.03...0.03))
        )
        let startY = min(
            0.92,
            max(0.08, baseOrigin.y + originJitterY + CGFloat.random(in: -0.025...0.025))
        )
        return Burst(
            id: UUID(),
            stickerName: StickerBook.sticker(for: key.id),
            display: burstLabel(for: key),
            color: key.sound.color,
            startX: startX,
            startY: startY,
            endX: min(0.92, max(0.08, startX + CGFloat(cos(angle)) * distance * 1.15)),
            endY: min(0.78, max(0.08, startY - CGFloat(sin(angle)) * distance * 1.25)),
            size: CGFloat(128 + seed % 56),
            rotation: Double((seed % 21) - 10) * 3.4 + Double.random(in: -8...8),
            duration: 1.15
        )
    }

    private func burstLabel(for key: ToyKey) -> String {
        if key.display.count <= 3 { return key.display }
        return String(key.display.prefix(2)).uppercased()
    }
}
