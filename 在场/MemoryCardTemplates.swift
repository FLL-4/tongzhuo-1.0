import Foundation

struct MemoryDraftingResult: Equatable {
    let title: String
    let mood: MemoryMood
    let observation: String
    let keyMoment: String
    let keywords: [String]
    let timeHint: String
    let summary: String

    init(
        title: String,
        mood: MemoryMood,
        observation: String,
        keyMoment: String,
        keywords: [String]? = nil,
        date: Date = Date()
    ) {
        self.title = Self.normalized(title)
        self.mood = mood
        self.observation = Self.normalized(observation)
        self.keyMoment = Self.normalized(keyMoment)
        self.keywords = keywords ?? Self.extractKeywords(
            from: [self.title, self.observation, self.keyMoment].joined(separator: " ")
        )
        self.timeHint = Self.timeHint(for: date)
        self.summary = [self.title, mood.title, self.keyMoment]
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }

    var searchCorpus: String {
        [title, observation, keyMoment, keywords.joined(separator: " ")]
            .joined(separator: " ")
            .lowercased()
    }

    private static func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func extractKeywords(from corpus: String) -> [String] {
        let separators = CharacterSet(charactersIn: " ,，。！？!?；;:、\n\t/|")
        let extracted = corpus
            .components(separatedBy: separators)
            .map { normalized($0) }
            .filter { $0.count >= 2 }
        return Array(NSOrderedSet(array: extracted)).compactMap { $0 as? String }
    }

    private static func timeHint(for date: Date) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<11: return "清晨"
        case 11..<14: return "午后"
        case 14..<18: return "傍晚"
        case 18..<23: return "夜色"
        default: return "深夜"
        }
    }
}

enum MemoryCardPromptBuilder {
    static func prompt(for draft: MemoryDraftingResult) -> String {
        """
        Create one square warm pixel-art illustration for a memory card inside a polaroid frame.

        PRODUCT
        - App name: Zaichang.
        - The image represents a private voice memory between two close people.
        - It must feel calm, intimate, and suitable for long-term viewing.

        STYLE LOCK
        - Square 1:1 composition.
        - Warm handcrafted low-resolution pixel art.
        - Crisp pixel edges, limited cozy palette, subtle ordered dithering.
        - Soft practical lighting, quiet everyday objects, restrained emotion.
        - No text, letters, numbers, speech bubbles, UI, watermark, logo, signature.
        - Do not include the white polaroid paper border; the app will render that frame.

        MEMORY CONTENT
        Transcribed voice note: \(draft.observation)
        Key feeling: \(draft.mood.title)
        Moment hint: \(draft.keyMoment.isEmpty ? draft.summary : draft.keyMoment)
        Time hint: \(draft.timeHint)

        OUTPUT
        - One complete square illustration.
        - Center-safe subject, no important detail on the outer 8%.
        - No photorealism, no vector graphics, no collage.
        """
    }
}
