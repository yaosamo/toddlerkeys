import AppKit
import SwiftUI

@main
struct MrBlobskyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var session = AppSession.shared

    var body: some Scene {
        MenuBarExtra {
            MenuBarContent(session: session, playground: session.playground, voice: VoiceBank.shared)
        } label: {
            Group {
                if session.isLocked {
                    Image(systemName: "lock.fill")
                } else {
                    Image("MenuBarCat")
                        .renderingMode(.template)
                }
            }
            .accessibilityLabel(session.isLocked ? "Mr.Blobsky Locked" : "Mr.Blobsky")
        }
        .menuBarExtraStyle(.menu)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        if let icon = NSImage(named: "AboutIcon") {
            NSApp.applicationIconImage = icon
        }
        AppSession.shared.start()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        AppSession.shared.retryLockIfNeeded()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

private struct MenuBarContent: View {
    @ObservedObject var session: AppSession
    @ObservedObject var playground: Playground
    @ObservedObject var voice: VoiceBank

    var body: some View {
        VStack {
            Button("About Mr.Blobsky") {
                AboutPanel.shared.show()
            }

            Divider()

            Text(session.lockStatus)

            Button(session.isLocked ? "Unlock" : "Lock Keyboard") {
                session.toggle()
            }
            .keyboardShortcut("k", modifiers: [.option, .command])

            Button("Record a Sound…") {
                RecordPanel.shared.show(playground: playground)
            }

            if voice.hasSample {
                Button(voice.usesVoice ? "Use Built-in Sounds" : "Use My Sound") {
                    playground.setUsesVoice(!voice.usesVoice)
                }
            }

            Menu("Follow a Song") {
                Button("Off") {
                    session.stopFollowingSong()
                }
                Divider()
                ForEach(SongBook.all) { song in
                    Button(song.title) {
                        session.followSong(song)
                    }
                }
            }

            if playground.song != nil {
                Button("Hear Song") {
                    session.hearSong()
                }
            }

            if !session.accessibilityTrusted || !AccessibilityAuth.canListenToKeys {
                Button("Allow Keyboard Access…") {
                    session.requestAccessibility()
                }
            }

            Divider()

            Button("Quit Mr.Blobsky") {
                session.quit()
            }
        }
        .onAppear {
            session.refreshPermissions()
        }
    }
}
