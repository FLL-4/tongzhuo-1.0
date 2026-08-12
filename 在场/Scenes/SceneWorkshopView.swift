import SwiftUI

struct SceneWorkshopSheet: View {
    @ObservedObject private var appModel: AppModel
    @StateObject private var workshop: SceneWorkshopModel
    @Environment(\.dismiss) private var dismiss

    init(model: AppModel) {
        appModel = model
        _workshop = StateObject(
            wrappedValue: SceneWorkshopModel(generator: model.sceneGenerator)
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(Palette.line)
            ScrollView {
                content
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            Divider().overlay(Palette.line)
            footer
        }
        .background(Palette.surface2)
        .foregroundStyle(Palette.ink)
#if os(macOS)
        .frame(width: 640, height: 580)
#else
        .frame(maxWidth: 640)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Palette.surface2)
#endif
        .onDisappear { workshop.cancelGeneration() }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("场景工坊").eyebrowStyle()
                Text(headerTitle)
                    .font(.system(size: 18, weight: .semibold))
            }
            Spacer()
            Button {
                workshop.cancelGeneration()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .adaptiveHitTarget(minWidth: 32, minHeight: 32)
            }
            .buttonStyle(ZaichangPlainButtonStyle())
            .accessibilityLabel("关闭")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
    }

    @ViewBuilder
    private var content: some View {
        switch workshop.step {
        case .describe:
            descriptionStep
        case .configure:
            configurationStep
        case .generating:
            generatingStep
        case .preview:
            previewStep
        }
    }

    private var descriptionStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 7) {
                Label("想一起待在哪里？", systemImage: "text.bubble")
                    .font(.system(size: 14, weight: .semibold))
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $workshop.descriptionText)
                        .font(.system(size: 14))
                        .scrollContentBackground(.hidden)
                        .padding(10)
                        .frame(minHeight: 112)
                    if workshop.descriptionText.isEmpty {
                        Text("雪夜列车包厢，两个人安静看书。")
                            .font(.system(size: 14))
                            .foregroundStyle(Palette.muted)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 18)
                            .allowsHitTesting(false)
                    }
                }
                .background(Palette.surface3)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Palette.line))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            HStack(spacing: 8) {
                WorkshopSuggestion(title: "雨夜阁楼", symbol: "cloud.rain") {
                    workshop.descriptionText = "雨夜的旧阁楼书房，两个人隔着一盏台灯安静工作。"
                }
                WorkshopSuggestion(title: "雪夜列车", symbol: "train.side.front.car") {
                    workshop.descriptionText = "雪夜列车包厢，两个人安静看书。"
                }
                WorkshopSuggestion(title: "海边黄昏", symbol: "sun.horizon") {
                    workshop.descriptionText = "面向海面的工作室，黄昏时一起完成各自的事。"
                }
            }
        }
    }

    @ViewBuilder
    private var configurationStep: some View {
        if workshop.spec != nil {
            SceneConfigurationForm(
                spec: Binding(
                    get: { workshop.spec! },
                    set: { workshop.spec = $0 }
                ),
                keyObjectsText: $workshop.keyObjectsText
            )
        }
    }

    private var generatingStep: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 44)
            ProgressView()
                .controlSize(.large)
                .tint(Palette.amber)
            VStack(spacing: 7) {
                Text(workshop.generationStatusTitle)
                    .font(.system(size: 18, weight: .semibold))
                Text(workshop.spec?.name ?? "新场景")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.muted)
            }
            VStack(spacing: 12) {
                GenerationStageRow(
                    title: "场景背景",
                    symbol: "photo",
                    status: generationStageStatus
                )
                GenerationStageRow(
                    title: "构图审查",
                    symbol: "checkmark.shield",
                    status: reviewStageStatus
                )
            }
            .frame(maxWidth: 360)
            Spacer(minLength: 44)
        }
        .frame(maxWidth: .infinity, minHeight: 430)
    }

    @ViewBuilder
    private var previewStep: some View {
        if let result = workshop.result, let spec = workshop.spec {
            VStack(alignment: .leading, spacing: 18) {
                BundledSceneImage(relativePath: result.image.relativePath)
                    .aspectRatio(16 / 9, contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .overlay(alignment: .topTrailing) {
                        Text("静态背景")
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(.black.opacity(0.68), in: RoundedRectangle(cornerRadius: 5))
                            .padding(10)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(Palette.line))

                HStack(alignment: .top, spacing: 18) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(spec.name)
                            .font(.system(size: 15, weight: .semibold))
                        Text("\(spec.timeOfDay.displayName) · \(spec.mood.displayName) · \(spec.ambientPreset.displayName)")
                            .font(.system(size: 11))
                            .foregroundStyle(Palette.muted)
                    }
                    Spacer()
                    ReviewSummary(review: result.review)
                }
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 14) {
            WorkshopProgress(step: workshop.step)

            HStack(spacing: 10) {
                if let errorMessage = workshop.errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.circle")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(red: 0.95, green: 0.58, blue: 0.48))
                }
                Spacer()
                footerButtons
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private var footerButtons: some View {
        switch workshop.step {
        case .describe:
            Button {
                workshop.cancelGeneration()
                dismiss()
            } label: {
                Text("取消").adaptiveHitTarget()
            }
            .buttonStyle(.bordered)
            Button {
                workshop.draftSpec()
            } label: {
                HStack(spacing: 6) {
                    Text("下一步")
                    Image(systemName: "chevron.right")
                }
                .adaptiveHitTarget()
            }
            .buttonStyle(.borderedProminent)
            .tint(Palette.amber)
            .disabled(!workshop.canDraft)
        case .configure:
            Button {
                workshop.returnToDescription()
            } label: {
                Label("上一步", systemImage: "chevron.left")
                    .adaptiveHitTarget()
            }
            .buttonStyle(.bordered)
            Button {
                workshop.generate()
            } label: {
                Text("生成预览").adaptiveHitTarget()
            }
            .buttonStyle(.borderedProminent)
            .tint(Palette.amber)
        case .generating:
            Button {
                workshop.adjustAndRedraw()
            } label: {
                Label("停止生成", systemImage: "xmark")
                    .adaptiveHitTarget()
            }
            .buttonStyle(.bordered)
        case .preview:
            Button {
                workshop.adjustAndRedraw()
            } label: {
                Label("上一步", systemImage: "chevron.left")
                    .adaptiveHitTarget()
            }
            .buttonStyle(.bordered)
            Button {
                guard let scene = workshop.generatedScene() else { return }
                appModel.saveGeneratedScene(scene)
                dismiss()
            } label: {
                Text("保存场景").adaptiveHitTarget()
            }
            .buttonStyle(.borderedProminent)
            .tint(Palette.amber)
            .disabled(workshop.result?.review.isApproved != true)
        }
    }

    private var headerTitle: String {
        switch workshop.step {
        case .describe: "描述一个地方"
        case .configure: "确认场景细节"
        case .generating: "正在点亮房间"
        case .preview: "查看场景预览"
        }
    }

    private var generationStageStatus: GenerationStageStatus {
        guard let state = workshop.job?.state else { return .waiting }
        switch state {
        case .queued:
            return .waiting
        case .generating:
            return .active
        case .reviewing, .repairing, .ready:
            return .complete
        case .failed:
            return .waiting
        }
    }

    private var reviewStageStatus: GenerationStageStatus {
        guard let state = workshop.job?.state else { return .waiting }
        return switch state {
        case .reviewing, .repairing: .active
        case .ready: .complete
        default: .waiting
        }
    }
}

private struct WorkshopProgress: View {
    let step: SceneWorkshopStep
    private let titles = ["描述", "细节", "预览"]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(titles.enumerated()), id: \.offset) { index, title in
                HStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(index <= progressIndex ? Palette.amber : Palette.surface3)
                            .overlay(Circle().stroke(index <= progressIndex ? Palette.amber : Palette.line))

                        if index < progressIndex {
                            Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .bold))
                        } else {
                            Text("\(index + 1)")
                                .font(.system(size: 9, weight: .semibold))
                        }
                    }
                    .frame(width: 20, height: 20)
                    .foregroundStyle(index <= progressIndex ? Palette.surface : Palette.muted)

                    Text(title)
                        .font(.system(size: 10, weight: index == progressIndex ? .semibold : .regular))
                        .foregroundStyle(index <= progressIndex ? Palette.ink : Palette.muted)
                }

                if index < titles.count - 1 {
                    Rectangle()
                        .fill(index < progressIndex ? Palette.amber : Palette.line)
                        .frame(maxWidth: 38, maxHeight: 1)
                }
            }
        }
        .frame(maxWidth: 360)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("第 \(progressIndex + 1) 步，共 3 步：\(titles[progressIndex])")
    }

    private var progressIndex: Int {
        switch step {
        case .describe: 0
        case .configure, .generating: 1
        case .preview: 2
        }
    }
}

