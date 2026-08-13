import Foundation
import Testing
@testable import 在场

@Suite("Phonograph")
@MainActor
struct PhonographTests {

    @Test("Interrupted generation is recovered on launch")
    func interruptedGenerationIsRecoveredOnLaunch() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("phonograph-recovery-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: fileURL) }
        let persistence = MemoryPersistence(fileURL: fileURL)
        let interrupted = MemoryDraft(
            id: UUID(), sourceActivityID: nil, sourceEvent: .manual, creatorName: "我",
            participantNames: [], visibility: .shared, resourceReferences: [],
            voiceAttachment: nil,
            confirmedAt: nil, deletedAt: nil, title: "中断的留声", mood: .quiet,
            observation: "生成过程中退出了应用", keyMoment: "重新打开时",
            imagePrompt: nil,
            reviewState: .generating, deliveryPlan: .oneHourLater,
            deliveryState: .notScheduled, imageData: nil,
            createdAt: Date()
        )
        try persistence.save(drafts: [interrupted], cards: [])

        let controller = MemoryController(
            imageGenerator: PhonographImmediateImageGenerator(),
            persistence: persistence
        )

        #expect(controller.drafts.first?.reviewState == .draft)
        #expect(persistence.load().drafts.first?.reviewState == .draft)
    }

    @Test("Draft generation stores prompt and image")
    func memoryDraftCarriesMockGenerationArtifacts() async throws {
        let controller = MemoryController(imageGenerator: PhonographImmediateImageGenerator(), persistence: testPersistence())

        controller.makeDraft(
            title: "雨夜书桌",
            mood: .quiet,
            observation: "今晚在台灯下把代码整理完了，窗外一直在下雨。",
            keyMoment: "窗边的雨声和桌面那盏灯",
            delivery: .oneHourLater
        )

        let draft = try #require(controller.drafts.first)
        controller.generateImage(for: draft)

        try await Task.sleep(for: .milliseconds(40))

        let ready = try #require(controller.drafts.first)
        #expect(ready.reviewState == .ready)
        #expect(ready.imagePrompt?.isEmpty == false)
        #expect(ready.imageData != nil)
    }

    @Test("Confirmed card tracks delivery lifecycle")
    func confirmedCardTracksDeliveryLifecycle() async throws {
        let controller = MemoryController(imageGenerator: PhonographImmediateImageGenerator(), persistence: testPersistence())

        controller.makeDraft(
            title: "列车回声",
            mood: .tender,
            observation: "从车站回来的路上，想把那句没说完的话留住。",
            keyMoment: "车窗里的灯光",
            delivery: .bedtime
        )

        let draft = try #require(controller.drafts.first)
        controller.generateImage(for: draft)
        try await Task.sleep(for: .milliseconds(40))

        controller.attachVoiceAttachment(
            noteID: UUID(),
            filename: "test.m4a",
            duration: 3,
            createdAt: Date(),
            delivery: .focusEnd
        )
        let ready = try #require(controller.drafts.first)
        controller.confirm(ready)

        let card = try #require(controller.cards.first)
        #expect(card.reviewState == .confirmed)
        #expect(card.deliveryState == .scheduled)

        controller.markDelivered(card)
        let delivered = try #require(controller.cards.first)
        #expect(delivered.deliveryState == .delivered)

        controller.markOpened(delivered)
        let opened = try #require(controller.cards.first)
        #expect(opened.deliveryState == .opened)
    }

    @Test("Delivery plan sync reflects strategy")
    func deliveryPlanSyncReflectsStrategy() async throws {
        let controller = MemoryController(imageGenerator: PhonographImmediateImageGenerator(), persistence: testPersistence())

        controller.makeDraft(
            title: "午后小停顿",
            mood: .bright,
            observation: "杯子放下的时候，桌面终于安静了一点。",
            keyMoment: "放下水杯的那一秒",
            delivery: .bedtime
        )

        let draft = try #require(controller.drafts.first)
        controller.generateImage(for: draft)
        try await Task.sleep(for: .milliseconds(40))

        controller.attachVoiceAttachment(
            noteID: UUID(),
            filename: "test.m4a",
            duration: 3,
            createdAt: Date(),
            delivery: .focusEnd
        )
        let ready = try #require(controller.drafts.first)
        controller.confirm(ready)

        let card = try #require(controller.cards.first)
        #expect(card.deliveryState == .scheduled)

        controller.syncDeliveryState(for: card)
        let synced = try #require(controller.cards.first)
        #expect(synced.deliveryState == .delivered)
    }

    @Test("Memory view source should only expose confirmed cards")
    func memorySourceShouldOnlyExposeConfirmedCards() async throws {
        let controller = MemoryController(imageGenerator: PhonographImmediateImageGenerator(), persistence: testPersistence())

        controller.makeDraft(
            title: "雨夜书桌",
            mood: .quiet,
            observation: "台灯和雨声一起落下来。",
            keyMoment: "雨打在窗上那一刻",
            delivery: .oneHourLater
        )

        let draft = try #require(controller.drafts.first)
        controller.generateImage(for: draft)
        try await Task.sleep(for: .milliseconds(40))

        let ready = try #require(controller.drafts.first)
        controller.confirm(ready)

        #expect(controller.cards.allSatisfy { $0.reviewState == .confirmed })
    }
}

private func testPersistence() -> MemoryPersistence {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("phonograph-test-\(UUID().uuidString).json")
    return MemoryPersistence(fileURL: url)
}

private struct PhonographImmediateImageGenerator: MemoryImageGenerating {
    func generate(prompt: String) async throws -> Data {
        Data([0x89, 0x50, 0x4E, 0x47])
    }
}
