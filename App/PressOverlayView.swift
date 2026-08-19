import SwiftUI

struct PressOverlayView: View {
    @ObservedObject var session: AppSession
    @ObservedObject var playground: Playground

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.08),
                        Color.black.opacity(0.22),
                        Color.black.opacity(0.08)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ForEach(playground.trackpadSparks) { spark in
                    TrackpadSparkView(spark: spark, canvas: geo.size)
                }

                ForEach(playground.bursts) { burst in
                    BurstBlob(burst: burst, canvas: geo.size)
                }

                if playground.hasMovedTrackpad {
                    TrackpadMagicCursor(
                        position: playground.trackpadPosition,
                        canvas: geo.size
                    )
                }

                if session.isLocked {
                    CenterKitty(bounceTick: playground.bounceTick)
                        .position(x: geo.size.width * 0.5, y: geo.size.height * 0.5)
                        .allowsHitTesting(false)
                }

                if playground.trackpadTick > 0 {
                    TrackpadSurpriseGlow(
                        canvas: geo.size,
                        position: playground.trackpadPosition
                    )
                        .id(playground.trackpadTick)
                }

                VStack(spacing: 0) {
                    Spacer()
                    if let song = playground.song {
                        SongFollowBar(
                            song: song,
                            index: playground.songIndex,
                            completed: playground.songCompleted
                        )
                    }

                    if session.isLocked && !session.isKeyboardLocked {
                        Text(session.lockStatus)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(.black.opacity(0.35)))
                            .padding(.top, 10)
                    }

                    Text("Move the trackpad to paint magic • press for a surprise")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.78))
                        .padding(.top, 8)
                    Text("\(ToggleHotKey.displayName) to unlock")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.65))
                        .padding(.top, 6)
                        .padding(.bottom, 28)
                }
                .allowsHitTesting(false)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct TrackpadSurpriseGlow: View {
    let canvas: CGSize
    let position: CGPoint
    @State private var expanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.yellow.opacity(0.72),
                        Color.pink.opacity(0.42),
                        Color.purple.opacity(0.08),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 4,
                    endRadius: 90
                )
            )
            .frame(width: 180, height: 180)
            .position(x: position.x * canvas.width, y: position.y * canvas.height)
            .scaleEffect(expanded ? (reduceMotion ? 1.15 : 2.1) : 0.35)
            .opacity(expanded ? 0 : 0.9)
            .allowsHitTesting(false)
            .onAppear {
                withAnimation(.easeOut(duration: reduceMotion ? 0.18 : 0.55)) {
                    expanded = true
                }
            }
    }
}

private struct TrackpadMagicCursor: View {
    let position: CGPoint
    let canvas: CGSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let color = Color(
            hue: Double(position.x) * 0.7,
            saturation: 0.72,
            brightness: 1
        )

        ZStack {
            Circle()
                .fill(color.opacity(0.18))
                .frame(width: 46, height: 46)
                .blur(radius: 3)
            Image(systemName: "sparkles")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: color, radius: 9)
        }
        .position(x: position.x * canvas.width, y: position.y * canvas.height)
        .animation(
            reduceMotion ? nil : .easeOut(duration: 0.08),
            value: position
        )
        .allowsHitTesting(false)
    }
}

private struct TrackpadSparkView: View {
    let spark: TrackpadSpark
    let canvas: CGSize
    @State private var expanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: spark.size, weight: .bold))
            .foregroundStyle(
                Color(hue: spark.hue, saturation: 0.76, brightness: 1)
            )
            .shadow(
                color: Color(hue: spark.hue, saturation: 0.8, brightness: 1).opacity(0.75),
                radius: 8
            )
            .rotationEffect(.degrees(spark.rotation + (expanded && !reduceMotion ? 32 : 0)))
            .scaleEffect(expanded ? (reduceMotion ? 1 : 1.55) : 0.35)
            .offset(y: expanded && !reduceMotion ? -18 : 0)
            .opacity(expanded ? 0 : 0.95)
            .position(
                x: spark.position.x * canvas.width,
                y: spark.position.y * canvas.height
            )
            .allowsHitTesting(false)
            .onAppear {
                withAnimation(.easeOut(duration: reduceMotion ? 0.18 : 0.68)) {
                    expanded = true
                }
            }
    }
}

private struct CenterKitty: View {
    let bounceTick: Int
    @State private var hop: CGFloat = 0
    @State private var squash: CGFloat = 1

    var body: some View {
        StickerView(name: StickerBook.idleKitty)
            .frame(width: 260, height: 260)
            .scaleEffect(x: squash, y: 1 + hop)
            .offset(y: -hop * 18)
            .shadow(color: .black.opacity(0.22), radius: 18, y: 8)
            .onChange(of: bounceTick) { _, _ in
                hop = 0
                squash = 1
                withAnimation(.easeOut(duration: 0.07)) {
                    hop = 0.28
                    squash = 0.86
                }
                withAnimation(.interpolatingSpring(stiffness: 320, damping: 11).delay(0.07)) {
                    hop = 0
                    squash = 1
                }
            }
    }
}

struct BurstBlob: View {
    let burst: Burst
    let canvas: CGSize
    @State private var progress: CGFloat = 0
    @State private var fade: CGFloat = 1

    var body: some View {
        let t = progress
        let x = burst.startX + (burst.endX - burst.startX) * t
        let y = burst.startY + (burst.endY - burst.startY) * t
        let scale = 0.18 + 0.82 * min(1, t / 0.28)

        StickerView(name: burst.stickerName)
            .frame(width: burst.size, height: burst.size)
            .shadow(color: burst.color.opacity(0.28), radius: 14, y: 6)
            .rotationEffect(.degrees(burst.rotation * Double(t)))
            .scaleEffect(scale)
            .opacity(fade)
            .position(x: x * canvas.width, y: y * canvas.height)
            .allowsHitTesting(false)
            .onAppear {
                progress = 0
                fade = 1
                withAnimation(.easeOut(duration: burst.duration)) {
                    progress = 1
                }
                withAnimation(.easeOut(duration: 0.55).delay(burst.duration + 0.7)) {
                    fade = 0
                }
            }
    }
}
