import SwiftUI

struct SongFollowBar: View {
    let song: NurserySong
    let index: Int
    let completed: Bool

    var body: some View {
        VStack(spacing: 10) {
            Text(completed ? "Yay! Again…" : song.title)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.25), radius: 8, y: 3)

            if !completed {
                Text("Play \(nextDisplay)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
            }

            HStack(spacing: 8) {
                ForEach(visibleWindow, id: \.offset) { item in
                    let isCurrent = !completed && item.offset == index
                    Text(item.step.display)
                        .font(.system(size: isCurrent ? 28 : 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: isCurrent ? 56 : 36, height: isCurrent ? 56 : 36)
                        .background(
                            Circle()
                                .fill(isCurrent ? Color.white.opacity(0.32) : Color.white.opacity(0.16))
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(.white.opacity(isCurrent ? 0.95 : 0.25), lineWidth: isCurrent ? 3 : 1)
                        )
                        .scaleEffect(isCurrent ? 1.08 : 1)
                        .shadow(color: .black.opacity(isCurrent ? 0.25 : 0), radius: 10, y: 4)
                }
            }
            .animation(.spring(response: 0.32, dampingFraction: 0.7), value: index)
            .animation(.spring(response: 0.32, dampingFraction: 0.7), value: completed)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.black.opacity(0.28))
        )
    }

    private var nextDisplay: String {
        guard index < song.notes.count else { return "" }
        return song.notes[index].display
    }

    private var visibleWindow: [(offset: Int, step: SongStep)] {
        let start = min(index, max(0, song.notes.count - 1))
        let end = min(song.notes.count, start + 8)
        return Array(song.notes[start..<end].enumerated().map { item in
            (offset: start + item.offset, step: item.element)
        })
    }
}
