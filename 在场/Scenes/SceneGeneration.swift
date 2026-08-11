import Foundation

enum SceneImageFormat: String, Codable, Equatable {
    case png
}

struct SceneCanvas: Codable, Equatable {
    let width: Int
    let height: Int
    let format: SceneImageFormat
}

enum SceneGenerationContract {
    static let currentPromptVersion = 1
    static let maximumAutomaticRepairAttempts = 1
    static let canvas = SceneCanvas(width: 1_920, height: 1_080, format: .png)
    static let assetRootDirectory = "assets/scenes"
    static let requiredOccupancies = SceneOccupancy.allCases

    static func relativeImagePath(sceneID: RoomScene.ID, occupancy: SceneOccupancy) -> String {
        "\(assetRootDirectory)/\(sceneID)/\(occupancy.rawValue).\(canvas.format.rawValue)"
    }

    static func isValidSceneID(_ sceneID: String) -> Bool {
        guard
            !sceneID.isEmpty,
            sceneID.first?.isASCII == true,
            sceneID.first?.isLetter == true,
            sceneID.last?.isASCII == true,
            sceneID.last?.isLetter == true || sceneID.last?.isNumber == true
        else { return false }

        return sceneID.allSatisfy {
            $0.isASCII && ($0.isLowercase || $0.isNumber || $0 == "-")
        }
    }
}

enum SceneTimeOfDay: String, Codable, CaseIterable, Equatable, Hashable {
    case dawn
    case daytime
    case dusk
    case lateNight

    var promptValue: String {
        switch self {
        case .dawn: "dawn"
        case .daytime: "daytime"
        case .dusk: "dusk"
        case .lateNight: "late night"
        }
    }

    var displayName: String {
        switch self {
        case .dawn: "清晨"
        case .daytime: "白天"
        case .dusk: "黄昏"
        case .lateNight: "深夜"
        }
    }
}

enum SceneMood: String, Codable, CaseIterable, Equatable, Hashable {
    case quiet
    case warm
    case clear
    case sleepy

    var promptValue: String {
        switch self {
        case .quiet: "quiet"
        case .warm: "warm"
        case .clear: "clear and awake"
        case .sleepy: "soft and sleepy"
        }
    }

    var displayName: String {
        switch self {
        case .quiet: "安静"
        case .warm: "温暖"
        case .clear: "清醒"
        case .sleepy: "困倦"
        }
    }
}

enum SceneEffectPreset: String, Codable, CaseIterable, Equatable, Hashable {
    case none
    case rain
    case steam

    var weatherEffect: SceneWeatherEffect {
        self == .rain ? .rain : .none
    }

    var atmosphericEffect: SceneAtmosphericEffect {
        self == .steam ? .steam : .none
    }

    var displayName: String {
        switch self {
        case .none: "无"
        case .rain: "雨"
        case .steam: "蒸汽"
        }
    }
}

struct GeneratedSceneSpec: Codable, Equatable, Identifiable {
    let sceneID: RoomScene.ID
    var name: String
    var location: String
    var timeOfDay: SceneTimeOfDay
    var weather: String
    var mood: SceneMood
    var windowView: String
    var lighting: String
    var keyObjects: [String]
    var ambientPreset: AmbientPreset
    var effectPreset: SceneEffectPreset
    var promptVersion: Int

    var id: RoomScene.ID { sceneID }

    init(
        sceneID: RoomScene.ID,
        name: String,
        location: String,
        timeOfDay: SceneTimeOfDay,
        weather: String,
        mood: SceneMood,
        windowView: String,
        lighting: String,
        keyObjects: [String],
        ambientPreset: AmbientPreset,
        effectPreset: SceneEffectPreset,
        promptVersion: Int = SceneGenerationContract.currentPromptVersion
    ) {
        self.sceneID = sceneID
        self.name = name
        self.location = location
        self.timeOfDay = timeOfDay
        self.weather = weather
        self.mood = mood
        self.windowView = windowView
        self.lighting = lighting
        self.keyObjects = keyObjects
        self.ambientPreset = ambientPreset
        self.effectPreset = effectPreset
        self.promptVersion = promptVersion
    }

