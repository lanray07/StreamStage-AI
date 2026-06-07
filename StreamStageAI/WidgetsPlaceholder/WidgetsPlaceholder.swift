import Foundation

struct PracticeWidgetSnapshot: Identifiable, Codable {
    var id = UUID()
    var title: String
    var value: String
    var prompt: String
}

enum WidgetPlaceholderRegistry {
    static let snapshots = [
        PracticeWidgetSnapshot(
            title: "Practice reminder",
            value: "Today",
            prompt: "Run one 90-second opener."
        ),
        PracticeWidgetSnapshot(
            title: "Confidence score",
            value: "82",
            prompt: "Hold your pace and answer directly."
        ),
        PracticeWidgetSnapshot(
            title: "Next rehearsal",
            value: "Q&A",
            prompt: "Handle five questions without restarting."
        ),
        PracticeWidgetSnapshot(
            title: "Daily speaking prompt",
            value: "Hook",
            prompt: "Say the promise before the backstory."
        )
    ]
}
