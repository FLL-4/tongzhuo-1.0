import Foundation
import Speech

enum SpeechTranscriptionError: LocalizedError {
    case recognizerUnavailable
    case permissionDenied
    case emptyResult

    var errorDescription: String? {
        switch self {
        case .recognizerUnavailable:
            return "当前系统暂时无法使用语音识别。"
        case .permissionDenied:
            return "没有语音识别权限，请在系统设置中允许在场使用语音识别。"
        case .emptyResult:
            return "没有识别到可编辑的文字。"
        }
    }
}

struct SpeechTranscriptionService {
    private let locale: Locale

    init(locale: Locale = Locale(identifier: "zh-CN")) {
        self.locale = locale
    }

    func transcribe(audioURL: URL) async throws -> String {
        let status = await requestAuthorization()
        guard status == .authorized else { throw SpeechTranscriptionError.permissionDenied }
        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            throw SpeechTranscriptionError.recognizerUnavailable
        }

        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = false

        let text = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            recognizer.recognitionTask(with: request) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let result, result.isFinal else { return }
                continuation.resume(returning: result.bestTranscription.formattedString)
            }
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw SpeechTranscriptionError.emptyResult }
        return trimmed
    }

    private func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { (continuation: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>) in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
}
