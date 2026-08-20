import Foundation

enum SongStep: Equatable {
    case note(keyID: String, beats: Double)
    case wait(beats: Double)

    var keyID: String? {
        if case .note(let keyID, _) = self { return keyID }
        return nil
    }

    var beats: Double {
        switch self {
        case .note(_, let beats), .wait(let beats):
            return beats
        }
    }

    var display: String? { keyID?.uppercased() }

    static func note(_ keyID: String, _ beats: Double = 1) -> SongStep {
        .note(keyID: keyID, beats: beats)
    }

    static func wait(_ beats: Double = 1.4) -> SongStep {
        .wait(beats: beats)
    }
}

struct NurserySong: Identifiable, Equatable {
    let id: String
    let title: String
    let notes: [SongStep]

    /// First playable note at or after a timing-only wait step.
    func nextNoteIndex(from index: Int) -> Int? {
        guard !notes.isEmpty else { return nil }
        let start = min(max(0, index), notes.count)
        return (start..<notes.count).first { notes[$0].keyID != nil }
    }

    func nextKeyID(from index: Int) -> String? {
        guard let noteIndex = nextNoteIndex(from: index) else { return nil }
        return notes[noteIndex].keyID
    }

    func previousNoteIndex(before index: Int) -> Int? {
        guard index > 0, !notes.isEmpty else { return nil }
        let start = min(index - 1, notes.count - 1)
        return stride(from: start, through: 0, by: -1).first { notes[$0].keyID != nil }
    }
}

enum SongBook {
    static let all: [NurserySong] = [mary, hotCrossBuns, jingleBells, rainRain, farmerInTheDell]

    static let mary = NurserySong(
        id: "mary",
        title: "Mary Had a Little Lamb",
        notes: [
            .note("c"), .note("x"), .note("z"), .note("x"),
            .note("c"), .note("c"), .note("c"), .wait(),
            .note("x"), .note("x"), .note("x"), .wait(),
            .note("c"), .note("v"), .note("v"), .wait(),
            .note("c"), .note("x"), .note("z"), .note("x"),
            .note("c"), .note("c"), .note("c"), .note("c"),
            .note("x"), .note("x"), .note("c"), .note("x"),
            .note("z", 1.8)
        ]
    )

    static let hotCrossBuns = NurserySong(
        id: "hot-cross-buns",
        title: "Hot Cross Buns",
        notes: [
            .note("c"), .note("x"), .note("z"), .wait(),
            .note("c"), .note("x"), .note("z"), .wait(),
            .note("z", 0.55), .note("z", 0.55), .note("z", 0.55), .note("z", 0.55),
            .note("x", 0.55), .note("x", 0.55), .note("x", 0.55), .note("x", 0.55),
            .note("c"), .note("x"), .note("z", 1.8)
        ]
    )

    static let jingleBells = NurserySong(
        id: "jingle-bells",
        title: "Jingle Bells",
        notes: [
            .note("c"), .note("c"), .note("c"), .wait(),
            .note("c"), .note("c"), .note("c"), .wait(),
            .note("c"), .note("v"), .note("z"), .note("x"),
            .note("c", 1.8)
        ]
    )

    static let rainRain = NurserySong(
        id: "rain-rain",
        title: "Rain Rain Go Away",
        notes: [
            .note("v"), .note("c"), .note("v"), .note("c"), .wait(1.3),
            .note("v"), .note("b"), .note("v"), .note("c"), .wait(1.3),
            .note("x"), .note("x"), .note("c"), .note("v"), .wait(1.3),
            .note("c"), .note("x"), .note("z", 1.8)
        ]
    )

    static let farmerInTheDell = NurserySong(
        id: "farmer",
        title: "The Farmer in the Dell",
        notes: [
            .note("z"), .note("z"), .note("z"), .note("v"), .wait(1.3),
            .note("b"), .note("b"), .note("v"), .wait(1.3),
            .note("c"), .note("c"), .note("x"), .note("x"),
            .note("z", 1.8)
        ]
    )

    static func song(id: String) -> NurserySong? {
        all.first { $0.id == id }
    }
}
