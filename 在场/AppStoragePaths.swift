import Foundation

/// Centralizes app-scoped persistence locations.
enum AppStoragePaths {
    static let rootDirectoryName = "Zaichang"
    static let legacyRootDirectoryName = "在场"

    static func applicationSupportRoot(fileManager: FileManager = .default) -> URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(rootDirectoryName, isDirectory: true)
    }

    static func legacyApplicationSupportRoot(fileManager: FileManager = .default) -> URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(legacyRootDirectoryName, isDirectory: true)
    }

    static func memoriesURL(fileManager: FileManager = .default) -> URL {
        applicationSupportRoot(fileManager: fileManager).appendingPathComponent("memories.json")
    }

    static func voiceNotesURL(fileManager: FileManager = .default) -> URL {
        applicationSupportRoot(fileManager: fileManager).appendingPathComponent("voice-notes.json")
    }

    static func generatedScenesURL(fileManager: FileManager = .default) -> URL {
        applicationSupportRoot(fileManager: fileManager).appendingPathComponent("generated-scenes.json")
    }

    static func apiConfigurationURL(fileManager: FileManager = .default) -> URL {
        applicationSupportRoot(fileManager: fileManager).appendingPathComponent("api.yaml")
    }

    static func deskPetsDirectory(fileManager: FileManager = .default) -> URL {
        applicationSupportRoot(fileManager: fileManager).appendingPathComponent("DeskPets", isDirectory: true)
    }

    static func recordingsDirectory(fileManager: FileManager = .default) -> URL {
        applicationSupportRoot(fileManager: fileManager).appendingPathComponent("Recordings", isDirectory: true)
    }

    static func scenesDirectory(fileManager: FileManager = .default) -> URL {
        applicationSupportRoot(fileManager: fileManager).appendingPathComponent("Scenes", isDirectory: true)
    }

    static func migrateLegacyRootIfNeeded(fileManager: FileManager = .default) {
        let legacyRoot = legacyApplicationSupportRoot(fileManager: fileManager)
        let root = applicationSupportRoot(fileManager: fileManager)
        guard fileManager.fileExists(atPath: legacyRoot.path) else { return }
        do {
            try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
            try migrateContents(from: legacyRoot, to: root, fileManager: fileManager)
        } catch {
            // Migration is best-effort; the app can continue reading the legacy location if needed.
        }
    }

    private static func migrateContents(from source: URL, to destination: URL, fileManager: FileManager) throws {
        let keys: [URLResourceKey] = [.isDirectoryKey, .nameKey]
        guard let enumerator = fileManager.enumerator(
            at: source,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) else { return }

        for case let itemURL as URL in enumerator {
            let values = try itemURL.resourceValues(forKeys: Set(keys))
            let relativePath = itemURL.path.replacingOccurrences(of: source.path + "/", with: "")
            let targetURL = destination.appendingPathComponent(relativePath)
            if values.isDirectory == true {
                try fileManager.createDirectory(at: targetURL, withIntermediateDirectories: true)
            } else {
                let parent = targetURL.deletingLastPathComponent()
                try fileManager.createDirectory(at: parent, withIntermediateDirectories: true)
                if !fileManager.fileExists(atPath: targetURL.path) {
                    try fileManager.moveItem(at: itemURL, to: targetURL)
                }
            }
        }

        if let contents = try? fileManager.contentsOfDirectory(atPath: source.path), contents.isEmpty {
            try? fileManager.removeItem(at: source)
        }
    }
}
