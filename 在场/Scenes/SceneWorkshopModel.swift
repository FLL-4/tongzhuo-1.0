import Combine
import Foundation

enum SceneWorkshopStep: Equatable {
    case describe
    case configure
    case generating
    case preview
}

protocol SceneSpecDrafting {
    func draft(from description: String) -> GeneratedSceneSpec
}

struct MockSceneSpecDrafter: SceneSpecDrafting {
    func draft(from description: String) -> GeneratedSceneSpec {
        let normalized = description
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
        let sceneID = "scene-\(UUID().uuidString.prefix(8).lowercased())"

        if normalized.contains("雪") || normalized.contains("列车") {
            return GeneratedSceneSpec(
                sceneID: sceneID,
                name: "雪夜列车",
                location: "安静的列车包厢",
                timeOfDay: .lateNight,
                weather: "窗外正在下雪",
                mood: .warm,
                windowView: "覆雪的山野和远处站台灯光",
                lighting: "暖色阅读灯",
                keyObjects: ["打开的书", "热饮", "挂起的外套"],
                ambientPreset: .quiet,
                effectPreset: .none
            )
        }

        if normalized.contains("海") || normalized.contains("沙滩") {
            return GeneratedSceneSpec(
                sceneID: sceneID,
                name: "海边工作室",
                location: "面向海面的木质工作室",
                timeOfDay: .dusk,
                weather: "晴朗微风",
                mood: .clear,
                windowView: "黄昏海面和缓慢靠岸的船",
                lighting: "夕阳与室内台灯",
                keyObjects: ["速写本", "玻璃水杯", "贝壳"],
                ambientPreset: .forest,
                effectPreset: .none
            )
        }

        if normalized.contains("雨") {
            return GeneratedSceneSpec(
                sceneID: sceneID,
                name: "雨夜阁楼",
                location: "有斜顶窗的旧阁楼书房",
                timeOfDay: .lateNight,
                weather: "持续的小雨",
                mood: .quiet,
                windowView: "雨中的屋顶与街灯",
                lighting: "低矮的暖色台灯",
                keyObjects: ["旧书", "陶瓷杯", "毛毯"],
                ambientPreset: .rain,
                effectPreset: .rain
            )
        }

        return GeneratedSceneSpec(
            sceneID: sceneID,
            name: "林间小屋",
            location: normalized.isEmpty ? "安静的林间木屋" : normalized,
            timeOfDay: .dusk,
            weather: "天气晴朗",
            mood: .warm,
            windowView: "树林与远处的山",
            lighting: "壁炉和桌面台灯",
            keyObjects: ["笔记本", "热饮", "针织外套"],
            ambientPreset: .fireplace,
            effectPreset: .steam
        )
    }
}

@MainActor
final class SceneWorkshopModel: ObservableObject {
    @Published var step: SceneWorkshopStep = .describe
    @Published var descriptionText = ""
    @Published var spec: GeneratedSceneSpec?
    @Published var keyObjectsText = ""
    @Published private(set) var job: SceneGenerationJob?
    @Published var previewOccupancy: SceneOccupancy = .together
    @Published var errorMessage: String?

    private let drafter: any SceneSpecDrafting
    private let generator: any SceneGenerating
    private var generationTask: Task<Void, Never>?

    init(
        drafter: any SceneSpecDrafting,
        generator: any SceneGenerating
    ) {
        self.drafter = drafter
        self.generator = generator
    }

    convenience init(generator: any SceneGenerating) {
        self.init(drafter: MockSceneSpecDrafter(), generator: generator)
    }

    convenience init() {
        self.init(drafter: MockSceneSpecDrafter(), generator: MockSceneGenerator())
    }

    deinit {
        generationTask?.cancel()
    }

    var canDraft: Bool {
        descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).count >= 4
    }

    var result: SceneGenerationResult? {
        guard case let .ready(result) = job?.state else { return nil }
        return result
    }

    var generationStatusTitle: String {
        guard let state = job?.state else { return "准备场景" }
        return switch state {
        case .queued: "整理场景描述"
        case .generating(.together): "绘制同桌场景"
        case .generating(.solo): "绘制独处场景"
        case .reviewing: "检查构图与安全区域"
        case .repairing: "修正没有通过的细节"
        case .ready: "场景已经准备好"
        case .failed: "生成没有完成"
        }
    }

    func draftSpec() {
        guard canDraft else {
            errorMessage = "再多写一点想去的地方。"
            return
        }
        let draft = drafter.draft(from: descriptionText)
        spec = draft
        keyObjectsText = draft.keyObjects.joined(separator: "、")
        errorMessage = nil
        step = .configure
    }

    func generate() {
        guard var spec else { return }
        spec.keyObjects = parsedKeyObjects
        self.spec = spec

        let request: SceneGenerationRequest
        do {
            request = try SceneGenerationRequest(spec: spec)
        } catch {
            errorMessage = validationMessage(for: error)
            return
        }

        generationTask?.cancel()
        errorMessage = nil
        previewOccupancy = .together
        job = SceneGenerationJob(request: request, state: .queued)
        step = .generating

        generationTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let result = try await generator.generate(request) { [weak self] state in
                    guard let self, self.job?.request.id == request.id else { return }
                    self.job?.state = state
                }
                guard !Task.isCancelled, job?.request.id == request.id else { return }
                job?.state = .ready(result)
                step = .preview
            } catch is CancellationError {
                return
            } catch {
                guard job?.request.id == request.id else { return }
                let message = "场景暂时没有生成，请再试一次。"
                job?.state = .failed(message: message)
                errorMessage = message
                step = .configure
            }
        }
    }

    func returnToDescription() {
        generationTask?.cancel()
        errorMessage = nil
        step = .describe
    }

    func adjustAndRedraw() {
        generationTask?.cancel()
        errorMessage = nil
        step = .configure
    }

    func cancelGeneration() {
        generationTask?.cancel()
        generationTask = nil
    }

    func generatedScene() -> RoomScene? {
        guard let spec, let result, result.review.isApproved else { return nil }
        return RoomScene(
            id: spec.sceneID,
            origin: .generated,
            name: spec.name,
            eyebrow: "\(spec.timeOfDay.displayName) · \(spec.weather)",
            headline: "在\(spec.name)慢慢待一会儿",
            images: SceneImageSet(
                together: SceneImageAsset(
                    relativePath: result.images.together.relativePath,
                    metadata: result.images.together.metadata
                ),
                solo: SceneImageAsset(
                    relativePath: result.images.solo.relativePath,
                    metadata: result.images.solo.metadata
                )
            ),
            ambientPreset: spec.ambientPreset,
            weatherEffect: spec.effectPreset.weatherEffect,
            atmosphericEffect: spec.effectPreset.atmosphericEffect,
            promptVersion: spec.promptVersion
        )
    }

    private var parsedKeyObjects: [String] {
        keyObjectsText
            .components(separatedBy: CharacterSet(charactersIn: "、,，"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func validationMessage(for error: Error) -> String {
        switch error as? SceneSpecValidationError {
        case .tooManyKeyObjects:
            "关键物件最多保留三个。"
        case .missingName:
            "给场景起一个名字。"
        case .missingLocation:
            "补充一下场景所在的地方。"
        default:
            "场景信息还不完整。"
        }
    }
}
