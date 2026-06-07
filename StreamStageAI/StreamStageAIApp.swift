import SwiftData
import SwiftUI

@main
struct StreamStageAIApp: App {
    @State private var appState = AppState()

    private let modelContainer: ModelContainer = {
        let schema = Schema([
            CreatorProfile.self,
            SimulationSession.self,
            ChatMessage.self,
            VoiceTranscript.self,
            PerformanceReview.self,
            ScriptDraft.self,
            SubscriptionState.self
        ])

        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Unable to create StreamStage AI model container: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .modelContainer(modelContainer)
                .preferredColorScheme(.dark)
                .task {
                    await appState.bootstrap()
                }
        }
    }
}
