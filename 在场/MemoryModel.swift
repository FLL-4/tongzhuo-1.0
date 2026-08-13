import Foundation
import Combine

enum MemoryMood: String, CaseIterable, Codable, Identifiable {
    case warm, quiet, bright, tender
    var id: String { rawValue }
    static var selectableCases: [MemoryMood] { [.warm, .quiet, .bright] }
    var title: String {
        switch self {
        case .warm: "温暖"
        case .quiet: "安静"
        case .bright: "明亮"
        case .tender: "柔软"
        }
    }
}

enum MemoryReviewState: Equatable, Codable {
    case draft, generating, ready, confirmed, failed(String)
}

enum MemoryGenerationState: Equatable { case idle, generating }

enum MemoryDeliveryState: Equatable, Codable {
    case notScheduled, scheduled, delivered, opened, failed(String)
}

enum MemorySourceEvent: String, CaseIterable, Codable, Identifiable {
    case manual
    case activityEnded
    case dailyTodoCompleted

    var id: String { rawValue }
}

enum MemoryVisibility: String, CaseIterable, Codable, Identifiable {
    case shared
    case privateOnly

    var id: String { rawValue }
}

struct MemoryResourceReference: Identifiable, Equatable, Codable {
    let id: UUID
    var kind: String
    var value: String

    init(id: UUID = UUID(), kind: String, value: String) {
        self.id = id
        self.kind = kind
        self.value = value
    }
}

struct MemoryVoiceAttachment: Identifiable, Equatable, Codable {
    let id: UUID
    var noteID: UUID
    var filename: String
    var duration: TimeInterval
    var createdAt: Date
    var delivery: VoiceDelivery

    init(
        id: UUID = UUID(),
        noteID: UUID,
        filename: String,
        duration: TimeInterval,
        createdAt: Date,
        delivery: VoiceDelivery
    ) {
        self.id = id
        self.noteID = noteID
        self.filename = filename
        self.duration = duration
        self.createdAt = createdAt
        self.delivery = delivery
    }
}

enum MemoryDeliveryPlan: String, CaseIterable, Codable, Identifiable {
    case oneHourLater, dailyTodoCompleted, bedtime
    var id: String { rawValue }
    var title: String {
        switch self {
        case .oneHourLater: "1 小时后"
        case .dailyTodoCompleted: "今日所有事项完成后"
        case .bedtime: "今晚睡前"
        }
    }
    var detail: String {
        switch self {
        case .oneHourLater: "适合不打扰当下的一小段延迟。"
        case .dailyTodoCompleted: "等今天放在桌上的事都完成后送达。"
        case .bedtime: "留到夜里安静的时候再打开。"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value {
        case "activityEnd", "nextFocusEnd":
            self = .oneHourLater
        case "scheduled":
            self = .bedtime
        default:
            self = MemoryDeliveryPlan(rawValue: value) ?? .oneHourLater
        }
    }
}

struct MemoryDraft: Identifiable, Equatable, Codable {
    let id: UUID
    var sourceActivityID: UUID?
    var sourceEvent: MemorySourceEvent
    var creatorName: String
    var participantNames: [String]
    var visibility: MemoryVisibility
    var resourceReferences: [MemoryResourceReference]
    var voiceAttachment: MemoryVoiceAttachment?
    var confirmedAt: Date?
    var deletedAt: Date?
    var title: String
    var mood: MemoryMood
    var observation: String
    var keyMoment: String
    var imagePrompt: String?
    var reviewState: MemoryReviewState
    var deliveryPlan: MemoryDeliveryPlan
    var deliveryState: MemoryDeliveryState
    var imageData: Data?
    var createdAt: Date
}

extension MemoryDraft {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        sourceActivityID = try c.decodeIfPresent(UUID.self, forKey: .sourceActivityID)
        sourceEvent = try c.decodeIfPresent(MemorySourceEvent.self, forKey: .sourceEvent) ?? .manual
        creatorName = try c.decodeIfPresent(String.self, forKey: .creatorName) ?? "我"
        participantNames = try c.decodeIfPresent([String].self, forKey: .participantNames) ?? []
        visibility = try c.decodeIfPresent(MemoryVisibility.self, forKey: .visibility) ?? .shared
        resourceReferences = try c.decodeIfPresent([MemoryResourceReference].self, forKey: .resourceReferences) ?? []
        voiceAttachment = try c.decodeIfPresent(MemoryVoiceAttachment.self, forKey: .voiceAttachment)
        confirmedAt = try c.decodeIfPresent(Date.self, forKey: .confirmedAt)
        deletedAt = try c.decodeIfPresent(Date.self, forKey: .deletedAt)
        title = try c.decode(String.self, forKey: .title)
        mood = try c.decode(MemoryMood.self, forKey: .mood)
        observation = try c.decode(String.self, forKey: .observation)
        keyMoment = try c.decode(String.self, forKey: .keyMoment)
        imagePrompt = try c.decodeIfPresent(String.self, forKey: .imagePrompt)
        reviewState = try c.decode(MemoryReviewState.self, forKey: .reviewState)
        deliveryPlan = try c.decode(MemoryDeliveryPlan.self, forKey: .deliveryPlan)
        deliveryState = try c.decode(MemoryDeliveryState.self, forKey: .deliveryState)
        imageData = try c.decodeIfPresent(Data.self, forKey: .imageData)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
    }
    private enum CodingKeys: String, CodingKey {
        case id, sourceActivityID, sourceEvent, creatorName, participantNames, visibility,
             resourceReferences, confirmedAt, deletedAt, title, mood, observation, keyMoment,
             imagePrompt, voiceAttachment, reviewState, deliveryPlan, deliveryState, imageData,
             createdAt
    }
}

