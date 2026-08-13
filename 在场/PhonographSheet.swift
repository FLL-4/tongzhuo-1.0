import SwiftUI

struct PhonographSheet: View {
    @ObservedObject var model: AppModel
    @ObservedObject var memory: MemoryController
    @ObservedObject var recorder: VoiceRecorderController
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var observation = ""
    @State private var keyMoment = ""
    @State private var mood: MemoryMood = .warm
    @State private var selectedTemplateID: String?

    var body: some View {
        SheetContainer(eyebrow: "留声机", title: "把这一刻留下来", dismiss: dismiss, maxWidth: 600) {
            VStack(alignment: .leading, spacing: 16) {
                if let draft = memory.drafts.first {
                    draftContent(draft)
        } else if let card = memory.cards.first {
            savedCard(card)
        } else {
                    draftEditor(
                        title: $title,
                        observation: $observation,
                        keyMoment: $keyMoment,
                        mood: $mood,
                        submitTitle: "开始整理",
                        submitDisabled: observation.trimmed.isEmpty,
                        submitAction: {
                            memory.makeDraft(
                                title: title.isEmpty ? "未命名的一刻" : title,
                                mood: mood,
                                observation: observation,
                                keyMoment: keyMoment,
                                delivery: .activityEnd,
                                sourceEvent: .manual,
                                creatorName: "我",
                                participantNames: [],
                                visibility: .shared
                            )
                        }
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func draftContent(_ draft: MemoryDraft) -> some View {
        switch draft.reviewState {
        case .draft:
            VStack(alignment: .leading, spacing: 12) {
                stepLabel("1 / 3", "检查记忆草稿")
                draftEditor(
                    title: binding(for: draft, keyPath: \.title),
                    observation: binding(for: draft, keyPath: \.observation),
                    keyMoment: binding(for: draft, keyPath: \.keyMoment),
                    mood: binding(for: draft, keyPath: \.mood),
                    submitTitle: "生成卡片选项",
                    submitDisabled: draft.observation.trimmed.isEmpty,
                    submitAction: { memory.prepareCard(for: draft) },
                    footer: {
                        voiceAttachmentPanel(for: draft)
                    }
                )
            }
        case .generating:
            VStack(alignment: .leading, spacing: 12) {
                stepLabel("2 / 3", "准备卡片选项")
                ProgressView().tint(Palette.amber)
                Text("正在从本地卡片池准备可选样式…")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.muted)
                Button("返回修改") { memory.cancelPreparation(for: draft) }
                    .buttonStyle(.bordered)
            }
        case .ready:
            cardSelection(draft)
        case .failed(let reason):
            VStack(alignment: .leading, spacing: 12) {
                stepLabel("2 / 3", "卡片准备失败")
                Text(reason)
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.muted)
                Button {
                    memory.prepareCard(for: draft, preferredTemplateID: draft.imageTemplateID)
                } label: {
                    Label("重试", systemImage: "arrow.clockwise")
                        .adaptiveFullWidthHitTarget(minHeight: 40)
                }
                .buttonStyle(.borderedProminent)
            }
        case .confirmed:
            savedCard(draft)
        }
    }

    private func draftEditor(
        title: Binding<String>,
        observation: Binding<String>,
        keyMoment: Binding<String>,
        mood: Binding<MemoryMood>,
        submitTitle: String,
        submitDisabled: Bool,
        submitAction: @escaping () -> Void,
        @ViewBuilder footer: () -> some View = { EmptyView() }
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("先写下事实和细节，留声机会帮你整理成一张卡片。")
                .font(.system(size: 12))
                .foregroundStyle(Palette.muted)
            TextField("这段记忆的标题", text: title)
                .textFieldStyle(.roundedBorder)
            TextField("发生了什么？", text: observation, axis: .vertical)
                .lineLimit(3...5)
                .textFieldStyle(.roundedBorder)
            TextField("最想记住哪一秒？", text: keyMoment, axis: .vertical)
                .lineLimit(2...3)
                .textFieldStyle(.roundedBorder)
            moodPicker(selection: mood)
            footer()
            Button(action: submitAction) {
                Label(submitTitle, systemImage: "arrow.right")
                    .adaptiveFullWidthHitTarget(minHeight: 40)
            }
            .buttonStyle(.borderedProminent)
            .disabled(submitDisabled)
        }
    }

    private func voiceAttachmentPanel(for draft: MemoryDraft) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("语音附件")
                .font(.system(size: 12, weight: .semibold))
            if let voice = draft.voiceAttachment {
                Text("已附加 \(String(format: "%.0f", voice.duration)) 秒语音")
                    .font(.system(size: 10))
                    .foregroundStyle(Palette.muted)
                Button {
                    if let note = recorder.savedNotes.first(where: { $0.id == voice.noteID }) {
                        recorder.togglePlayback(note)
                    }
                } label: {
                    Label("播放语音", systemImage: recorder.isPlaying ? "pause.fill" : "play.fill")
                        .adaptiveFullWidthHitTarget(minHeight: 36)
                }
                .buttonStyle(.bordered)
                .disabled(!recorder.savedNotes.contains(where: { $0.id == voice.noteID }))
            } else {
                Text("可以先录一段语音，再继续整理。")
                    .font(.system(size: 10))
                    .foregroundStyle(Palette.muted)
                VoiceRecorderPanel(recorder: recorder) {
                    if let note = recorder.saveDraft() {
                        memory.attachVoiceAttachment(
                            noteID: note.id,
                            filename: note.filename,
                            duration: note.duration,
                            createdAt: note.createdAt,
                            delivery: note.delivery
                        )
                        model.showToast("语音已保存，继续整理为记忆卡片")
                    }
                }
            }
        }
        .padding(10)
        .background(Palette.surface2, in: RoundedRectangle(cornerRadius: 8))
    }

