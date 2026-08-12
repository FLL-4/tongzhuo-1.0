import SwiftUI
#if !os(macOS)
import UIKit
#endif

struct MemorySheet: View {
    @ObservedObject var memory: MemoryController
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var observation = ""
    @State private var keyMoment = ""
    @State private var mood: MemoryMood = .warm
    @State private var delivery: MemoryDeliveryPlan = .activityEnd
    @State private var submitted = false

    var body: some View {
        SheetContainer(eyebrow: "留声机", title: "把这一刻留下来", dismiss: dismiss) {
            if let draft = memory.drafts.first {
                if draft.reviewState == .ready { cardView(draft) } else { draftFlow(draft) }
            } else if let card = memory.cards.first {
                cardView(card)
            } else {
                inputForm
            }
        }
    }

    private var inputForm: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("记录文字、心情和事件记忆点").font(.system(size: 12, weight: .semibold))
            TextField("标题，例如：雨夜书桌", text: $title).textFieldStyle(.roundedBorder)
            Picker("心情", selection: $mood) { ForEach(MemoryMood.allCases) { Text($0.title).tag($0) } }.pickerStyle(.segmented)
            TextField("见闻：这一段发生了什么？", text: $observation, axis: .vertical).lineLimit(3...5).textFieldStyle(.roundedBorder)
            TextField("关键时刻：最想记住哪一秒？", text: $keyMoment, axis: .vertical).lineLimit(2...4).textFieldStyle(.roundedBorder)
            Button { memory.makeDraft(title: title.isEmpty ? "未命名的一刻" : title, mood: mood, observation: observation, keyMoment: keyMoment, delivery: delivery) } label: {
                Label("整理成记忆草稿", systemImage: "wand.and.stars").adaptiveFullWidthHitTarget(minHeight: 42)
            }.buttonStyle(.borderedProminent).disabled(observation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private func draftFlow(_ draft: MemoryDraft) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("步骤 1 / 3 · AI 整理草稿", systemImage: "doc.text.magnifyingglass").font(.system(size: 12, weight: .semibold))
            TextField("标题", text: Binding(get: { draft.title }, set: { var x = draft; x.title = $0; memory.updateDraft(x) })).textFieldStyle(.roundedBorder)
            Text("心情：\(draft.mood.title)").foregroundStyle(Palette.muted)
            Text(draft.observation).font(.system(size: 12))
            Text("关键时刻：\(draft.keyMoment)").font(.system(size: 11)).foregroundStyle(Palette.muted)
            Button { memory.generateImage(for: draft) } label: { Label("确认草稿并生成图像", systemImage: "photo.artframe").adaptiveFullWidthHitTarget(minHeight: 42) }.buttonStyle(.borderedProminent).disabled(draft.observation.isEmpty || draft.reviewState == .generating)
            if case .generating = draft.reviewState { ProgressView("正在生成统一风格图像…") }
            if case let .failed(message) = draft.reviewState { Text(message).foregroundStyle(.red); Button("重试") { memory.generateImage(for: draft) } }
            Button("重新记录") { memory.discardDraft(draft) }.buttonStyle(.bordered)
        }
    }

    private func cardView(_ card: MemoryDraft) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("步骤 2 / 3 · 记忆卡片已准备", systemImage: "checkmark.seal").font(.system(size: 12, weight: .semibold))
            if let data = card.imageData {
                #if os(macOS)
                if let image = NSImage(data: data) { Image(nsImage: image).resizable().scaledToFit().frame(maxHeight: 220) }
                #else
                if let image = UIImage(data: data) { Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 220) }
                #endif
            }
            Text(card.title).font(.system(size: 18, weight: .semibold))
            Text(card.observation).font(.system(size: 12))
            Text("步骤 3 / 3 · 选择送达策略").font(.system(size: 12, weight: .semibold))
            ForEach(MemoryDeliveryPlan.allCases) { plan in Button { var x = card; x.deliveryPlan = plan; x.deliveryState = plan == .archiveOnly ? .notScheduled : .scheduled; memory.updateCard(x) } label: { Label(plan.title, systemImage: card.deliveryPlan == plan ? "checkmark.circle.fill" : "circle").adaptiveFullWidthHitTarget(minHeight: 34) }.buttonStyle(ZaichangPlainButtonStyle()) }
            Button { memory.confirm(card); dismiss() } label: { Label(card.deliveryPlan == .archiveOnly ? "确认并保存到回忆" : "确认并进入待送达", systemImage: "paperplane").adaptiveFullWidthHitTarget(minHeight: 42) }.buttonStyle(.borderedProminent)
        }
    }
}
