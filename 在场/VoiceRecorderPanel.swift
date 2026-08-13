import SwiftUI

struct VoiceRecorderPanel: View {
    @ObservedObject var recorder: VoiceRecorderController
    let onSaveDraft: (() -> Void)?

    init(
        recorder: VoiceRecorderController,
        onSaveDraft: (() -> Void)? = nil
    ) {
        self.recorder = recorder
        self.onSaveDraft = onSaveDraft
    }

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: recorder.isRecording ? "stop.circle.fill" : "record.circle")
                .font(.system(size: 72))
                .foregroundStyle(recorder.isRecording ? Color(red: 0.86, green: 0.42, blue: 0.36) : Palette.amber)
            Text(recorder.elapsedText)
                .font(.system(size: 14, design: .monospaced))

            if case .permissionDenied = recorder.phase {
                Text("请在“系统设置 > 隐私与安全性 > 麦克风”中允许在场使用麦克风。")
                    .font(.system(size: 10))
                    .foregroundStyle(Palette.muted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            } else if case let .failed(message) = recorder.phase {
                Text(message)
                    .font(.system(size: 10))
                    .foregroundStyle(Color(red: 0.90, green: 0.52, blue: 0.46))
                    .multilineTextAlignment(.center)
            }

            Button {
                if recorder.isRecording {
                    recorder.finishRecording()
                } else {
                    Task { await recorder.startRecording() }
                }
            } label: {
                Text(recordButtonTitle)
                    .adaptiveHitTarget()
            }
            .buttonStyle(.bordered)
            .disabled(recorder.phase == .requestingPermission)

            if recorder.hasDraft && !recorder.isRecording {
                HStack(spacing: 16) {
                    Button {
                        recorder.toggleDraftPlayback()
                    } label: {
                        Label(recorder.isPlaying ? "暂停试听" : "试听", systemImage: recorder.isPlaying ? "pause.fill" : "play.fill")
                            .adaptiveHitTarget()
                    }
                    .buttonStyle(.bordered)
                    Button(role: .destructive) {
                        recorder.cancelCurrentRecording()
                    } label: {
                        Label("放弃", systemImage: "trash")
                            .adaptiveHitTarget()
                    }
                    .buttonStyle(.bordered)
                }
                .font(.system(size: 11))
            }

            if let onSaveDraft, recorder.hasDraft && !recorder.isRecording {
                Button(action: onSaveDraft) {
                    Label("放进留声机", systemImage: "paperplane")
                        .adaptiveFullWidthHitTarget(minHeight: 40)
                        .background(Palette.amber)
                        .foregroundStyle(Color(red: 0.17, green: 0.13, blue: 0.09))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(ZaichangPlainButtonStyle())
                .opacity(recorder.hasDraft && !recorder.isRecording ? 1 : 0.45)
                .disabled(!recorder.hasDraft || recorder.isRecording)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .overlay(alignment: .top) { Divider().overlay(Palette.line) }
        .overlay(alignment: .bottom) { Divider().overlay(Palette.line) }
        .onDisappear {
            if recorder.isRecording {
                recorder.finishRecording()
            } else {
                recorder.stopPlayback()
            }
        }
    }

    private var recordButtonTitle: String {
        switch recorder.phase {
        case .requestingPermission: "正在请求权限…"
        case .recording: "完成录制"
        case .recorded, .playing: "重新录制"
        default: "开始录制"
        }
    }
}