    func validate() throws {
        guard SceneGenerationContract.isValidSceneID(sceneID) else {
            throw SceneSpecValidationError.invalidSceneID
        }
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SceneSpecValidationError.missingName
        }
        guard !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SceneSpecValidationError.missingLocation
        }
        guard keyObjects.count <= 3 else {
            throw SceneSpecValidationError.tooManyKeyObjects(maximum: 3)
        }
        guard promptVersion == SceneGenerationContract.currentPromptVersion else {
            throw SceneSpecValidationError.unsupportedPromptVersion(promptVersion)
        }
    }
}

enum SceneSpecValidationError: Error, Equatable {
    case invalidSceneID
    case missingName
    case missingLocation
    case tooManyKeyObjects(maximum: Int)
    case unsupportedPromptVersion(Int)
}

struct SceneGenerationPrompt: Codable, Equatable {
    let occupancy: SceneOccupancy
    let promptVersion: Int
    let text: String
}

struct SceneStyleReference: Codable, Equatable {
    let sceneID: RoomScene.ID
    let togetherImagePath: String
    let soloImagePath: String

    static var builtIn: [SceneStyleReference] {
        RoomSceneCatalog.builtIn.map { scene in
            SceneStyleReference(
                sceneID: scene.id,
                togetherImagePath: scene.image(for: .together).relativePath,
                soloImagePath: scene.image(for: .solo).relativePath
            )
        }
    }
}

struct SceneGenerationPrompts: Codable, Equatable {
    let together: SceneGenerationPrompt
    let solo: SceneGenerationPrompt

    func prompt(for occupancy: SceneOccupancy) -> SceneGenerationPrompt {
        switch occupancy {
        case .together: together
        case .solo: solo
        }
    }
}

struct SceneGenerationRequest: Codable, Equatable, Identifiable {
    let id: UUID
    let spec: GeneratedSceneSpec
    let prompts: SceneGenerationPrompts
    let styleReferences: [SceneStyleReference]

    init(
        id: UUID = UUID(),
        spec: GeneratedSceneSpec,
        styleReferences: [SceneStyleReference]
    ) throws {
        try spec.validate()
        self.id = id
        self.spec = spec
        prompts = ScenePromptCompiler.compile(spec)
        self.styleReferences = styleReferences
    }

    init(id: UUID = UUID(), spec: GeneratedSceneSpec) throws {
        try self.init(id: id, spec: spec, styleReferences: SceneStyleReference.builtIn)
    }
}

enum SceneReviewIssue: String, Codable, Equatable {
    case pixelStyleMismatch
    case occupancyMismatch
    case interfaceSafeAreaConflict
    case forbiddenContentDetected

    var repairInstruction: String {
        switch self {
        case .pixelStyleMismatch:
            "Restore crisp pixel clusters, limited palette and consistent pixel density."
        case .occupancyMismatch:
            "Correct the number of people and workstations for the requested occupancy variant."
        case .interfaceSafeAreaConflict:
            "Move faces and essential objects away from the reserved top and bottom interface areas."
        case .forbiddenContentDetected:
            "Remove all text, logos, watermarks, UI controls and malformed duplicated content."
        }
    }
}

enum SceneGenerationState: Codable, Equatable {
    case queued
    case generating(SceneOccupancy)
    case reviewing
    case repairing(attempt: Int, issues: [SceneReviewIssue])
    case ready(SceneGenerationResult)
    case failed(message: String)
}

struct GeneratedSceneImage: Codable, Equatable {
    let relativePath: String
    let canvas: SceneCanvas
    let metadata: SceneImageMetadata
}

struct GeneratedSceneImages: Codable, Equatable {
    let together: GeneratedSceneImage
    let solo: GeneratedSceneImage

    func image(for occupancy: SceneOccupancy) -> GeneratedSceneImage {
        switch occupancy {
        case .together: together
        case .solo: solo
        }
    }
}

struct SceneGenerationResult: Codable, Equatable {
    let requestID: SceneGenerationRequest.ID
    let sceneID: RoomScene.ID
    let images: GeneratedSceneImages
    let review: SceneGenerationReview
    let completedAt: Date

    func targetRelativePath(for occupancy: SceneOccupancy) -> String {
        SceneGenerationContract.relativeImagePath(sceneID: sceneID, occupancy: occupancy)
    }
}

struct SceneGenerationReview: Codable, Equatable {
    let pixelStyleConsistent: Bool
    let occupancyCorrect: Bool
    let interfaceSafeAreasClear: Bool
    let forbiddenContentAbsent: Bool

