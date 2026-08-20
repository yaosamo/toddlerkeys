import AppKit
import SwiftUI

enum AppInfo {
    static var name: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "Lapki"
    }

    static var version: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.2.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(short) (\(build))"
    }

    static var copyright: String {
        Bundle.main.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String
            ?? "Copyright © 2026 Yaosamo"
    }
}

final class AboutPanel {
    static let shared = AboutPanel()
    private var window: NSWindow?

    func show() {
        let window = preparedWindow()
        sizeToFit(window)
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.assistiveTechHighWindow)) + 4)
        window.center()
        window.orderFrontRegardless()
        window.makeKey()
    }

    private func preparedWindow() -> NSWindow {
        if let window {
            return window
        }
        let host = NSHostingController(rootView: AboutView { [weak self] in
            self?.window?.orderOut(nil)
        })
        let window = NSWindow(contentViewController: host)
        window.title = "About \(AppInfo.name)"
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        self.window = window
        return window
    }

    private func sizeToFit(_ window: NSWindow) {
        guard let host = window.contentViewController as? NSHostingController<AboutView> else { return }
        let fitting = host.sizeThatFits(in: NSSize(width: 400, height: 2000))
        window.setContentSize(NSSize(width: 400, height: max(360, fitting.height)))
    }
}

private struct AboutView: View {
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Image("AboutIcon")
                .resizable()
                .interpolation(.high)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.top, 8)

            Text(AppInfo.name)
                .font(.system(size: 20, weight: .bold))
            Text("Version \(AppInfo.version)")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            Text("A menu-bar toy that turns the Mac keyboard into sounds and stickers for little hands.")
                .font(.system(size: 13))
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            if let privacyURL = URL(string: "https://github.com/yaosamo/toddlerkeys/blob/main/PRIVACY.md") {
                Link("Privacy", destination: privacyURL)
                    .font(.system(size: 13, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Credits")
                    .font(.system(size: 12, weight: .semibold))
                Text("Blob Cats by DuckOfDisorder, from Google blob emoji.\nApache License 2.0.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(nsColor: .controlBackgroundColor)))

            Text(AppInfo.copyright)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)
        }
        .padding(20)
        .frame(width: 400)
        .fixedSize(horizontal: true, vertical: true)
    }
}
