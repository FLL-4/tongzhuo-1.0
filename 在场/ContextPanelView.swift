import Foundation
import SwiftUI

// MARK: - Context Panel

struct ContextPanelView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var recorder: VoiceRecorderController

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("此刻").eyebrowStyle()
                            Text("今晚的节奏").font(.system(size: 18, weight: .semibold))
                        }
                        Spacer()
                    }

                    VStack(spacing: 12) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("已在场").font(.system(size: 11)).foregroundStyle(Palette.muted)
                            Spacer()
                            Text(model.presenceText).font(.system(size: 20, weight: .semibold)).monospacedDigit()
                        }
                        HStack(spacing: 4) {
                            ForEach(0..<8, id: \.self) { index in
                                Capsule().fill(index < 5 ? Palette.amber : Color.white.opacity(0.14)).frame(height: 6)
                            }
                        }
                        HStack {
                            Label("连续 6 晚", systemImage: "flame.fill")
                                .foregroundStyle(Color(red: 0.85, green: 0.70, blue: 0.48))
                            Spacer()
                            Text("目标 60 分钟")
                        }
                        .font(.system(size: 10))
                        .foregroundStyle(Palette.muted)
                    }
                    .padding(.vertical, 20)
                    .panelDivider()

                    TaskShelfSection(model: model, title: "放在桌上的事", mode: .manage)
                    .padding(.vertical, 18)
                    .panelDivider()

                    NoticeCard {
                        HStack(spacing: 10) {
                            AppGlyph(.phonograph, size: 20)
                                .foregroundStyle(Palette.amber)
                                .frame(width: 38, height: 38)
                                .background(Color(red: 0.42, green: 0.29, blue: 0.20))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            VStack(alignment: .leading, spacing: 3) {
                                if let note = recorder.savedNotes.first {
                                    Text("最近保存的留声").font(.system(size: 9)).foregroundStyle(Palette.muted)
                                    Text(note.delivery.title).font(.system(size: 11, weight: .semibold))
                                    Text("你 · \(durationText(note.duration))").font(.system(size: 9)).foregroundStyle(Palette.muted)
                                } else {
                                    Text("一段留声等待播放").font(.system(size: 9)).foregroundStyle(Palette.muted)
                                    Text("“等你忙完再听”").font(.system(size: 11, weight: .semibold))
                                    Text("阿禾 · 00:18").font(.system(size: 9)).foregroundStyle(Palette.muted)
                                }
                            }
                            Spacer()
                            Button {
                                if let note = recorder.savedNotes.first {
                                    recorder.togglePlayback(note)
                                } else {
                                    model.showToast("这段示例留声还没有音频文件")
                                }
                            } label: {
                                Image(systemName: recorder.savedNotes.first.map(recorder.isPlaying) == true ? "pause.fill" : "play.fill")
                                    .foregroundStyle(Color(red: 0.18, green: 0.14, blue: 0.10))
                                    .adaptiveHitTarget(minWidth: 32, minHeight: 32)
                                    .background(Palette.amber)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(ZaichangPlainButtonStyle())
                            .accessibilityLabel(recorder.savedNotes.first.map(recorder.isPlaying) == true ? "暂停最近留声" : "播放最近留声")
                            .help(recorder.savedNotes.first.map(recorder.isPlaying) == true ? "暂停最近留声" : "播放最近留声")
                        }
                    }
                    .padding(.top, 18)

                    NoticeCard {
                        HStack(spacing: 0) {
                            Text("阿禾在20:34拍了拍你")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                        }
                    }
                    .padding(.top, 14)
                }
                .padding(.horizontal, 20)
                .padding(.top, 22)
            }

        }
        .background(Color(red: 0.115, green: 0.122, blue: 0.137))
    }

    private func durationText(_ duration: TimeInterval) -> String {
        let seconds = Int(duration.rounded(.down))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

}

private struct NoticeCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(11)
            .background(Color(red: 0.15, green: 0.14, blue: 0.12))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color(red: 0.27, green: 0.23, blue: 0.19)))
            .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}

struct ContextSheet: View {
    @ObservedObject var model: AppModel
    @ObservedObject var recorder: VoiceRecorderController
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ContextPanelView(model: model, recorder: recorder)
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .adaptiveHitTarget(minWidth: 32, minHeight: 32)
            }
            .buttonStyle(ZaichangPlainButtonStyle())
            .padding(.top, 12)
            .padding(.trailing, 14)
            .accessibilityLabel("关闭")
        }
        .adaptiveSheetFrame()
        .background(Palette.surface2)
        .foregroundStyle(Palette.ink)
#if os(macOS)
        .frame(minHeight: 520)
#else
        .frame(maxHeight: .infinity)
#endif
        .adaptiveSheetPresentation()
    }
}