protocol MemoryImageGenerating { func generate(prompt: String) async throws -> Data }

struct MockMemoryImageGenerator: MemoryImageGenerating {
    func generate(prompt: String) async throws -> Data {
        try await Task.sleep(for: .milliseconds(120))
        return Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=")!
    }
}

struct HybridMemoryImageGenerator: MemoryImageGenerating {
    private let configuration: APIConfiguration
    private let mock = MockMemoryImageGenerator()

    init(configuration: APIConfiguration = .load()) {
        self.configuration = configuration
    }

    func generate(prompt: String) async throws -> Data {
        guard configuration.isMemoryImageGenerationConfigured else {
            return try await mock.generate(prompt: prompt)
        }
        return try await RemoteMemoryImageGenerator(configuration: configuration).generate(prompt: prompt)
    }
}

private struct RemoteMemoryImageGenerator: MemoryImageGenerating {
    let configuration: APIConfiguration

    func generate(prompt: String) async throws -> Data {
        switch configuration.image.provider {
        case .dashScope:
            return try await generateDashScope(prompt: prompt)
        case .openAI:
            return try await generateOpenAI(prompt: prompt)
        }
    }

    private func generateDashScope(prompt: String) async throws -> Data {
        let payload = MemoryDashScopeImageRequest(
            model: configuration.image.sceneModel.isEmpty ? configuration.image.model : configuration.image.sceneModel,
            input: .init(messages: [.init(role: "user", content: [.text(prompt)])]),
            parameters: .init(
                count: 1,
                watermark: false,
                promptExtend: false,
                size: configuration.image.size.replacingOccurrences(of: "x", with: "*")
            )
        )
        var request = URLRequest(url: try endpointURL(configuration.image.endpoint))
        request.httpMethod = "POST"
        request.timeoutInterval = 180
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(configuration.image.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(payload)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)
        guard let image = try await extractImage(from: data) else { throw MemoryImageGenerationError.invalidResponse }
        return image
    }

    private func generateOpenAI(prompt: String) async throws -> Data {
        let endpoint = configuration.image.baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/images/generations"
        let payload = MemoryOpenAIImageRequest(
            model: configuration.image.model,
            prompt: prompt,
            size: configuration.image.size,
            responseFormat: "b64_json"
        )
        var request = URLRequest(url: try endpointURL(endpoint))
        request.httpMethod = "POST"
        request.timeoutInterval = 180
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(configuration.image.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(payload)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)
        guard let image = try await extractImage(from: data) else { throw MemoryImageGenerationError.invalidResponse }
        return image
    }

