import SwiftUI

struct PhonographSheet: View {
    @ObservedObject var model: AppModel
    @ObservedObject var memory: MemoryController
    @ObservedObject var recorder: VoiceRecorderController
    @Environment(\.dismiss) private var dismiss

    @State private var flow = PhonographFlow()
    @State private var transcriptionService = SpeechTranscriptionService()

    var body: some View {
        SheetContainer(eyebrow: "留声机", title: "把声音留成一张卡", dismiss: dismiss) {
            VStack(alignment: .leading, spacing: 18) {
                stepProgress
                content
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let draft = activeDraft {
            switch draft.reviewState {
            case .draft:
                editTranscriptStep(draft)
            case .generating:
                generationStep(draft)
            case .ready:
                deliveryStep(draft)
            case .failed(let reason):
                generationFailureStep(draft, reason: reason)
            case .confirmed:
                recordingStep
            }
        } else {
            recordingStep
        }
    }

    private var stepProgress: some View {
        HStack(spacing: 8) {
            ForEach(PhonographStep.allCases) { step in
                HStack(spacing: 6) {
                    Circle()
                        .fill(step.rawValue <= currentStep.rawValue ? Palette.amber : Palette.surface3)
                        .frame(width: 8, height: 8)
                    Text(step.title)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(step == currentStep ? Palette.ink : Palette.muted)
                }
                if step != PhonographStep.allCases.last {
                    Rectangle()
                        .fill(Palette.line)
                        .frame(height: 1)
                }
            }
        }
    }

    private var currentStep: PhonographStep {
        guard let draft = activeDraft else { return .record }
        switch draft.reviewState {
        case .draft: return .editText
        case .generating, .failed: return .generateCard
        case .ready, .confirmed: return .delivery
        }
    }

    private var activeDraft: MemoryDraft? {
        guard let draftID = flow.activeDraftID else { return nil }
        return memory.drafts.first { $0.id == draftID }
    }

    private var recordingStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepLabel("1 / 4", "先录一段声音")
            Text("这一版留声机只从录音开始。录音会和最终卡片绑定保存。")
                .font(.system(size: 12))
                .foregroundStyle(Palette.muted)

            if let pendingDraft = memory.drafts.first, flow.activeDraftID == nil {
                unfinishedDraftBanner(for: pendingDraft)
            }

            VoiceRecorderPanel(recorder: recorder) {
                guard let note = recorder.saveDraft(delivery: .focusEnd) else { return }
                flow.voiceNote = note
                Task { await transcribe(note) }
            }
            .padding(16)
            .background(Palette.surface2, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            switch flow.transcriptionState {
            case .idle:
                EmptyView()
            case .running:
                HStack(spacing: 10) {
                    ProgressView().controlSize(.small).tint(Palette.amber)
                    Text("正在识别录音文字…")
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.muted)
                }
            case .failed(let message):
                VStack(alignment: .leading, spacing: 8) {
                    Text(message)
                        .font(.system(size: 12))
                        .foregroundStyle(Color(red: 0.92, green: 0.52, blue: 0.46))
                    Button("手动输入识别文字") {
                        createDraft(from: flow.voiceNote, transcript: "")
                    }
                    .buttonStyle(.bordered)
                    .disabled(flow.voiceNote == nil)
                }
            }
        }
    }

