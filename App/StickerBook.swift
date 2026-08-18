import AppKit
import Foundation
import ImageIO
import SwiftUI

enum StickerBook {
    static let idleKitty = "meow_adorable_hd"

    static let all: [String] = bundledStickerNames()

    static func sticker(for keyID: String) -> String {
        let names = all
        guard !names.isEmpty else { return idleKitty }
        var hash: UInt64 = 5_381
        for byte in keyID.utf8 {
            hash = hash &* 33 &+ UInt64(byte)
        }
        return names[Int(hash % UInt64(names.count))]
    }

    private static func bundledStickerNames() -> [String] {
        let urls =
            (Bundle.main.urls(forResourcesWithExtension: "png", subdirectory: nil) ?? [])
            + (Bundle.main.urls(forResourcesWithExtension: "gif", subdirectory: nil) ?? [])
            + (Bundle.main.urls(forResourcesWithExtension: "png", subdirectory: "Stickers") ?? [])
            + (Bundle.main.urls(forResourcesWithExtension: "gif", subdirectory: "Stickers") ?? [])
        let skip = Set(["meow_adorable_hd", "AppIcon"])
        let names = Set(urls.map { $0.deletingPathExtension().lastPathComponent }.filter { !skip.contains($0) })
        return names.sorted()
    }

    static func url(named name: String) -> URL? {
        let extensions = ["png", "gif"]
        let folders = ["Stickers", "App/Stickers", nil]
        for folder in folders {
            for ext in extensions {
                if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: folder) {
                    return url
                }
            }
        }
        return nil
    }
}

struct StickerAnimation {
    let frames: [NSImage]
    let frameDuration: TimeInterval
}

enum StickerCache {
    private static var images: [String: NSImage] = [:]
    private static var animations: [String: StickerAnimation] = [:]

    static func image(named name: String) -> NSImage? {
        if let cached = images[name] { return cached }
        guard let url = StickerBook.url(named: name), let image = NSImage(contentsOf: url) else {
            return nil
        }
        images[name] = image
        return image
    }

    static func animation(named name: String) -> StickerAnimation? {
        if let cached = animations[name] { return cached }
        guard let url = StickerBook.url(named: name), url.pathExtension.lowercased() == "gif" else {
            return nil
        }
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let count = CGImageSourceGetCount(source)
        guard count > 1 else { return nil }

        var frames: [NSImage] = []
        var total: TimeInterval = 0
        for index in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else { continue }
            frames.append(NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height)))
            if let props = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [String: Any],
               let gif = props[kCGImagePropertyGIFDictionary as String] as? [String: Any] {
                let delay = (gif[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double)
                    ?? (gif[kCGImagePropertyGIFDelayTime as String] as? Double)
                    ?? 0.08
                total += max(delay, 0.04)
            } else {
                total += 0.08
            }
        }
        guard frames.count > 1 else { return nil }
        let animation = StickerAnimation(frames: frames, frameDuration: total / Double(frames.count))
        animations[name] = animation
        return animation
    }
}

struct StickerView: View {
    let name: String

    var body: some View {
        if let animation = StickerCache.animation(named: name) {
            TimelineView(.animation(minimumInterval: animation.frameDuration)) { timeline in
                let index = Int(timeline.date.timeIntervalSinceReferenceDate / animation.frameDuration) % animation.frames.count
                Image(nsImage: animation.frames[index])
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            }
        } else if let image = StickerCache.image(named: name) {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
        } else {
            Text("🐱")
                .font(.system(size: 64))
        }
    }
}
