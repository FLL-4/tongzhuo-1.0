import SwiftUI

// MARK: - Shared Memory

struct MemorySheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SheetContainer(eyebrow: "共同记忆", title: "一起坐过的时间", dismiss: dismiss) {
            HStack {
                MemoryStat(value: "12", label: "次同桌")
                Divider().overlay(Palette.line)
                MemoryStat(value: "8h 24m", label: "共同在场")
                Divider().overlay(Palette.line)
                MemoryStat(value: "7", label: "段留声")
            }
            .frame(height: 72)
            .overlay(alignment: .top) { Divider().overlay(Palette.line) }
            .overlay(alignment: .bottom) { Divider().overlay(Palette.line) }

            VStack(alignment: .leading, spacing: 18) {
                MemoryEvent(time: "今晚 · 22:26", title: "雨夜书桌", text: "你们一起完成了 42 分钟专注。")
                MemoryEvent(time: "8 月 8 日", title: "一段迟到的留声", text: "“面试结束记得告诉我。”")
                MemoryEvent(time: "8 月 3 日", title: "第一次同桌", text: "两盏台灯从那天开始同时亮起。")
            }
            .padding(.top, 18)
        }
    }
}

private struct MemoryStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 18, weight: .semibold)).foregroundStyle(Palette.amberSoft)
            Text(label).font(.system(size: 9)).foregroundStyle(Palette.muted)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct MemoryEvent: View {
    let time: String
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(time).font(.system(size: 9)).foregroundStyle(Palette.muted)
            Text(title).font(.system(size: 12, weight: .semibold))
            Text(text).font(.system(size: 10)).foregroundStyle(Color.white.opacity(0.72))
        }
    }
}
