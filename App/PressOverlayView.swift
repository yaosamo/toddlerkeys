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

                ForEach(playground.bursts) { burst in
                    BurstBlob(burst: burst, canvas: geo.size)
                }

                if session.isLocked {
                    CenterKitty(bounceTick: playground.bounceTick)
                        .position(x: geo.size.width * 0.5, y: geo.size.height * 0.5)
                        .allowsHitTesting(false)
                }

                if playground.trackpadTick > 0 {
                    TrackpadSurpriseGlow(canvas: geo.size)
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

                    Text("Press the trackpad for a surprise")
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
    @State private var expanded = false

    var body: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        Color.pink.opacity(0.08),
                        Color.yellow.opacity(0.72),
                        Color.purple.opacity(0.16)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: min(680, canvas.width * 0.56), height: 76)
            .position(x: canvas.width * 0.5, y: canvas.height - 96)
            .scaleEffect(expanded ? 1.2 : 0.72)
            .opacity(expanded ? 0 : 0.82)
            .allowsHitTesting(false)
            .onAppear {
                withAnimation(.easeOut(duration: 0.55)) {
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