    private func cardSelection(_ draft: MemoryDraft) -> some View {
        let templates = MemoryCardTemplatePool().previewTemplates(for: MemoryDraftingResult(draft: draft), limit: 6)
        return VStack(alignment: .leading, spacing: 12) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    stepLabel("2 / 3", "选择卡片样式")
                    Text("选择一张最贴近这一刻的卡片。内容会沿用上一步确认的事实。")
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.muted)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible())], spacing: 14) {
                        ForEach(templates) { template in
                            cardTile(template, draft: draft, selected: template.id == draft.imageTemplateID || template.id == selectedTemplateID)
                        }
                    }
                    selectedInfo(draft, template: templates.first { $0.id == (selectedTemplateID ?? draft.imageTemplateID) })
                    stepLabel("3 / 3", "确认并保存")
                    Text("默认会在活动结束后送达。需要改时间时，先保存再从记忆里调整。")
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.muted)
                }
                .padding(.bottom, 16)
            }
            Divider().overlay(Palette.line)
            HStack(spacing: 12) {
                Button {
                    var back = draft
                    back.reviewState = .draft
                    memory.updateDraft(back)
                    selectedTemplateID = nil
                } label: {
                    Label("返回上一步", systemImage: "arrow.left")
                        .adaptiveFullWidthHitTarget(minHeight: 44)
                }
                .buttonStyle(.bordered)

                Button {
                    var chosen = draft
                    chosen.imageTemplateID = selectedTemplateID ?? draft.imageTemplateID
                    chosen.imageTemplateName = MemoryCardTemplatePool().template(id: chosen.imageTemplateID)?.name
                    chosen.deliveryPlan = .activityEnd
                    memory.confirm(chosen)
                    dismiss()
                } label: {
                    Label("确认并保存", systemImage: "checkmark.circle.fill")
                        .adaptiveFullWidthHitTarget(minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .disabled((selectedTemplateID ?? draft.imageTemplateID) == nil)
            }
        }
        .frame(height: 500)
    }

    private func cardTile(_ template: MemoryCardTemplate, draft: MemoryDraft, selected: Bool) -> some View {
        Button {
            selectedTemplateID = template.id
            var chosen = draft
            chosen.imageTemplateID = template.id
            chosen.imageTemplateName = template.name
            memory.updateDraft(chosen)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                artwork(template)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(2 / 3, contentMode: .fit)
                Text(template.name)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                Text(template.subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(Palette.muted)
                    .lineLimit(2)
            }
            .padding(8)
            .background(selected ? Palette.amber.opacity(0.14) : Palette.surface2, in: RoundedRectangle(cornerRadius: 7))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(selected ? Palette.amber : Palette.line, lineWidth: selected ? 2 : 1))
        }
        .buttonStyle(.plain)
    }

    private func artwork(_ template: MemoryCardTemplate) -> some View {
        Group {
            if let art = MemoryCardArtwork.image(for: template.assetName) {
                art.resizable().scaledToFit()
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(template.surfaceColor)
                    .overlay(Image(systemName: template.symbol))
            }
        }
    }

    private func selectedInfo(_ draft: MemoryDraft, template: MemoryCardTemplate?) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("已选择：\(template?.name ?? draft.imageTemplateName ?? "请选择一张卡片")")
                .font(.system(size: 12, weight: .semibold))
            Text("标签：\((template?.tags ?? draft.suggestedTags).joined(separator: " · "))")
                .font(.system(size: 10))
                .foregroundStyle(Palette.muted)
            Text("来源：\(draft.sourceEvent.rawValue) · 创建者：\(draft.creatorName)")
                .font(.system(size: 10))
                .foregroundStyle(Palette.muted)
            if let voice = draft.voiceAttachment {
                let durationText = String(format: "%.0f", voice.duration)
                Text("语音附件：\(durationText) 秒")
                    .font(.system(size: 10))
                    .foregroundStyle(Palette.muted)
            }
            if let confirmedAt = draft.confirmedAt {
                Text("确认时间：\(confirmedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.system(size: 10))
                    .foregroundStyle(Palette.muted)
            }
        }
    }

    private func savedCard(_ card: MemoryDraft) -> some View {
        let template = MemoryCardTemplatePool().template(id: card.imageTemplateID)
        return VStack(alignment: .leading, spacing: 12) {
            stepLabel("3 / 3", "确认送达")
            if let template {
                artwork(template)
                    .frame(maxWidth: .infinity)
                    .frame(height: 240)
            }
            Text(card.title)
                .font(.system(size: 16, weight: .semibold))
            Text(card.observation)
                .font(.system(size: 12))
            Text("送达：\(card.deliveryPlan.title) · \(deliveryLabel(card.deliveryState))")
                .font(.system(size: 11))
                .foregroundStyle(Palette.muted)
            Text("来源：\(card.sourceEvent.rawValue) · 创建者：\(card.creatorName) · \(card.visibility.rawValue)")
                .font(.system(size: 10))
                .foregroundStyle(Palette.muted)
            if let voice = card.voiceAttachment {
                let durationText = String(format: "%.0f", voice.duration)
                Button {
                    if let note = recorder.savedNotes.first(where: { $0.id == voice.noteID }) {
                        recorder.togglePlayback(note)
                    }
                } label: {
                    Label("播放语音附件 \(durationText) 秒", systemImage: "play.circle")
                        .adaptiveFullWidthHitTarget(minHeight: 34)
                }
                .buttonStyle(.bordered)
                .disabled(!recorder.savedNotes.contains(where: { $0.id == voice.noteID }))
            }
            HStack {
                Button("推进送达") { memory.advanceDeliveryState(for: card) }
                    .buttonStyle(.bordered)
            }
        }
    }

    private func moodPicker(selection: Binding<MemoryMood>) -> some View {
        Picker("心情", selection: selection) {
            ForEach(MemoryMood.selectableCases) { Text($0.title).tag($0) }
        }
        .pickerStyle(.segmented)
    }

    private func stepLabel(_ step: String, _ title: String) -> some View {
        Label("步骤 \(step) · \(title)", systemImage: "recordingtape")
            .font(.system(size: 12, weight: .semibold))
    }

    private func binding<T>(for draft: MemoryDraft, keyPath: WritableKeyPath<MemoryDraft, T>) -> Binding<T> {
        Binding(
            get: { draft[keyPath: keyPath] },
            set: { value in
                var copy = draft
                copy[keyPath: keyPath] = value
                memory.updateDraft(copy)
            }
        )
    }

    private func deliveryLabel(_ state: MemoryDeliveryState) -> String {
        switch state {
        case .notScheduled: "仅保存"
        case .scheduled: "待送达"
        case .delivered: "已送达"
        case .opened: "已打开"
        case .failed: "送达失败"
        }
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
