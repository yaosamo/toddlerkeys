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

@main
private enum SongFollowTests {
    static func main() {
        keepsWaitsAsTimingSteps()
        resolvesTheNextPlayableNoteAfterWaiting()
        retainsTheLastPlayedNoteAcrossTheWait()
        preservesTheJingleBellsMelody()

        guard failures == 0 else { exit(1) }
        print("Song follow tests passed")
    }

    private static func keepsWaitsAsTimingSteps() {
        let song = SongBook.jingleBells
        expect(song.notes.count == 13, "keeps waits in the song timing")
        expect(
            {
                if case .wait = song.notes[3] { return true }
                return false
            }(),
            "stores the first phrase break as a timing-only wait"
        )
    }

    private static func resolvesTheNextPlayableNoteAfterWaiting() {
        let song = SongBook.jingleBells
        expect(song.nextKeyID(from: 3) == "c", "queues the next C after the wait")
        expect(song.nextNoteIndex(from: 3) == 4, "skips the timing-only wait when resolving the next note")
    }

    private static func retainsTheLastPlayedNoteAcrossTheWait() {
        let song = SongBook.jingleBells
        expect(song.previousNoteIndex(before: 3) == 2, "retains the C played before the first wait")
        expect(song.previousNoteIndex(before: 4) == 2, "retains the same C until the next note arrives")
    }

    private static func preservesTheJingleBellsMelody() {
        let song = SongBook.jingleBells
        expect(song.notes.compactMap(\.keyID).count == 11, "keeps all eleven playable Jingle Bells notes")
        expect(
            song.notes.compactMap(\.keyID) == ["c", "c", "c", "c", "c", "c", "c", "v", "z", "x", "c"],
            "keeps Jingle Bells note order intact"
        )
    }
}