    var isApproved: Bool {
        pixelStyleConsistent
            && occupancyCorrect
            && interfaceSafeAreasClear
            && forbiddenContentAbsent
    }

    var issues: [SceneReviewIssue] {
        var issues: [SceneReviewIssue] = []
        if !pixelStyleConsistent { issues.append(.pixelStyleMismatch) }
        if !occupancyCorrect { issues.append(.occupancyMismatch) }
        if !interfaceSafeAreasClear { issues.append(.interfaceSafeAreaConflict) }
        if !forbiddenContentAbsent { issues.append(.forbiddenContentDetected) }
        return issues
    }
}

struct SceneRepairRequest: Codable, Equatable {
    let generationRequestID: SceneGenerationRequest.ID
    let occupancy: SceneOccupancy
    let attempt: Int
    let prompt: String
    let issues: [SceneReviewIssue]
}

struct SceneGenerationJob: Codable, Equatable, Identifiable {
    let request: SceneGenerationRequest
    var state: SceneGenerationState

    var id: SceneGenerationRequest.ID { request.id }
}

protocol SceneGenerating {
    func generate(
        _ request: SceneGenerationRequest,
        progress: @escaping (SceneGenerationState) -> Void
    ) async throws -> SceneGenerationResult
}

struct MockSceneGenerator: SceneGenerating {
    func generate(
        _ request: SceneGenerationRequest,
        progress: @escaping (SceneGenerationState) -> Void
    ) async throws -> SceneGenerationResult {
        progress(.generating(.together))
        try await Task.sleep(for: .milliseconds(520))
        progress(.generating(.solo))
        try await Task.sleep(for: .milliseconds(520))
        progress(.reviewing)
        try await Task.sleep(for: .milliseconds(420))

        let template = templateScene(for: request.spec)
        let togetherTemplate = template.image(for: .together)
        let soloTemplate = template.image(for: .solo)
        let sceneName = request.spec.name

        return SceneGenerationResult(
            requestID: request.id,
            sceneID: request.spec.sceneID,
            images: GeneratedSceneImages(
                together: GeneratedSceneImage(
                    relativePath: togetherTemplate.relativePath,
                    canvas: SceneGenerationContract.canvas,
                    metadata: SceneImageMetadata(
                        accessibilityDescription: "两个人在\(sceneName)安静同桌",
                        steamAnchors: togetherTemplate.steamAnchors
                    )
                ),
                solo: GeneratedSceneImage(
                    relativePath: soloTemplate.relativePath,
                    canvas: SceneGenerationContract.canvas,
                    metadata: SceneImageMetadata(
                        accessibilityDescription: "一个人在\(sceneName)安静专注",
                        steamAnchors: soloTemplate.steamAnchors
                    )
                )
            ),
            review: SceneGenerationReview(
                pixelStyleConsistent: true,
                occupancyCorrect: true,
                interfaceSafeAreasClear: true,
                forbiddenContentAbsent: true
            ),
            completedAt: Date()
        )
    }

    private func templateScene(for spec: GeneratedSceneSpec) -> RoomScene {
        if spec.effectPreset == .rain || spec.ambientPreset == .rain {
            return RoomSceneCatalog.rainyStudy
        }
        if spec.effectPreset == .steam
            || spec.ambientPreset == .fireplace
            || spec.timeOfDay == .lateNight
            || spec.weather.contains("雪")
        {
            return RoomSceneCatalog.midnightCabin
        }
        return RoomSceneCatalog.lakesideDesk
    }
}

enum ScenePromptCompiler {
    static func compile(_ spec: GeneratedSceneSpec) -> SceneGenerationPrompts {
        SceneGenerationPrompts(
            together: prompt(for: spec, occupancy: .together),
            solo: prompt(for: spec, occupancy: .solo)
        )
    }

    static func compileRepairRequest(
        for request: SceneGenerationRequest,
        occupancy: SceneOccupancy,
        review: SceneGenerationReview,
        attempt: Int
    ) -> SceneRepairRequest? {
        guard
            !review.isApproved,
            attempt > 0,
            attempt <= SceneGenerationContract.maximumAutomaticRepairAttempts
        else { return nil }

        let issues = review.issues
        let instructions = issues
            .map { "- \($0.repairInstruction)" }
            .joined(separator: "\n")
        let originalPrompt = request.prompts.prompt(for: occupancy).text
        return SceneRepairRequest(
            generationRequestID: request.id,
            occupancy: occupancy,
            attempt: attempt,
            prompt: """
            \(originalPrompt)

            TARGETED REPAIR
            Preserve the approved composition and change only the failed checks below:
            \(instructions)
            """,
            issues: issues
        )
    }

