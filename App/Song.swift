import Foundation

struct SongStep: Equatable {
    let keyID: String
    let beats: Double

    var display: String { keyID.uppercased() }

    static func note(_ keyID: String, _ beats: Double = 1) -> SongStep {
        SongStep(keyID: keyID, beats: beats)
    }
}

struct NurserySong: Identifiable, Equatable {
    let id: String
    let title: String
    let hint: String
    let notes: [SongStep]
}

enum SongBook {
    static let all: [NurserySong] = [mary, hotCrossBuns, jingleBells, rainRain, farmerInTheDell]

    static let mary = NurserySong(
        id: "mary",
        title: "Mary Had a Little Lamb",
        hint: "Use Z X C V on the bottom row",
        notes: [
            .note("c"), .note("x"), .note("z"), .note("x"),
            .note("c"), .note("c"), .note("c", 1.4),
            .note("x"), .note("x"), .note("x", 1.4),
            .note("c"), .note("v"), .note("v", 1.4),
            .note("c"), .note("x"), .note("z"), .note("x"),
            .note("c"), .note("c"), .note("c"), .note("c"),
            .note("x"), .note("x"), .note("c"), .note("x"),
            .note("z", 1.8)
        ]
    )

    static let hotCrossBuns = NurserySong(
        id: "hot-cross-buns",
        title: "Hot Cross Buns",
        hint: "Use Z X C on the bottom row",
        notes: [
            .note("c"), .note("x"), .note("z", 1.4),
            .note("c"), .note("x"), .note("z", 1.4),
            .note("z", 0.55), .note("z", 0.55), .note("z", 0.55), .note("z", 0.55),
            .note("x", 0.55), .note("x", 0.55), .note("x", 0.55), .note("x", 0.55),
            .note("c"), .note("x"), .note("z", 1.8)
        ]
    )

    static let jingleBells = NurserySong(
        id: "jingle-bells",
        title: "Jingle Bells",
        hint: "Use Z X C V on the bottom row",
        notes: [
            .note("c"), .note("c"), .note("c", 1.4),
            .note("c"), .note("c"), .note("c", 1.4),
            .note("c"), .note("v"), .note("z"), .note("x"),
            .note("c", 1.8)
        ]
    )

    static let rainRain = NurserySong(
        id: "rain-rain",
        title: "Rain Rain Go Away",
        hint: "Use Z X C V B on the bottom row",
        notes: [
            .note("v"), .note("c"), .note("v"), .note("c", 1.3),
            .note("v"), .note("b"), .note("v"), .note("c", 1.3),
            .note("x"), .note("x"), .note("c"), .note("v", 1.3),
            .note("c"), .note("x"), .note("z", 1.8)
        ]
    )

    static let farmerInTheDell = NurserySong(
        id: "farmer",
        title: "The Farmer in the Dell",
        hint: "Use Z X C V B on the bottom row",
        notes: [
            .note("z"), .note("z"), .note("z"), .note("v", 1.3),
            .note("b"), .note("b"), .note("v", 1.3),
            .note("c"), .note("c"), .note("x"), .note("x"),
            .note("z", 1.8)
        ]
    )

    static func song(id: String) -> NurserySong? {
        all.first { $0.id == id }
    }
}
