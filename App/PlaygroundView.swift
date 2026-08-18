import AppKit
import SwiftUI

struct PlaygroundView: View {
    @ObservedObject var playground: Playground

    var body: some View {
        GeometryReader { geo in
            ZStack {
                PlaygroundBackground()

                ForEach(playground.bursts) { burst in
                    BurstBlob(burst: burst)
                        .position(
                            x: burst.x * geo.size.width,
                            y: burst.y * geo.size.height
                        )
                }

                VStack(spacing: 0) {
                    header
                    Spacer(minLength: 8)
                    stage
                    Spacer(minLength: 12)
                    keyboard
                        .padding(.horizontal, 28)
                        .padding(.bottom, 22)
                }
            }
        }
        .background(
            KeyMonitor { event in
                playground.handle(event: event)
            }
            .frame(width: 0, height: 0)
        )
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
        }
        .onTapGesture {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private var header: some View {
        HStack {
            Color.clear.frame(width: 68, height: 12)
            Text("ToddlerKeys")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))
            Spacer()
            Text("⌘Q to quit")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var stage: some View {
        VStack(spacing: 6) {
            Text(playground.headline)
                .font(.system(size: 132, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .animation(.spring(response: 0.28, dampingFraction: 0.7), value: playground.headline)

            Text(playground.hasPlayed ? playground.subtitle : "Mash the keys")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.86))
                .animation(.easeOut(duration: 0.15), value: playground.subtitle)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }

    private var keyboard: some View {
        VStack(spacing: 8) {
            ForEach(Array(KeyMap.visibleRows.enumerated()), id: \.offset) { index, row in
                HStack(spacing: 8) {
                    ForEach(row) { key in
                        KeyCapView(key: key, isLit: playground.litKeyID == key.id) {
                            playground.play(key)
                        }
                    }
                }
                .padding(.leading, rowIndent(index))
                .padding(.trailing, max(0, 28 - rowIndent(index)))
            }

            Text("letters play notes  ·  numbers are silly  ·  space goes boom")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.62))
                .padding(.top, 6)
        }
    }

    private func rowIndent(_ index: Int) -> CGFloat {
        switch index {
        case 2: return 18
        case 3: return 36
        case 4: return 72
        default: return 0
        }
    }
}

private struct KeyCapView: View {
    let key: ToyKey
    let isLit: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(key.display)
                    .font(.system(size: key.flex > 2 ? 18 : 20, weight: .heavy, design: .rounded))
                if key.flex <= 2 {
                    Text(key.caption)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .opacity(0.7)
                }
            }
            .foregroundStyle(isLit ? .white : Color(red: 0.28, green: 0.18, blue: 0.16))
            .frame(maxWidth: .infinity)
            .frame(height: key.flex > 2 ? 52 : 58)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isLit ? key.sound.color : Color.white.opacity(0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(.white.opacity(isLit ? 0.7 : 0.35), lineWidth: 1.5)
            )
            .shadow(color: (isLit ? key.sound.color : .black).opacity(isLit ? 0.45 : 0.08), radius: isLit ? 10 : 3, y: 2)
            .scaleEffect(isLit ? 1.06 : 1)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .layoutPriority(key.flex)
        .animation(.spring(response: 0.22, dampingFraction: 0.62), value: isLit)
    }
}

private struct BurstBlob: View {
    let burst: Burst

    var body: some View {
        Text(burst.display)
            .font(.system(size: burst.size * 0.42, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: burst.size, height: burst.size)
            .background(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [burst.color, burst.color.opacity(0.75)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: burst.color.opacity(0.45), radius: 16, y: 6)
            .transition(.scale.combined(with: .opacity))
            .allowsHitTesting(false)
    }
}

private struct PlaygroundBackground: View {
    private static let meshColors: [Color] = [
        Color(red: 1.00, green: 0.55, blue: 0.42),
        Color(red: 1.00, green: 0.72, blue: 0.32),
        Color(red: 1.00, green: 0.48, blue: 0.58),
        Color(red: 0.46, green: 0.78, blue: 1.00),
        Color(red: 1.00, green: 0.62, blue: 0.38),
        Color(red: 0.62, green: 0.52, blue: 1.00),
        Color(red: 0.38, green: 0.86, blue: 0.68),
        Color(red: 1.00, green: 0.58, blue: 0.46),
        Color(red: 0.98, green: 0.42, blue: 0.52)
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 24)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let cx = Float(0.5 + 0.06 * sin(t * 0.6))
            let cy = Float(0.5 + 0.05 * cos(t * 0.5))
            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    SIMD2<Float>(0, 0), SIMD2<Float>(0.5, 0), SIMD2<Float>(1, 0),
                    SIMD2<Float>(0, 0.5), SIMD2<Float>(cx, cy), SIMD2<Float>(1, 0.5),
                    SIMD2<Float>(0, 1), SIMD2<Float>(0.5, 1), SIMD2<Float>(1, 1)
                ],
                colors: Self.meshColors
            )
        }
        .ignoresSafeArea()
        .overlay(Color.black.opacity(0.08))
    }
}
