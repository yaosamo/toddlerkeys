import AppKit
import SwiftUI

@main
struct ToddlerKeysApp: App {
    @StateObject private var playground = Playground()

    var body: some Scene {
        WindowGroup {
            PlaygroundView(playground: playground)
                .frame(minWidth: 820, minHeight: 600)
                .onAppear {
                    playground.welcome()
                }
        }
        .defaultSize(width: 1100, height: 760)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
