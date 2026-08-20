import SwiftUI

struct SongFollowBar: View {
    let song: NurserySong
    let index: Int
    let completed: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 10) {
            if !completed {
                Text(song.title)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.25), radius: 8, y: 3)
            }

            GeometryReader { geo in
                noteLane(in: geo.size)
            }
            .frame(height: completed ? 84 : 76)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.black.opacity(0.56))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.32), .white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .frame(maxWidth: 460)
    }

    @ViewBuilder
    private func noteLane(in size: CGSize) -> some View {
        let safeInset: CGFloat = 34
        let targetX = min(
            max(safeInset, size.width * 0.2),
            max(safeInset, size.width - safeInset)
        )
        let noteSpacing: CGFloat = 58
        let upcoming = upcomingNotes

        ZStack {
            if !completed {
                Circle()
                    .fill(Color.yellow.opacity(0.08))
                    .frame(width: 64, height: 64)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.yellow.opacity(0.95), lineWidth: 3)
                    )
                    .shadow(color: .yellow.opacity(0.5), radius: 8)
                    .position(x: targetX, y: size.height / 2)

                Text("PRESS")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundStyle(.yellow.opacity(0.95))
                    .position(x: targetX, y: -2)

                ForEach(upcoming) { note in
                    let x = targetX + note.offset * noteSpacing
                    let isCurrent = note.state == .current
                    let isPressed = note.state == .pressed
                    let isActiveWait = note.state == .wait && note.id == index
                    let diameter: CGFloat = (isCurrent || isActiveWait) ? 52 : 38

                    // Do not create a partially visible chip at either edge. This keeps
                    // note keys intact when macOS zoom reduces the overlay's viewport.
                    if x - diameter / 2 >= 0, x + diameter / 2 <= size.width {
                        laneChip(
                            note,
                            isCurrent: isCurrent,
                            isPressed: isPressed,
                            isActiveWait: isActiveWait
                        )
                        .position(x: x, y: size.height / 2)
                        .animation(
                            reduceMotion ? nil : .linear(duration: 0.22),
                            value: index
                        )
                    }
                }
            }

            completionCelebration
                .opacity(completed ? 1 : 0)
                .scaleEffect(completed ? 1.08 : 0.65)
                .animation(
                    reduceMotion ? nil : .spring(response: 0.48, dampingFraction: 0.55),
                    value: completed
                )
        }
        .frame(width: size.width, height: size.height, alignment: .center)
    }

    private var completionCelebration: some View {
        ZStack {
            Text("✦")
                .font(.system(size: 34, weight: .black))
                .foregroundStyle(.yellow)
                .offset(x: -132, y: -18)

            Text("✦")
                .font(.system(size: 28, weight: .black))
                .foregroundStyle(.pink)
                .offset(x: 132, y: 18)

            VStack(spacing: -2) {
                Text("YOU DID IT!")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .yellow.opacity(0.46), radius: 10, y: 3)

                Text("AMAZING!")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.86))
            }
        }
        .accessibilityLabel("You did it! Amazing!")
    }

    private var upcomingNotes: [LaneNote] {
        guard !completed, song.notes.indices.contains(index) else {
            return []
        }

        var notes: [LaneNote] = []
        var offset: CGFloat = 0

        if index > 0, case .wait = song.notes[index - 1] {
            if let previousNoteIndex = song.previousNoteIndex(before: index - 1),
               let keyID = song.notes[previousNoteIndex].keyID {
                notes.append(
                    LaneNote(
                        id: previousNoteIndex,
                        label: keyID.uppercased(),
                        offset: -2,
                        state: .pressed
                    )
                )
            }

            notes.append(
                LaneNote(
                    id: index - 1,
                    label: "WAIT",
                    offset: -1,
                    state: .completedWait
                )
            )
        } else if let previousIndex = song.previousNoteIndex(before: index),
           let keyID = song.notes[previousIndex].keyID {
            notes.append(
                LaneNote(
                    id: previousIndex,
                    label: keyID.uppercased(),
                    offset: -1,
                    state: .pressed
                )
            )
        }

        for (stepIndex, step) in song.notes.dropFirst(index).enumerated() {
            let absoluteIndex = index + stepIndex
            switch step {
            case .note(let keyID, _):
                notes.append(
                    LaneNote(
                        id: absoluteIndex,
                        label: keyID.uppercased(),
                        offset: offset,
                        state: absoluteIndex == index ? .current : .upcoming
                    )
                )
                offset += 1
            case .wait:
                notes.append(
                    LaneNote(
                        id: absoluteIndex,
                        label: "WAIT",
                        offset: offset,
                        state: .wait
                    )
                )
                offset += 1
            }

            if notes.count == 10 { break }
        }

        return notes
    }

    @ViewBuilder
    private func laneChip(
        _ note: LaneNote,
        isCurrent: Bool,
        isPressed: Bool,
        isActiveWait: Bool
    ) -> some View {
        switch note.state {
        case .wait, .completedWait:
            waitChip(
                isActive: isActiveWait,
                isCompleted: note.state == .completedWait
            )
        default:
            noteChip(label: note.label, isCurrent: isCurrent, isPressed: isPressed)
        }
    }

    private func waitChip(isActive: Bool, isCompleted: Bool) -> some View {
        Text("WAIT")
            .font(.system(size: isActive ? 14 : 11, weight: .black, design: .rounded))
            .foregroundStyle(isCompleted ? .white.opacity(0.42) : (isActive ? .white : .yellow.opacity(0.92)))
            .frame(width: isActive ? 52 : 38, height: isActive ? 52 : 38)
            .background(
                Circle().fill(
                    isCompleted
                        ? Color.gray.opacity(0.34)
                        : (isActive ? Color.yellow.opacity(0.42) : .black.opacity(0.30))
                )
            )
            .overlay(
                Circle().strokeBorder(
                    isCompleted ? .white.opacity(0.16) : (isActive ? .white.opacity(0.9) : .yellow.opacity(0.65)),
                    lineWidth: isActive ? 3 : (isCompleted ? 1 : 1.5)
                )
            )
            .scaleEffect(isActive ? 1.06 : (isCompleted ? 0.90 : 1))
            .saturation(isCompleted ? 0 : 1)
            .shadow(color: .yellow.opacity(isActive ? 0.34 : 0), radius: 10, y: 4)
            .animation(
                reduceMotion ? nil : .spring(response: 0.24, dampingFraction: 0.68),
                value: isCompleted
            )
            .accessibilityLabel(isCompleted ? "Completed wait" : "Waiting for the next note")
    }

    private func noteChip(label: String, isCurrent: Bool, isPressed: Bool) -> some View {
        Text(label)
            .font(.system(size: isCurrent ? 26 : 17, weight: .heavy, design: .rounded))
            .foregroundStyle(isPressed ? .white.opacity(0.42) : .white)
            .frame(width: isCurrent ? 52 : 38, height: isCurrent ? 52 : 38)
            .background(
                Circle()
                    .fill(
                        isPressed
                            ? Color.gray.opacity(0.34)
                            : (isCurrent ? Color.yellow.opacity(0.42) : Color.white.opacity(0.17))
                    )
            )
            .overlay(
                Circle()
                    .strokeBorder(
                        isPressed
                            ? Color.white.opacity(0.16)
                            : .white.opacity(isCurrent ? 0.9 : 0.28),
                        lineWidth: isCurrent ? 3 : 1
                    )
            )
            .scaleEffect(isCurrent ? 1.06 : (isPressed ? 0.90 : 1))
            .saturation(isPressed ? 0 : 1)
            .shadow(color: .yellow.opacity(isCurrent ? 0.34 : 0), radius: 10, y: 4)
            .animation(
                reduceMotion ? nil : .spring(response: 0.24, dampingFraction: 0.68),
                value: isPressed
            )
            .accessibilityLabel(isPressed ? "Pressed \(label)" : "Press \(label)")
    }

    private struct LaneNote: Identifiable {
        let id: Int
        let label: String
        let offset: CGFloat
        let state: State

        enum State: Equatable {
            case pressed
            case current
            case upcoming
            case wait
            case completedWait
        }
    }
}
