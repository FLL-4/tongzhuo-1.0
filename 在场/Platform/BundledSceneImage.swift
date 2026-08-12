import SwiftUI
#if os(macOS)
import AppKit
#elseif os(iOS) || os(visionOS)
import UIKit
#endif

struct BundledSceneImage: View {
    let relativePath: String

    var body: some View {
#if os(macOS)
        if let image = imageURL.flatMap(NSImage.init(contentsOf:)) {
            Image(nsImage: image).resizable().scaledToFill()
        } else {
            fallback
        }
#elseif os(iOS) || os(visionOS)
        if let image = imageURL.flatMap({ try? Data(contentsOf: $0) }).flatMap(UIImage.init(data:)) {
            Image(uiImage: image).resizable().scaledToFill()
        } else {
            fallback
        }
#else
        fallback
#endif
    }

    private var imageURL: URL? {
        if let userURL = SceneAssetStore.shared.url(for: relativePath),
           FileManager.default.fileExists(atPath: userURL.path) {
            return userURL
        }

        let resourceURL = Bundle.main.resourceURL
        let bundledPath = resourceURL?.appendingPathComponent(relativePath)

        if let bundledPath, FileManager.default.fileExists(atPath: bundledPath.path) {
            return bundledPath
        }

        let path = relativePath as NSString
        let directory = path.deletingLastPathComponent
        let fileName = (path.lastPathComponent as NSString).deletingPathExtension
        let fileExtension = (path.lastPathComponent as NSString).pathExtension
        if let nestedURL = Bundle.main.url(
            forResource: fileName,
            withExtension: fileExtension,
            subdirectory: directory
        ) {
            return nestedURL
        }
        return Bundle.main.url(forResource: fileName, withExtension: fileExtension)
    }

    private var fallback: some View {
        ZStack {
            Color(red: 0.10, green: 0.13, blue: 0.18)
            Image(systemName: "photo").foregroundStyle(Palette.muted)
        }
    }
}

final class SceneAssetStore {
    static let shared = SceneAssetStore()

    private let fileManager = FileManager.default

    private var rootURL: URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Zaichang", isDirectory: true)
            .appendingPathComponent("Scenes", isDirectory: true)
    }

    func url(for relativePath: String) -> URL? {
        guard relativePath.hasPrefix("Scenes/"), !relativePath.contains("..") else { return nil }
        return rootURL.appendingPathComponent(String(relativePath.dropFirst("Scenes/".count)))
    }

    func store(_ data: Data, relativePath: String) throws {
        guard let url = url(for: relativePath) else { throw CocoaError(.fileNoSuchFile) }
        try fileManager.createDirectory(at: rootURL, withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }
}