    private func unfinishedDraftBanner(for draft: MemoryDraft) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "doc.text.below.ecg")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Palette.amberSoft)
                Text("有一条未完成留声")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
            }
            Text("可以继续上次进度，也可以直接录一段新的。")
                .font(.system(size: 11))
                .foregroundStyle(Palette.muted)
            Button("继续上次留声") {
                flow.activeDraftID = draft.id
            }
            .buttonStyle(.bordered)
        }
        .padding(12)
        .background(Palette.surface3, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Palette.line))
    }

    private func editTranscriptStep(_ draft: MemoryDraft) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            stepLabel("2 / 4", "修正识别文字")
            Text("系统已把录音转成文字。你只需要修正错字，卡片会根据这段文字生成。")
                .font(.system(size: 12))
                .foregroundStyle(Palette.muted)

            TextField("语音识别文字", text: binding(for: draft, keyPath: \.observation), axis: .vertical)
                .lineLimit(7...10)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 13))

            if let voice = draft.voiceAttachment {
                Button {
                    if let note = recorder.savedNotes.first(where: { $0.id == voice.noteID }) {
                        recorder.togglePlayback(note)
                    }
                } label: {
                    Label("回听原始录音 \(Int(voice.duration)) 秒", systemImage: recorder.isPlaying ? "pause.circle" : "play.circle")
                        .adaptiveFullWidthHitTarget(minHeight: 38)
                }
                .buttonStyle(.bordered)
            }

            HStack(spacing: 12) {
                Button("重新录音") {
                    memory.discardDraft(draft)
                    resetFlow()
                }
                .buttonStyle(.bordered)

                Button {
                    memory.prepareCard(for: normalized(draft))
                } label: {
                    Label("生成卡片", systemImage: "sparkles")
                        .adaptiveFullWidthHitTarget(minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .disabled(draft.observation.trimmed.isEmpty || draft.voiceAttachment == nil)
            }
        }
    }

    private func generationStep(_ draft: MemoryDraft) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            stepLabel("3 / 4", "生成拍立得卡片")
            PolaroidMemoryCard(draft: draft)
                .frame(maxWidth: 300)
                .frame(maxWidth: .infinity)
            HStack(spacing: 10) {
                ProgressView().controlSize(.small).tint(Palette.amber)
                Text("正在根据录音文字生成画面…")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.muted)
            }
            Button("返回修改文字") { memory.cancelPreparation(for: draft) }
                .buttonStyle(.bordered)
        }
    }

    private func generationFailureStep(_ draft: MemoryDraft, reason: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            stepLabel("3 / 4", "卡片生成失败")
            Text(reason)
                .font(.system(size: 12))
                .foregroundStyle(Color(red: 0.92, green: 0.52, blue: 0.46))
            HStack(spacing: 12) {
                Button("返回修改文字") {
                    var back = draft
                    back.reviewState = .draft
                    memory.updateDraft(back)
                }
                .buttonStyle(.bordered)
                Button("重试生成") {
                    memory.prepareCard(for: draft)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func deliveryStep(_ draft: MemoryDraft) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            stepLabel("4 / 4", "选择送达时间")
            Text("卡片已生成。选择它什么时候出现在对方的回忆里。")
                .font(.system(size: 12))
                .foregroundStyle(Palette.muted)

            PolaroidMemoryCard(draft: draft)
                .frame(maxWidth: 320)
                .frame(maxWidth: .infinity)

            VStack(spacing: 10) {
                ForEach(MemoryDeliveryPlan.allCases) { plan in
                    Button {
                        var updated = draft
                        updated.deliveryPlan = plan
                        memory.updateDraft(updated)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: draft.deliveryPlan == plan ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(draft.deliveryPlan == plan ? Palette.amber : Palette.muted)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(plan.title)
                                    .font(.system(size: 12, weight: .semibold))
                                Text(plan.detail)
                                    .font(.system(size: 10))
                                    .foregroundStyle(Palette.muted)
                            }
                            Spacer()
                        }
                        .adaptiveFullWidthHitTarget(minHeight: 52)
                        .padding(.horizontal, 10)
                        .background(Palette.surface2, in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(ZaichangPlainButtonStyle())
                }
            }

            HStack(spacing: 12) {
                Button("返回重新生成") {
                    var back = draft
                    back.reviewState = .draft
                    memory.updateDraft(back)
                }
                .buttonStyle(.bordered)

                Button {
                    memory.confirm(draft)
                    resetFlow()
                    dismiss()
                } label: {
                    Label("保存并等待送达", systemImage: "paperplane.fill")
                        .adaptiveFullWidthHitTarget(minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func transcribe(_ note: SavedVoiceNote) async {
        flow.transcriptionState = .running
        do {
            let transcript = try await transcriptionService.transcribe(audioURL: recorder.fileURL(for: note))
            createDraft(from: note, transcript: transcript)
            flow.transcriptionState = .idle
        } catch {
            flow.transcriptionState = .failed(error.localizedDescription)
        }
    }

    private func createDraft(from note: SavedVoiceNote?, transcript: String) {
        guard let note else { return }
        let draft = memory.makeDraft(
            title: "一段留声",
            mood: .warm,
            observation: transcript,
            keyMoment: transcript,
            delivery: .oneHourLater,
            creatorName: "我",
            participantNames: ["阿禾"],
            visibility: .shared,
            voiceAttachment: .init(
                noteID: note.id,
                filename: note.filename,
                duration: note.duration,
                createdAt: note.createdAt,
                delivery: note.delivery
            )
        )
        flow.activeDraftID = draft.id
    }

    private func normalized(_ draft: MemoryDraft) -> MemoryDraft {
        var copy = draft
        let transcript = draft.observation.trimmed
        copy.title = transcript.prefix(12).isEmpty ? "一段留声" : String(transcript.prefix(12))
        copy.keyMoment = transcript
        return copy
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

    private func stepLabel(_ step: String, _ title: String) -> some View {
        Label("步骤 \(step) · \(title)", systemImage: "recordingtape")
            .font(.system(size: 12, weight: .semibold))
    }

    private func resetFlow() {
        flow = PhonographFlow()
        recorder.cancelCurrentRecording()
    }
}

private struct PhonographFlow {
    var voiceNote: SavedVoiceNote?
    var transcriptionState: TranscriptionState = .idle
    var activeDraftID: UUID?
}

private enum TranscriptionState: Equatable {
    case idle
    case running
    case failed(String)
}

private enum PhonographStep: Int, CaseIterable, Identifiable {
    case record = 1
    case editText = 2
    case generateCard = 3
    case delivery = 4

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .record: "录音"
        case .editText: "修正"
        case .generateCard: "生成"
        case .delivery: "送达"
        }
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
