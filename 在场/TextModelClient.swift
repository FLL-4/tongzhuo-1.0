import Foundation

/// A message sent to an OpenAI-compatible chat completion endpoint.
struct TextModelMessage: Codable, Equatable {
    enum Role: String, Codable {
        case system
        case user
        case assistant
    }

    let role: Role
    let content: String

    init(role: Role, content: String) {
        self.role = role
        self.content = content
    }
}

protocol TextModelGenerating {
    func complete(messages: [TextModelMessage]) async throws -> String
}

/// Calls the chat-completions contract exposed by OpenAI-compatible gateways.
/// The client is deliberately independent from SwiftUI so it can serve
/// presence suggestions, scene drafting, and future local workflows.
struct OpenAICompatibleTextClient: TextModelGenerating {
    let configuration: APIConfiguration
    var session: URLSession = .shared

    func complete(messages: [TextModelMessage]) async throws -> String {
        guard !messages.isEmpty else { throw TextModelError.emptyMessages }
        guard configuration.text.provider == .openAI else { throw TextModelError.unsupportedProvider }
        guard !configuration.text.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TextModelError.notConfigured
        }
        guard !configuration.text.model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TextModelError.notConfigured
        }

        let requestBody = ChatCompletionRequest(
            model: configuration.text.model,
            messages: messages,
            stream: false
        )
        var request = URLRequest(url: try Self.chatCompletionsURL(baseURL: configuration.text.baseURL))
        request.httpMethod = "POST"
        request.timeoutInterval = 90
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(configuration.text.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TextModelError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw TextModelError.httpFailure(statusCode: httpResponse.statusCode)
        }

        let decoded: ChatCompletionResponse
        do {
            decoded = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        } catch {
            throw TextModelError.invalidResponse
        }
        guard let content = decoded.choices.first?.message.content,
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TextModelError.emptyResponse
        }
        return content
    }

    static func chatCompletionsURL(baseURL: String) throws -> URL {
        let normalized = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let base = URL(string: normalized),
              let scheme = base.scheme,
              ["https", "http"].contains(scheme),
              let host = base.host(),
              !host.isEmpty else {
            throw TextModelError.invalidEndpoint
        }
        return base.appendingPathComponent("chat/completions")
    }
}

enum TextModelError: LocalizedError, Equatable {
    case emptyMessages
    case unsupportedProvider
    case notConfigured
    case invalidEndpoint
    case invalidResponse
    case emptyResponse
    case httpFailure(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .emptyMessages: "文本请求没有消息。"
        case .unsupportedProvider: "当前 API 提供商不支持文本模型。"
        case .notConfigured: "文本模型 API 尚未配置。"
        case .invalidEndpoint: "文本模型 API 地址无效。"
        case .invalidResponse: "文本模型返回了无法识别的结果。"
        case .emptyResponse: "文本模型没有返回内容。"
        case .httpFailure(let statusCode): "文本模型请求失败（HTTP \(statusCode)）。"
        }
    }
}

private struct ChatCompletionRequest: Encodable {
    let model: String
    let messages: [TextModelMessage]
    let stream: Bool
}

private struct ChatCompletionResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String?
        }

        let message: Message
    }

    let choices: [Choice]
}