    private func endpointURL(_ value: String) throws -> URL {
        guard let url = URL(string: value), url.scheme == "https" || url.scheme == "http" else {
            throw MemoryImageGenerationError.invalidEndpoint
        }
        return url
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw MemoryImageGenerationError.remote(String(data: data, encoding: .utf8) ?? "图像接口请求失败")
        }
    }

    private func extractImage(from data: Data) async throws -> Data? {
        let object = try JSONSerialization.jsonObject(with: data)
        if let base64 = findString(in: object, keys: ["b64_json", "base64", "image_base64"]) {
            return Data(base64Encoded: base64)
        }
        if let urlString = findString(in: object, keys: ["url", "image", "image_url"]), let url = URL(string: urlString) {
            let (downloaded, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw MemoryImageGenerationError.invalidResponse
            }
            return downloaded
        }
        return nil
    }

    private func findString(in value: Any, keys: Set<String>) -> String? {
        if let dictionary = value as? [String: Any] {
            for key in keys {
                if let value = dictionary[key] as? String, !value.isEmpty { return value }
            }
            for child in dictionary.values {
                if let found = findString(in: child, keys: keys) { return found }
            }
        } else if let array = value as? [Any] {
            for child in array {
                if let found = findString(in: child, keys: keys) { return found }
            }
        }
        return nil
    }
}

private struct MemoryDashScopeImageRequest: Encodable {
    struct Input: Encodable { let messages: [Message] }
    struct Message: Encodable { let role: String; let content: [Content] }
    enum Content: Encodable {
        case text(String)
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            if case let .text(value) = self { try container.encode(value, forKey: .text) }
        }
        enum CodingKeys: String, CodingKey { case text }
    }
    struct Parameters: Encodable {
        let count: Int
        let watermark: Bool
        let promptExtend: Bool
        let size: String
        enum CodingKeys: String, CodingKey {
            case count = "n"
            case watermark
            case promptExtend = "prompt_extend"
            case size
        }
    }
    let model: String
    let input: Input
    let parameters: Parameters
}

private struct MemoryOpenAIImageRequest: Encodable {
    let model: String
    let prompt: String
    let size: String
    let responseFormat: String

    enum CodingKeys: String, CodingKey {
        case model
        case prompt
        case size
        case responseFormat = "response_format"
    }
}

private enum MemoryImageGenerationError: LocalizedError {
    case invalidEndpoint
    case invalidResponse
    case remote(String)

    var errorDescription: String? {
        switch self {
        case .invalidEndpoint: "记忆卡片图像接口地址无效。"
        case .invalidResponse: "记忆卡片图像接口没有返回可用图片。"
        case .remote(let message): "记忆卡片图像接口请求失败：\(message.prefix(180))"
        }
    }
}

@MainActor
final class MemoryController: ObservableObject {
    @Published private(set) var drafts: [MemoryDraft] = []
    @Published private(set) var cards: [MemoryDraft] = []
    @Published private(set) var generationState: MemoryGenerationState = .idle
    private let imageGenerator: any MemoryImageGenerating
    private let persistence: MemoryPersistence
    private var task: Task<Void, Never>?

    init(imageGenerator: (any MemoryImageGenerating)? = nil, persistence: MemoryPersistence? = nil) {
        self.imageGenerator = imageGenerator ?? HybridMemoryImageGenerator()
        self.persistence = persistence ?? MemoryPersistence()
        let stored = self.persistence.load()
        // Generation is an in-memory task; a persisted generating draft cannot
        // resume after relaunch, so make it reviewable again.
        var didRecoverInterruptedGeneration = false
        drafts = stored.drafts.map { draft in
            guard draft.reviewState == .generating else { return draft }
            didRecoverInterruptedGeneration = true
            var recovered = draft
            recovered.reviewState = .draft
            return recovered
        }
        cards = stored.cards
        if didRecoverInterruptedGeneration {
            try? self.persistence.save(drafts: drafts, cards: cards)
        }
    }
    deinit { task?.cancel() }

