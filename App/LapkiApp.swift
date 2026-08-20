import AppKit
import SwiftUI

@main
struct LapkiApp: App {
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
            .accessibilityLabel(session.isLocked ? "Lapki Locked" : "Lapki")
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
            Button("About Lapki") {
                AboutPanel.shared.show()
            }

            Divider()

            Text(session.lockStatus)

            if let playTimeStatus = session.playTimeStatus {
                Text(playTimeStatus)
            }

            if session.isLocked {
                Button("Unlock  \(GlobalHotKeys.toggleLock.displayName)") {
                    session.unlock()
                }
            } else {
                Button("Lock Keyboard  \(GlobalHotKeys.toggleLock.displayName)") {
                    session.lockAndShow()
                }

                Button("Lock for 2-Minute Play  \(GlobalHotKeys.twoMinutePlay.displayName)") {
                    session.lockForTwoMinutes()
                }
            }

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
                ForEach(Array(SongBook.all.enumerated()), id: \.element.id) { index, song in
                    Button("\(song.title)  \(GlobalHotKeys.songs[index].displayName)") {
                        session.followSong(song)
                    }
                }
            }

            if playground.song != nil {
                Button("Play Song  \(GlobalHotKeys.playSong.displayName)") {
                    session.playSong()
                }
            }

            if !session.accessibilityTrusted || !AccessibilityAuth.canListenToKeys {
                Button("Allow Keyboard Access…") {
                    session.requestAccessibility()
                }
            }

            Divider()

            Button("Quit Lapki") {
                session.quit()
            }
        }
        .onAppear {
            session.refreshPermissions()
        }
    }
}
