import SwiftUI

struct MemoryHistoryView: View {
    @ObservedObject var memory: MemoryController
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let cards = memory.cards.filter { $0.reviewState == .confirmed }
        SheetContainer(eyebrow: "回忆", title: "像翻开一本会发光的相册，每一页都只保留最重要的那一刻。", dismiss: dismiss, maxWidth: 760) {
            if cards.isEmpty {
                Text("确认后的记忆会像一本册子一样放在这里。")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 20)
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 170, maximum: 220), spacing: 18, alignment: .top)],
                        spacing: 18
                    ) {
                        ForEach(cards) { card in memoryCard(card) }
                    }
                    .padding(.vertical, 4)
                }
                .frame(height: 560)
            }
        }
    }

    private func memoryCard(_ card: MemoryDraft) -> some View {
        let template = MemoryCardTemplatePool().template(id: card.imageTemplateID)
        return VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Palette.surface2)
                if let template, let art = MemoryCardArtwork.image(for: template.assetName) {
                    art
                        .resizable()
                        .scaledToFit()
                        .padding(10)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.32)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 4) {
                    Text(status(card))
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Palette.amber.opacity(0.92), in: Capsule())
                    Text(card.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .shadow(radius: 4, y: 1)
                }
                .padding(10)
            }
            .aspectRatio(2 / 3, contentMode: .fit)

            VStack(alignment: .leading, spacing: 7) {
                Text(card.observation)
                    .font(.system(size: 11))
                    .lineLimit(2)
                Text("关键时刻：\(card.keyMoment)")
                    .font(.system(size: 10))
                    .foregroundStyle(Palette.muted)
                if let voice = card.voiceAttachment {
                    Text("语音附件：\(voice.duration.formatted(.number.precision(.fractionLength(0)))) 秒")
                        .font(.system(size: 10))
                        .foregroundStyle(Palette.muted)
                }
                if let confirmedAt = card.confirmedAt {
                    Text(confirmedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 10))
                        .foregroundStyle(Palette.muted)
                }
            }
            .padding(.horizontal, 2)

            HStack(spacing: 8) {
                if card.deliveryState == .delivered {
                    Button("已打开") { memory.markOpened(card) }
                        .buttonStyle(.bordered)
                }
            }
            .font(.system(size: 10))
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Palette.surface2)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.line.opacity(0.72), lineWidth: 1))
        )
    }

    private func status(_ card: MemoryDraft) -> String {
        deliveryLabel(card.deliveryState)
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
