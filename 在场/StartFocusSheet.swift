import SwiftUI

struct StartFocusSheet: View {
    @ObservedObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDurationMinutes = 25
    @State private var selectedTaskIDs = Set<FocusTask.ID>()
    @State private var customTaskTitle = ""

    var body: some View {
        SheetContainer(eyebrow: "开始", title: sheetTitle, dismiss: dismiss) {
            if let session = model.activeFocusSession {
                activeSessionContent(session)
            } else {
                focusConfiguration
            }
        }
    }

    private var sheetTitle: String {
        model.activeFocusSession == nil ? "准备这一段专注" : "这一段正在进行"
    }

    private var focusConfiguration: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("选择一段合适的时长，也可以把今天要做的事带进这一段。")
                .font(.system(size: 10))
                .foregroundStyle(Palette.muted)

            VStack(alignment: .leading, spacing: 8) {
                Text("专注时长")
                    .font(.system(size: 12, weight: .semibold))
                Picker("", selection: $selectedDurationMinutes) {
                    ForEach(FocusSessionConfiguration.allowedDurations, id: \.self) { minutes in
                        Text("\(minutes) 分钟").tag(minutes)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            Divider().overlay(Palette.line)

            TaskShelfSection(
                model: model,
                title: "今日 Todo（可多选）",
                mode: .selection(
                    selectedTaskIDs: $selectedTaskIDs,
                    customTaskTitle: $customTaskTitle
                )
            )

            PanelButton(
                title: "开始这一段专注",
                symbol: "play.fill",
                isProminent: true,
                action: beginFocus
            )
        }
        .padding(.vertical, 4)
    }

    private func activeSessionContent(_ session: FocusSession) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("剩余时间")
                        .font(.system(size: 10))
                        .foregroundStyle(Palette.muted)
                    Text(model.timerText)
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                }
                Spacer()
                Text(session.roomID == nil ? "独自专注" : "与同桌一起")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Palette.amberSoft)
            }

            if let summary = model.activeFocusSummary {
                VStack(alignment: .leading, spacing: 5) {
                    Text("这一段要做")
                        .font(.system(size: 10))
                        .foregroundStyle(Palette.muted)
                    Text(summary)
                        .font(.system(size: 12, weight: .medium))
                }
            }

            PanelButton(title: "回到在场", symbol: "arrow.left", isProminent: true) {
                dismiss()
            }
        }
        .padding(.vertical, 4)
    }

    private func beginFocus() {
        guard model.startFocus(
            durationMinutes: selectedDurationMinutes,
            taskIDs: selectedTaskIDs,
            customTaskTitle: customTaskTitle
        ) else { return }
        dismiss()
    }
}
