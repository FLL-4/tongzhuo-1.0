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
        let resourceURL = Bundle.main.resourceURL
        let bundledPath = resourceURL?
            .appendingPathComponent("WebApp", isDirectory: true)
            .appendingPathComponent(relativePath)

        if let bundledPath, FileManager.default.fileExists(atPath: bundledPath.path) {
            return bundledPath
        }

        let path = relativePath as NSString
        let directory = "WebApp/\(path.deletingLastPathComponent)"
        let fileName = (path.lastPathComponent as NSString).deletingPathExtension
        let fileExtension = (path.lastPathComponent as NSString).pathExtension
        return Bundle.main.url(
            forResource: fileName,
            withExtension: fileExtension,
            subdirectory: directory
        )
    }

    private var fallback: some View {
        ZStack {
            Color(red: 0.10, green: 0.13, blue: 0.18)
            Image(systemName: "photo").foregroundStyle(Palette.muted)
        }
    }
}