private struct WorkshopSuggestion: View {
    let title: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.system(size: 11, weight: .medium))
                .adaptiveFullWidthHitTarget(minHeight: 36)
        }
        .buttonStyle(.bordered)
        .contentShape(Rectangle())
    }
}

private struct SceneConfigurationForm: View {
    @Binding var spec: GeneratedSceneSpec
    @Binding var keyObjectsText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            WorkshopField(title: "场景名称", symbol: "character.cursor.ibeam") {
                TextField("场景名称", text: $spec.name)
                    .workshopTextField()
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("时间", systemImage: "clock")
                    .font(.system(size: 11, weight: .semibold))
                Picker("时间", selection: $spec.timeOfDay) {
                    ForEach(SceneTimeOfDay.allCases, id: \.self) {
                        Text($0.displayName).tag($0)
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("氛围", systemImage: "lamp.desk")
                    .font(.system(size: 11, weight: .semibold))
                Picker("氛围", selection: $spec.mood) {
                    ForEach(SceneMood.allCases, id: \.self) {
                        Text($0.displayName).tag($0)
                    }
                }
                .pickerStyle(.segmented)
            }

            HStack(alignment: .top, spacing: 14) {
                WorkshopField(title: "环境声音", symbol: "speaker.wave.2") {
                    Picker("环境声音", selection: $spec.ambientPreset) {
                        ForEach(AmbientPreset.allCases, id: \.self) {
                            Text($0.displayName).tag($0)
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                WorkshopField(title: "动态效果", symbol: "sparkles") {
                    Picker("动态效果", selection: $spec.effectPreset) {
                        ForEach(SceneEffectPreset.allCases, id: \.self) {
                            Text($0.displayName).tag($0)
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            WorkshopField(title: "所在位置", symbol: "mappin.and.ellipse") {
                TextField("所在位置", text: $spec.location)
                    .workshopTextField()
            }
            WorkshopField(title: "窗外", symbol: "window.casement") {
                TextField("窗外景色", text: $spec.windowView)
                    .workshopTextField()
            }
            WorkshopField(title: "天气", symbol: "cloud.sun") {
                TextField("天气", text: $spec.weather)
                    .workshopTextField()
            }
            WorkshopField(title: "主要灯光", symbol: "lightbulb") {
                TextField("主要灯光", text: $spec.lighting)
                    .workshopTextField()
            }
            WorkshopField(title: "关键物件", symbol: "square.grid.2x2") {
                TextField("最多三个，用逗号分隔", text: $keyObjectsText)
                    .workshopTextField()
            }
        }
    }
}

private struct WorkshopField<Content: View>: View {
    let title: String
    let symbol: String
    @ViewBuilder let content: Content

    init(title: String, symbol: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.symbol = symbol
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol)
                .font(.system(size: 11, weight: .semibold))
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension View {
    func workshopTextField() -> some View {
        textFieldStyle(.plain)
            .font(.system(size: 13))
            .padding(.horizontal, 11)
            .frame(height: 38)
            .background(Palette.surface3)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Palette.line))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

private enum GenerationStageStatus {
    case waiting
    case active
    case complete
}

private struct GenerationStageRow: View {
    let title: String
    let symbol: String
    let status: GenerationStageStatus

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: statusSymbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(statusColor)
                .frame(width: 18)
            Label(title, systemImage: symbol)
                .font(.system(size: 12, weight: .medium))
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var statusSymbol: String {
        switch status {
        case .waiting: "circle"
        case .active: "circle.dotted"
        case .complete: "checkmark.circle.fill"
        }
    }

    private var statusColor: Color {
        switch status {
        case .waiting: Palette.muted
        case .active: Palette.amber
        case .complete: Palette.moss
        }
    }
}

private struct ReviewSummary: View {
    let review: SceneGenerationReview

    var body: some View {
        HStack(spacing: 10) {
            ReviewCheck(title: "像素", passed: review.pixelStyleConsistent)
            ReviewCheck(title: "构图", passed: review.compositionCorrect)
            ReviewCheck(title: "安全区", passed: review.interfaceSafeAreasClear)
        }
    }
}

private struct ReviewCheck: View {
    let title: String
    let passed: Bool

    var body: some View {
        Label(title, systemImage: passed ? "checkmark.circle.fill" : "xmark.circle.fill")
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(passed ? Palette.moss : Color(red: 0.95, green: 0.58, blue: 0.48))
    }
}
