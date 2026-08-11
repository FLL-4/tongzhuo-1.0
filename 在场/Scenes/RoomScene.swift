import Foundation

enum SceneOccupancy: String, Codable, CaseIterable, Equatable, Hashable {
    case together
    case solo
}

enum AmbientPreset: String, Codable, CaseIterable, Equatable, Hashable {
    case quiet
    case rain
    case forest
    case fireplace

    var displayName: String {
        switch self {
        case .quiet: "安静"
        case .rain: "雨声"
        case .forest: "林间鸟鸣"
        case .fireplace: "壁炉声"
        }
    }
}

enum SceneWeatherEffect: String, Codable, Equatable {
    case none
    case rain
}

enum SceneAtmosphericEffect: String, Codable, Equatable {
    case none
    case steam
}

struct SteamAnchor: Codable, Equatable {
    let xPercent: Double
    let yPercent: Double
    let particleCount: Int
    let opacity: Double
}

struct SceneImageMetadata: Codable, Equatable {
    let accessibilityDescription: String
    var steamAnchors: [SteamAnchor] = []
}

struct SceneImageAsset: Codable, Equatable {
    let relativePath: String
    let metadata: SceneImageMetadata

    var webPath: String { "./\(relativePath)" }
    var accessibilityDescription: String { metadata.accessibilityDescription }
    var steamAnchors: [SteamAnchor] { metadata.steamAnchors }
}

struct SceneImageSet: Codable, Equatable {
    let together: SceneImageAsset
    let solo: SceneImageAsset

    func asset(for occupancy: SceneOccupancy) -> SceneImageAsset {
        switch occupancy {
        case .together: together
        case .solo: solo
        }
    }

    static func packaged(
        sceneID: RoomScene.ID,
        together: SceneImageMetadata,
        solo: SceneImageMetadata
    ) -> SceneImageSet {
        SceneImageSet(
            together: SceneImageAsset(
                relativePath: SceneGenerationContract.relativeImagePath(
                    sceneID: sceneID,
                    occupancy: .together
                ),
                metadata: together
            ),
            solo: SceneImageAsset(
                relativePath: SceneGenerationContract.relativeImagePath(
                    sceneID: sceneID,
                    occupancy: .solo
                ),
                metadata: solo
            )
        )
    }
}

enum SceneOrigin: String, Codable, Equatable {
    case builtIn
    case generated
}

struct RoomScene: Codable, Equatable, Identifiable {
    typealias ID = String

    let id: ID
    let origin: SceneOrigin
    let name: String
    let eyebrow: String
    let headline: String
    let images: SceneImageSet
    let ambientPreset: AmbientPreset
    let weatherEffect: SceneWeatherEffect
    let atmosphericEffect: SceneAtmosphericEffect
    let promptVersion: Int

    func image(for occupancy: SceneOccupancy) -> SceneImageAsset {
        images.asset(for: occupancy)
    }
}

enum RoomSceneCatalog {
    static let rainyStudy = RoomScene(
        id: "rainy-study",
        origin: .builtIn,
        name: "雨夜书房",
        eyebrow: "星期一 · 雨夜",
        headline: "一起安静坐一会儿",
        images: .packaged(
            sceneID: "rainy-study",
            together: SceneImageMetadata(
                accessibilityDescription: "雨夜中，两个人在像素书房里安静同桌"
            ),
            solo: SceneImageMetadata(
                accessibilityDescription: "雨夜中，一个人在像素书房里安静专注"
            )
        ),
        ambientPreset: .rain,
        weatherEffect: .rain,
        atmosphericEffect: .none,
        promptVersion: SceneGenerationContract.currentPromptVersion
    )

    static let lakesideDesk = RoomScene(
        id: "lakeside-desk",
        origin: .builtIn,
        name: "湖畔桌面",
        eyebrow: "星期二 · 湖畔清晨",
        headline: "让今天慢慢开始",
        images: .packaged(
            sceneID: "lakeside-desk",
            together: SceneImageMetadata(
                accessibilityDescription: "清晨湖畔，两个人在木屋里安静同桌"
            ),
            solo: SceneImageMetadata(
                accessibilityDescription: "清晨湖畔，一个人在木屋里安静专注"
            )
        ),
        ambientPreset: .forest,
        weatherEffect: .none,
        atmosphericEffect: .none,
        promptVersion: SceneGenerationContract.currentPromptVersion
    )

    static let midnightCabin = RoomScene(
        id: "midnight-cabin",
        origin: .builtIn,
        name: "深夜小屋",
        eyebrow: "星期五 · 山林深夜",
        headline: "灯还亮着，我也在",
        images: .packaged(
            sceneID: "midnight-cabin",
            together: SceneImageMetadata(
                accessibilityDescription: "深夜山林小屋里，两个人各自安静做事",
                steamAnchors: [
                    SteamAnchor(xPercent: 33.7, yPercent: 53.2, particleCount: 3, opacity: 0.36),
                    SteamAnchor(xPercent: 62.1, yPercent: 64.2, particleCount: 5, opacity: 0.52),
                ]
            ),
            solo: SceneImageMetadata(
                accessibilityDescription: "深夜山林小屋里，一个人在壁炉旁安静专注",
                steamAnchors: [
                    SteamAnchor(xPercent: 33.4, yPercent: 53.0, particleCount: 4, opacity: 0.40),
                ]
            )
        ),
        ambientPreset: .fireplace,
        weatherEffect: .none,
        atmosphericEffect: .steam,
        promptVersion: SceneGenerationContract.currentPromptVersion
    )

    static let builtIn: [RoomScene] = [rainyStudy, lakesideDesk, midnightCabin]
}
