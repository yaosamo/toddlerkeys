import AppKit
import SwiftUI

struct Burst: Identifiable, Equatable {
    let id: UUID
    let display: String
    let color: Color
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
}

@MainActor
final class Playground: ObservableObject {
    @Published var bursts: [Burst] = []
    @Published var litKeyID: String?
    @Published var headline: String = "🎹"
    @Published var subtitle: String = "Mash the keys"
    @Published var hasPlayed = false

    let sound = SoundEngine()

    func handle(event: NSEvent) -> NSEvent? {
        if KeyMap.shouldLetSystemHandle(event) {
            return event
        }
        guard let key = KeyMap.toyKey(from: event) else {
            return nil
        }
        play(key)
        return nil
    }

    func play(_ key: ToyKey) {
        sound.play(key.sound)
        headline = key.display
        subtitle = key.sound.title
        litKeyID = key.id
        hasPlayed = true

        let burst = makeBurst(for: key)
        withAnimation(.spring(response: 0.32, dampingFraction: 0.62)) {
            bursts.append(burst)
            if bursts.count > 36 {
                bursts.removeFirst(bursts.count - 36)
            }
        }

        let burstID = burst.id
        let keyID = key.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) { [weak self] in
            guard let self else { return }
            withAnimation(.easeOut(duration: 0.22)) {
                self.bursts.removeAll { $0.id == burstID }
            }
            if self.litKeyID == keyID {
                self.litKeyID = nil
            }
        }
    }

    func welcome() {
        sound.playWelcome()
    }

    private func makeBurst(for key: ToyKey) -> Burst {
        let seed = abs(key.id.hashValue)
        let jitterX = CGFloat((seed % 17) - 8) / 90
        let jitterY = CGFloat(((seed / 17) % 13) - 6) / 90
        return Burst(
            id: UUID(),
            display: key.display.count == 1 ? key.display : String(key.display.prefix(1)),
            color: key.sound.color,
            x: min(0.88, max(0.12, 0.22 + CGFloat(seed % 60) / 60 * 0.56 + jitterX)),
            y: min(0.52, max(0.12, 0.16 + CGFloat((seed / 60) % 28) / 28 * 0.28 + jitterY)),
            size: CGFloat(86 + seed % 42)
        )
    }
}
