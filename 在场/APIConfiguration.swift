import Foundation

/// The local configuration contract shared by AI features. The development
/// installer places secrets in this app's Application Support container; they
/// are intentionally never bundled with the app.
struct APIConfiguration: Equatable {
    enum Provider: String {
        case openAI = "openai"
        case dashScope = "dashscope"
    }

    struct TextModel: Equatable {
        var provider: Provider = .openAI
        var apiKey = ""
        var baseURL = ""
        var model = ""

        var isConfigured: Bool {
            provider == .openAI
                && !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    struct ImageModel: Equatable {
        var provider: Provider = .dashScope
        var apiKey = ""
        var baseURL = ""
        var endpoint = "https://dashscope.aliyuncs.com/api/v1/services/aigc/multimodal-generation/generation"
        /// Photo-to-character image editing for the user's and partner's desk pets.
        var deskPetModel = "qwen-image-edit-plus"
        var deskPetSize = "1024x1024"
        /// Text-to-image generation for the room background, without characters.
        var sceneModel = "qwen-image-3.0"
        var sceneSize = "1664x928"
        /// Text-to-image generation for a square phonograph memory card.
        var memoryCardModel = "qwen-image-3.0"
        var memoryCardSize = "1024x1024"

        var isConfigured: Bool {
            guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
            switch provider {
            case .openAI: return !baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            case .dashScope: return !endpoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
        }
    }

    struct Matting: Equatable {
        enum Provider: String {
            case disabled
            case removeBG = "removebg"
        }

        var provider: Provider = .disabled
        var apiKey = ""
        var endpoint = "https://api.remove.bg/v1.0/removebg"

        var isConfigured: Bool {
            provider == .removeBG
                && !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !endpoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    var text = TextModel()
    var image = ImageModel()
    var matting = Matting()

    var isTextModelConfigured: Bool { text.isConfigured }
    var isImageModelConfigured: Bool { image.isConfigured }
    var isSceneImageGenerationConfigured: Bool {
        image.provider == .dashScope
            && image.isConfigured
            && !image.sceneModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    var isDeskPetImageGenerationConfigured: Bool {
        image.isConfigured && !image.deskPetModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    var isMemoryImageGenerationConfigured: Bool {
        image.isConfigured && !image.memoryCardModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static var defaultURL: URL {
        if let override = ProcessInfo.processInfo.environment["ZAICHANG_API_CONFIG"], !override.isEmpty {
            return URL(fileURLWithPath: override)
        }
        return AppStoragePaths.apiConfigurationURL()
    }

    static func load() -> APIConfiguration {
        let urls = [defaultURL, Bundle.main.url(forResource: "api.example", withExtension: "yaml")].compactMap { $0 }
        for url in urls {
            guard let text = try? String(contentsOf: url, encoding: .utf8) else { continue }
            return from(yaml: text)
        }
        return APIConfiguration()
    }

    static func from(yaml: String) -> APIConfiguration {
        var configuration = APIConfiguration()
        let values = YAMLScalarParser.parse(yaml)

        configuration.text.provider = provider(values["text.provider"]) ?? configuration.text.provider
        configuration.text.apiKey = values["text.api_key"] ?? configuration.text.apiKey
        configuration.text.baseURL = values["text.base_url"] ?? configuration.text.baseURL
        configuration.text.model = values["text.model"] ?? configuration.text.model

        configuration.image.provider = provider(values["image.provider"]) ?? configuration.image.provider
        configuration.image.apiKey = values["image.api_key"] ?? configuration.image.apiKey
        configuration.image.baseURL = values["image.base_url"] ?? configuration.image.baseURL
        configuration.image.endpoint = values["image.endpoint"] ?? configuration.image.endpoint
        configuration.image.deskPetModel = values["image.desk_pet_model"] ?? configuration.image.deskPetModel
        configuration.image.deskPetSize = values["image.desk_pet_size"] ?? configuration.image.deskPetSize
        configuration.image.sceneModel = values["image.scene_model"] ?? configuration.image.sceneModel
        configuration.image.sceneSize = values["image.scene_size"] ?? configuration.image.sceneSize
        configuration.image.memoryCardModel = values["image.memory_card_model"] ?? configuration.image.memoryCardModel
        configuration.image.memoryCardSize = values["image.memory_card_size"] ?? configuration.image.memoryCardSize

        if let value = values["matting.provider"], let provider = Matting.Provider(rawValue: value.lowercased()) {
            configuration.matting.provider = provider
        }
        configuration.matting.apiKey = values["matting.api_key"] ?? configuration.matting.apiKey
        configuration.matting.endpoint = values["matting.endpoint"] ?? configuration.matting.endpoint

        return configuration
    }

    private static func provider(_ value: String?) -> Provider? {
        value.flatMap { Provider(rawValue: $0.lowercased()) }
    }

    // MARK: - Serialization

    var yamlString: String {
        func quote(_ value: String) -> String {
            "\"\(value.replacingOccurrences(of: "\"", with: "\\\""))\""
        }
        var lines: [String] = []
        lines.append("# Managed by the in-app settings page.")
        lines.append("")
        lines.append("text:")
        lines.append("  provider: \(quote(text.provider.rawValue))")
        lines.append("  api_key: \(quote(text.apiKey))")
        lines.append("  base_url: \(quote(text.baseURL))")
        lines.append("  model: \(quote(text.model))")
        lines.append("")
        lines.append("image:")
        lines.append("  provider: \(quote(image.provider.rawValue))")
        lines.append("  api_key: \(quote(image.apiKey))")
        lines.append("  base_url: \(quote(image.baseURL))")
        lines.append("  endpoint: \(quote(image.endpoint))")
        lines.append("  desk_pet_model: \(quote(image.deskPetModel))")
        lines.append("  desk_pet_size: \(quote(image.deskPetSize))")
        lines.append("  scene_model: \(quote(image.sceneModel))")
        lines.append("  scene_size: \(quote(image.sceneSize))")
        lines.append("  memory_card_model: \(quote(image.memoryCardModel))")
        lines.append("  memory_card_size: \(quote(image.memoryCardSize))")
        lines.append("")
        lines.append("matting:")
        lines.append("  provider: \(quote(matting.provider.rawValue))")
        lines.append("  api_key: \(quote(matting.apiKey))")
        lines.append("  endpoint: \(quote(matting.endpoint))")
        lines.append("")
        return lines.joined(separator: "\n")
    }

    /// Persists the configuration to the writable Application Support location.
    func save() throws {
        let url = Self.defaultURL
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try yamlString.write(to: url, atomically: true, encoding: .utf8)
    }
}

/// Small YAML scalar reader for this deliberately scalar-only configuration.
private enum YAMLScalarParser {
    static func parse(_ source: String) -> [String: String] {
        var result: [String: String] = [:]
        var sections: [Int: String] = [:]
        for rawLine in source.components(separatedBy: .newlines) {
            let line = rawLine.replacingOccurrences(of: "\t", with: "  ")
            let withoutComment = stripComment(line)
            guard !withoutComment.trimmingCharacters(in: .whitespaces).isEmpty else { continue }
            let indent = withoutComment.prefix { $0 == " " }.count
            let content = withoutComment.trimmingCharacters(in: .whitespaces)
            guard let separator = content.firstIndex(of: ":") else { continue }
            let key = String(content[..<separator]).trimmingCharacters(in: .whitespaces)
            let value = String(content[content.index(after: separator)...]).trimmingCharacters(in: .whitespaces)
            if value.isEmpty {
                sections[indent] = key
                sections = sections.filter { $0.key <= indent }
                continue
            }
            let parent = sections.keys.filter { $0 < indent }.max().flatMap { sections[$0] }
            let normalizedKey = parent.map { "\($0).\(key)" } ?? key
            result[key] = unquote(value)
            result[normalizedKey] = unquote(value)
        }
        return result
    }

    private static func stripComment(_ line: String) -> String {
        var quoted = false
        for (index, character) in line.enumerated() {
            if character == "\"" || character == "'" { quoted.toggle() }
            if character == "#" && !quoted { return String(line.prefix(index)) }
        }
        return line
    }

    private static func unquote(_ value: String) -> String {
        guard value.count >= 2 else { return value }
        if (value.first == "\"" && value.last == "\"") || (value.first == "'" && value.last == "'") {
            return String(value.dropFirst().dropLast())
        }
        return value
    }
}
