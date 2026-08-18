import Foundation

enum Instrument: String, CaseIterable, Identifiable {
    case piano
    case guitar
    case drums
    case voice

    var id: String { rawValue }

    var title: String {
        switch self {
        case .piano: return "Piano"
        case .guitar: return "Electric Guitar"
        case .drums: return "Drums"
        case .voice: return "My Sound"
        }
    }

    var symbol: String {
        switch self {
        case .piano: return "pianokeys"
        case .guitar: return "guitars"
        case .drums: return "drum"
        case .voice: return "mic.fill"
        }
    }
}
