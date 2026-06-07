import Foundation

struct WatchRehearsalPrompt: Identifiable, Codable {
    var id = UUID()
    var title: String
    var body: String
    var durationSeconds: Int
}

enum WatchPlaceholderRegistry {
    static let prompts = [
        WatchRehearsalPrompt(
            title: "Breathing warm-up",
            body: "Inhale for four, hold for two, speak the first line.",
            durationSeconds: 60
        ),
        WatchRehearsalPrompt(
            title: "Confidence prompt",
            body: "Look up, slow down, answer the question first.",
            durationSeconds: 30
        ),
        WatchRehearsalPrompt(
            title: "Session timer",
            body: "Three-minute practice block.",
            durationSeconds: 180
        )
    ]
}
