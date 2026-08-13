import SwiftUI

struct MemoryHistoryView: View {
    @ObservedObject var memory: MemoryController
    @ObservedObject var recorder: VoiceRecorderController
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let cards = memory.cards.filter { $0.reviewState == .confirmed }
        SheetContainer(eyebrow: "回忆", title: "留下来的声音", dismiss: dismiss) {
            if cards.isEmpty {
                Text("确认后的留声卡片会沿着时间线放在这里。")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 20)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(cards) { card in
                            timelineRow(card)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(maxWidth: 560)
                .frame(height: 560)
            }
        }
    }

    private func timelineRow(_ card: MemoryDraft) -> some View {
        HStack(alignment: .top, spacing: 16) {
            TimelineNode(date: card.confirmedAt ?? card.createdAt)
                .frame(width: 98)

            VStack(alignment: .leading, spacing: 12) {
                PolaroidMemoryCard(draft: card)
                    .frame(width: 220)
                voiceButton(for: card)
                    .frame(width: 220)
            }
            .padding(.bottom, 28)
        }
    }

    @ViewBuilder
    private func voiceButton(for card: MemoryDraft) -> some View {
        if let voice = card.voiceAttachment,
           let note = recorder.savedNotes.first(where: { $0.id == voice.noteID }) {
            Button {
                recorder.togglePlayback(note)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: recorder.isPlaying(note) ? "pause.fill" : "play.fill")
                    Text("\(Int(voice.duration)) 秒")
                    Spacer()
                }
                .font(.system(size: 11, weight: .semibold))
                .adaptiveFullWidthHitTarget(minHeight: 36)
                .padding(.horizontal, 10)
                .background(Palette.surface2, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).stroke(Palette.line))
            }
            .buttonStyle(ZaichangPlainButtonStyle())
        } else {
            Text("录音不可用")
                .font(.system(size: 11))
                .foregroundStyle(Palette.muted)
                .frame(width: 220, alignment: .leading)
                .frame(height: 36)
        }
    }
}

private struct TimelineNode: View {
    let date: Date

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(spacing: 0) {
                Circle()
                    .fill(Palette.amber)
                    .frame(width: 10, height: 10)
                Rectangle()
                    .fill(Palette.line)
                    .frame(width: 1)
                    .frame(height: 290)
            }
            Text(date.formatted(date: .abbreviated, time: .omitted))
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Palette.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, -2)
        }
    }
}