    private static func prompt(
        for spec: GeneratedSceneSpec,
        occupancy: SceneOccupancy
    ) -> SceneGenerationPrompt {
        let compositionRules: String
        switch occupancy {
        case .together:
            compositionRules = """
            OCCUPANCY VARIANT: TOGETHER
            - Show exactly two people quietly sharing the room.
            - Include two visually balanced work positions with equal importance.
            - Keep both people naturally integrated into the environment.
            """
        case .solo:
            compositionRules = """
            OCCUPANCY VARIANT: SOLO
            - Show exactly one person, using the left-side person from the together composition.
            - Remove the right-side person and their desk or workstation completely.
            - Do not leave an empty second desk, empty chair or obvious gap where they used to be.
            - Recompose furniture and room details as needed so the single-person scene feels complete.
            """
        }

        let keyObjects = spec.keyObjects.isEmpty
            ? "none required"
            : spec.keyObjects.map { promptValue($0) }.joined(separator: ", ")
        let text = """
        Create a production-ready \(SceneGenerationContract.canvas.width)x\(SceneGenerationContract.canvas.height) pixel-art background for the app "Zaichang", a quiet shared-presence space for close people.

        STYLE LOCK
        - Warm handcrafted low-resolution pixel art with an original visual identity.
        - Crisp, deliberate pixel clusters and hard pixel edges.
        - Limited 48-64 color palette with subtle ordered dithering.
        - Warm amber practical lighting inside, balanced by cooler exterior colors.
        - Rich environmental detail without visual clutter.
        - Human-scale furniture, believable lighting and restrained emotion.
        - No smooth vector shapes, photographic texture, blur or painterly brushwork.

        CAMERA AND COMPOSITION
        - Fixed wide camera, eye-level three-quarter side view.
        - Show the entire room as one coherent environment.
        - Avoid close-ups and dramatic cinematic perspective.
        - Keep the top-left 28% by 18% visually calm and relatively dark for scene text.
        - Keep the top-right 24% by 16% clear for presence information.
        - Keep the bottom 18% free of faces and essential objects for app controls.
        - Place the main room activity around the middle third of the frame.
        - Do not render a computer window, frame, border or application UI.

        \(compositionRules)

        SCENE VARIABLES
        Scene name: \(promptValue(spec.name))
        Location: \(promptValue(spec.location))
        Time of day: \(spec.timeOfDay.promptValue)
        Weather outside: \(promptValue(spec.weather))
        Emotional atmosphere: \(spec.mood.promptValue)
        Window view: \(promptValue(spec.windowView))
        Primary lighting: \(promptValue(spec.lighting))
        Key objects, maximum three: \(keyObjects)

        PRODUCT IDENTITY
        - The room should feel suitable for quiet companionship and long viewing.
        - Include small signs of ongoing life such as an open book, warm drink, desk lamp or coat.
        - The atmosphere should feel intimate and calm without romantic cliché.
        - The image must support the interface without demanding attention.

        DYNAMIC EFFECT RULES
        Effect preset: \(spec.effectPreset.rawValue)
        - Weather may be visible through windows.
        - Do not paint full-screen rain, steam or animated particles into the image.
        - Leave rain and steam overlays to the application.

        FORBIDDEN CONTENT
        - No text, letters, numbers, logos, watermarks or signatures.
        - No UI controls, speech bubbles, icons or decorative borders.
        - No excessive bloom, lens flare, smooth gradients or depth-of-field blur.
        - No malformed furniture, duplicated limbs or inconsistent pixel scale.
        - Do not imitate any named game, artist or copyrighted character.

        OUTPUT
        - One complete 16:9 PNG scene at exactly \(SceneGenerationContract.canvas.width)x\(SceneGenerationContract.canvas.height).
        - Consistent pixel density across the entire image.
        - Clear silhouettes and readable lighting at thumbnail size.
        - Suitable for center-crop on different macOS, iOS and iPadOS window sizes.
        """

        return SceneGenerationPrompt(
            occupancy: occupancy,
            promptVersion: spec.promptVersion,
            text: text
        )
    }

    private static func promptValue(_ value: String) -> String {
        value
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
    }
}
