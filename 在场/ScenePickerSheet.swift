import SwiftUI

// MARK: - Scene Selection

struct ScenePickerSheet: View {
    @ObservedObject var model: AppModel
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

    var body: some View {
        SheetContainer(eyebrow: "场景", title: "今晚住在哪里", dismiss: dismiss) {
            LazyVGrid(
                columns: columns,
                spacing: 10
            ) {
                ForEach(model.scenes) { scene in
                    Button {
                        model.selectScene(scene)
                        dismiss()
                    } label: {
                        ScenePickerCard(
                            title: scene.name,
                            isGenerated: scene.origin == .generated,
                            isSelected: model.selectedSceneID == scene.id
                        ) {
                            BundledSceneImage(
                                relativePath: scene.image.relativePath
                            )
                        }
                    }
                    .buttonStyle(ZaichangPlainButtonStyle())
                    .accessibilityLabel("选择场景：\(scene.name)")
                    .accessibilityValue(model.selectedSceneID == scene.id ? "已选择" : "未选择")
                }

                Button {
                    model.activeSheet = .sceneWorkshop
                } label: {
                    ScenePickerCard(title: "新建场景") {
                        ZStack {
                            Color.white.opacity(0.035)
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(Palette.amberSoft)
                        }
                    }
                }
                .buttonStyle(ZaichangPlainButtonStyle())
                .accessibilityLabel("新建场景")
            }
        }
    }
}

private struct ScenePickerCard<Preview: View>: View {
    let title: String
    let isGenerated: Bool
    let isSelected: Bool
    @ViewBuilder let preview: Preview

    init(
        title: String,
        isGenerated: Bool = false,
        isSelected: Bool = false,
        @ViewBuilder preview: () -> Preview
    ) {
        self.title = title
        self.isGenerated = isGenerated
        self.isSelected = isSelected
        self.preview = preview()
    }

    var body: some View {
        VStack(spacing: 0) {
            preview
                .frame(maxWidth: .infinity)
                .aspectRatio(16 / 9, contentMode: .fit)
                .clipped()

            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)

                if isGenerated {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Palette.amberSoft)
                }

                Spacer(minLength: 4)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Palette.amber)
                }
            }
            .padding(.horizontal, 10)
            .frame(height: 40)
        }
        .frame(maxWidth: .infinity)
        .background(Palette.surface3)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Palette.amber : Color.white.opacity(0.15))
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .contentShape(RoundedRectangle(cornerRadius: 6))
    }
}
