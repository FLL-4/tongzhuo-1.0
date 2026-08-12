import Foundation

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

struct SceneImageMetadata: Codable, Equatable {
    let accessibilityDescription: String
}

struct SceneImageAsset: Codable, Equatable {
    let relativePath: String
    let metadata: SceneImageMetadata

    var accessibilityDescription: String { metadata.accessibilityDescription }
}

extension SceneImageAsset {
    static func packaged(
        sceneID: RoomScene.ID,
        metadata: SceneImageMetadata
    ) -> SceneImageAsset {
        SceneImageAsset(
            relativePath: SceneGenerationContract.relativeImagePath(sceneID: sceneID),
            metadata: metadata
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
    let image: SceneImageAsset
    let ambientPreset: AmbientPreset
    let weatherEffect: SceneWeatherEffect
    let promptVersion: Int
}

enum RoomSceneCatalog {
    static let rainyStudy = RoomScene(
        id: "rainy-study",
        origin: .builtIn,
        name: "雨夜书房",
        eyebrow: "星期一 · 雨夜",
        headline: "一起安静坐一会儿",
        image: .packaged(
            sceneID: "rainy-study",
            metadata: SceneImageMetadata(
                accessibilityDescription: "雨夜像素书房的静态背景"
            )
        ),
        ambientPreset: .rain,
        weatherEffect: .rain,
        promptVersion: SceneGenerationContract.currentPromptVersion
    )

    static let lakesideDesk = RoomScene(
        id: "lakeside-desk",
        origin: .builtIn,
        name: "湖畔桌面",
        eyebrow: "星期二 · 湖畔清晨",
        headline: "让今天慢慢开始",
        image: .packaged(
            sceneID: "lakeside-desk",
            metadata: SceneImageMetadata(
                accessibilityDescription: "清晨湖畔像素工作室的静态背景"
            )
        ),
        ambientPreset: .forest,
        weatherEffect: .none,
        promptVersion: SceneGenerationContract.currentPromptVersion
    )

    static let midnightCabin = RoomScene(
        id: "midnight-cabin",
        origin: .builtIn,
        name: "深夜小屋",
        eyebrow: "星期五 · 山林深夜",
        headline: "灯还亮着，我也在",
        image: .packaged(
            sceneID: "midnight-cabin",
            metadata: SceneImageMetadata(
                accessibilityDescription: "深夜山林小屋的静态背景"
            )
        ),
        ambientPreset: .fireplace,
        weatherEffect: .none,
        promptVersion: SceneGenerationContract.currentPromptVersion
    )

    static let builtIn: [RoomScene] = [rainyStudy, lakesideDesk, midnightCabin]
}