    @discardableResult
    func makeDraft(
        title: String,
        mood: MemoryMood,
        observation: String,
        keyMoment: String,
        delivery: MemoryDeliveryPlan,
        sourceEvent: MemorySourceEvent = .manual,
        sourceActivityID: UUID? = nil,
        creatorName: String = "我",
        participantNames: [String] = [],
        visibility: MemoryVisibility = .shared,
        resourceReferences: [MemoryResourceReference] = [],
        voiceAttachment: MemoryVoiceAttachment? = nil,
        confirmedAt: Date? = nil,
        deletedAt: Date? = nil
    ) -> MemoryDraft {
        let draft = MemoryDraft(
            id: UUID(),
            sourceActivityID: sourceActivityID,
            sourceEvent: sourceEvent,
            creatorName: creatorName,
            participantNames: participantNames,
            visibility: visibility,
            resourceReferences: resourceReferences,
            voiceAttachment: voiceAttachment,
            confirmedAt: confirmedAt,
            deletedAt: deletedAt,
            title: title.trimmed,
            mood: mood,
            observation: observation.trimmed,
            keyMoment: keyMoment.trimmed,
            imagePrompt: nil,
            reviewState: .draft,
            deliveryPlan: delivery,
            deliveryState: .notScheduled,
            imageData: nil,
            createdAt: Date()
        )
        drafts.insert(draft, at: 0)
        persist()
        return draft
    }

    func updateDraft(_ draft: MemoryDraft) { replace(&drafts, with: draft); persist() }
    func discardDraft(_ draft: MemoryDraft) { drafts.removeAll { $0.id == draft.id }; persist() }
    func attachVoiceAttachment(
        noteID: UUID,
        filename: String,
        duration: TimeInterval,
        createdAt: Date,
        delivery: VoiceDelivery
    ) {
        guard var draft = drafts.first else { return }
        draft.voiceAttachment = MemoryVoiceAttachment(
            noteID: noteID,
            filename: filename,
            duration: duration,
            createdAt: createdAt,
            delivery: delivery
        )
        updateDraft(draft)
    }

    func prepareCard(for draft: MemoryDraft) {
        guard draft.reviewState == .draft || draft.reviewState.isFailed else { return }
        var working = draft
        working.reviewState = .generating
        updateDraft(working)
        generationState = .generating
        task?.cancel()
        task = Task { [weak self] in
            do {
                guard let self else { return }
                let prompt = MemoryCardPromptBuilder.prompt(for: MemoryDraftingResult(title: working.title, mood: working.mood, observation: working.observation, keyMoment: working.keyMoment, date: working.createdAt))
                let data = try await self.imageGenerator.generate(prompt: prompt)
                guard !Task.isCancelled else { return }
                var ready = working
                ready.imagePrompt = prompt
                ready.imageData = data
                ready.reviewState = .ready
                self.generationState = .idle
                self.updateDraft(ready)
            } catch {
                guard let self, !Task.isCancelled else { return }
                var failed = working
                failed.reviewState = .failed(error.localizedDescription)
                self.generationState = .idle
                self.updateDraft(failed)
            }
        }
    }

    func generateImage(for draft: MemoryDraft) {
        prepareCard(for: draft)
    }

    func cancelPreparation(for draft: MemoryDraft) {
        task?.cancel()
        task = nil
        generationState = .idle
        guard draft.reviewState == .generating else { return }
        var recovered = draft
        recovered.reviewState = .draft
        updateDraft(recovered)
    }

    func confirm(_ draft: MemoryDraft) {
        guard draft.reviewState == .ready, draft.imageData != nil, draft.voiceAttachment != nil else { return }
        var card = draft
        card.reviewState = .confirmed
        card.confirmedAt = Date()
        if let voiceAttachment = card.voiceAttachment,
           !card.resourceReferences.contains(where: { $0.kind == "voiceAttachment" && $0.value == voiceAttachment.noteID.uuidString }) {
            card.resourceReferences.append(.init(kind: "voiceAttachment", value: voiceAttachment.noteID.uuidString))
        }
        card.deliveryState = deliveryState(for: card)
        cards.insert(card, at: 0)
        drafts.removeAll { $0.id == draft.id }
        persist()
    }
    func markDelivered(_ card: MemoryDraft) { updateCard(card.withDeliveryState(.delivered)) }
    func markOpened(_ card: MemoryDraft) { var x = card; x.deliveryState = .opened; updateCard(x) }
    func advanceDeliveryState(for card: MemoryDraft) {
        var x = card
        switch card.deliveryState { case .notScheduled: x.deliveryState = .scheduled; case .scheduled: x.deliveryState = .delivered; case .delivered: x.deliveryState = .opened; default: return }
        updateCard(x)
    }
    func syncDeliveryState(for card: MemoryDraft) {
        updateCard(card.withDeliveryState(.delivered))
    }
    func deliverCards(for event: MemorySourceEvent, activityID: UUID? = nil, now: Date = Date()) {
        for card in cards where card.reviewState == .confirmed {
            guard card.deliveryState == .scheduled || card.deliveryState == .notScheduled else { continue }
            switch card.deliveryPlan {
            case .oneHourLater:
                guard event == .activityEnded else { continue }
                guard activityID == nil || card.sourceActivityID == activityID || card.sourceActivityID == nil else { continue }
                var updated = card
                updated.deliveryState = .scheduled
                updateCard(updated)
            case .dailyTodoCompleted:
                guard event == .dailyTodoCompleted else { continue }
                var updated = card
                updated.deliveryState = .delivered
                updated.confirmedAt = updated.confirmedAt ?? now
                updateCard(updated)
            case .bedtime:
                continue
            }
        }
    }
    func updateCard(_ card: MemoryDraft) { replace(&cards, with: card); persist() }

    private func updateCard(_ card: MemoryDraft, review: MemoryReviewState) { var x = card; x.reviewState = review; updateCard(x) }
    private func replace(_ list: inout [MemoryDraft], with item: MemoryDraft) { list.removeAll { $0.id == item.id }; list.insert(item, at: 0) }
    private func persist() { try? persistence.save(drafts: drafts, cards: cards) }

    /// 已确认的记忆卡片，按创建时间从新到旧排列，供历史列表展示。
    var history: [MemoryDraft] {
        cards.sorted { $0.createdAt > $1.createdAt }
    }

    func deleteCard(_ card: MemoryDraft) {
        cards.removeAll { $0.id == card.id }
        persist()
    }

    private func deliveryState(for card: MemoryDraft) -> MemoryDeliveryState {
        switch card.deliveryPlan {
        case .oneHourLater:
            return .scheduled
        case .dailyTodoCompleted:
            return card.sourceEvent == .dailyTodoCompleted ? .delivered : .scheduled
        case .bedtime:
            return .scheduled
        }
    }
}

private extension String { var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) } }
private extension MemoryReviewState { var isFailed: Bool { if case .failed = self { return true }; return false } }
private extension MemoryDraft {
    func withDeliveryState(_ state: MemoryDeliveryState) -> MemoryDraft {
        var copy = self
        copy.deliveryState = state
        return copy
    }
}

struct MemoryStore: Codable { let drafts: [MemoryDraft]; let cards: [MemoryDraft] }

final class MemoryPersistence {
    private let fileURL: URL
    init(fileURL: URL) { self.fileURL = fileURL }
    init(fileManager: FileManager = .default) {
        fileURL = AppStoragePaths.memoriesURL(fileManager: fileManager)
    }
    func load() -> MemoryStore {
        guard let data = try? Data(contentsOf: fileURL), let store = try? JSONDecoder().decode(MemoryStore.self, from: data) else { return MemoryStore(drafts: [], cards: []) }
        return store
    }
    func save(drafts: [MemoryDraft], cards: [MemoryDraft]) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(MemoryStore(drafts: drafts, cards: cards)).write(to: fileURL, options: .atomic)
    }
}
