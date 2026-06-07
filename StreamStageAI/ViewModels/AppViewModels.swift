import Foundation
import Observation

enum AppTab: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case analytics = "Analytics"
    case scripts = "Scripts"
    case replays = "Replays"
    case settings = "Settings"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .dashboard: "sparkles"
        case .analytics: "chart.line.uptrend.xyaxis"
        case .scripts: "text.quote"
        case .replays: "play.rectangle"
        case .settings: "gearshape"
        }
    }
}

@MainActor
@Observable
final class AppState {
    var selectedTab: AppTab = .dashboard
    var showPaywall = false
    var globalErrorMessage: String?

    @ObservationIgnored let aiService: any AIService
    @ObservationIgnored let audienceSimulationService: AudienceSimulationService
    @ObservationIgnored let performanceCoachService: PerformanceCoachService
    @ObservationIgnored let scriptBuilderService: ScriptBuilderService
    @ObservationIgnored let salesPracticeService = SalesPracticeService()
    @ObservationIgnored let qaPressureService = QAPressureService()
    @ObservationIgnored let voiceAnalysisService = VoiceAnalysisService()
    @ObservationIgnored let liveSimulationEngine: LiveSimulationEngine

    let subscriptionService = SubscriptionService()
    let notificationService = LocalNotificationService()
    let speechRecognitionService = SpeechRecognitionService()
    let voiceRecordingService = VoiceRecordingService()
    let waveformManager = WaveformAnimationManager()
    let audioLevelMeter = AudioLevelMeter()

    init(aiService: any AIService = MockAIService()) {
        self.aiService = aiService
        let audienceSimulationService = AudienceSimulationService(aiService: aiService)
        self.audienceSimulationService = audienceSimulationService
        self.performanceCoachService = PerformanceCoachService(aiService: aiService)
        self.scriptBuilderService = ScriptBuilderService(aiService: aiService)
        self.liveSimulationEngine = LiveSimulationEngine(audienceService: audienceSimulationService)
    }

    func bootstrap() async {
        await subscriptionService.loadProducts()
        await notificationService.refreshAuthorizationStatus()
    }
}

@MainActor
@Observable
final class OnboardingViewModel {
    var creatorType: CreatorType = .tiktokCreator
    var mainGoal: CreatorGoal = .buildConfidence
    var confidenceLevel = 54.0

    func makeProfile() -> CreatorProfile {
        let scenario: AudienceScenario
        let audienceMode: AudienceTone

        switch mainGoal {
        case .practiceSalesLives, .practiceProductDemos:
            scenario = .tiktokShopSelling
            audienceMode = .salesFocused
        case .handleQuestions:
            scenario = .qaSession
            audienceMode = .curious
        case .improveAudienceEngagement:
            scenario = .firstLiveStream
            audienceMode = .highEnergy
        case .improveSpeaking, .reduceNerves, .buildConfidence:
            scenario = .firstLiveStream
            audienceMode = .supportive
        }

        return CreatorProfile(
            creatorType: creatorType.rawValue,
            mainGoal: mainGoal.rawValue,
            confidenceLevel: Int(confidenceLevel),
            firstPracticeScenario: scenario.rawValue,
            recommendedAudienceMode: audienceMode.rawValue
        )
    }
}

@MainActor
@Observable
final class SimulationSetupViewModel {
    var platformStyle: PlatformStyle = .tiktokLive
    var audienceTone: AudienceTone = .supportive
    var audienceSize = 100
    var scenario: AudienceScenario = .firstLiveStream
    let audienceSizes = [10, 100, 1_000, 10_000]
}

@MainActor
@Observable
final class VoicePracticeViewModel {
    var selectedDrill = "Opening line practice"
    var editedTranscript = ""

    let drills = [
        "Opening line practice",
        "Breathing prompt",
        "Vocal clarity",
        "Product pitch",
        "Closing statement"
    ]
}

@MainActor
@Observable
final class ScriptBuilderViewModel {
    var selectedCategory: ScriptCategory = .liveOpening
    var selectedPlatform: PlatformStyle = .tiktokLive
    var goal = "Make the first 30 seconds sharper"
    var isGenerating = false
    var errorMessage: String?

    func generate(using service: ScriptBuilderService, creatorType: String) async -> ScriptDraft? {
        isGenerating = true
        defer { isGenerating = false }

        return await service.buildScript(
            category: selectedCategory,
            creatorType: creatorType,
            platformStyle: selectedPlatform,
            goal: goal
        )
    }
}

@MainActor
@Observable
final class QAPressureViewModel {
    var selectedLevel: QAPressureLevel = .beginner
    var activeQuestionIndex = 0

    func nextQuestion(total: Int) {
        guard total > 0 else { return }
        activeQuestionIndex = (activeQuestionIndex + 1) % total
    }
}

@MainActor
@Observable
final class AnalyticsViewModel {
    func averageConfidence(from reviews: [PerformanceReview]) -> Int {
        guard !reviews.isEmpty else { return 0 }
        return reviews.map(\.confidenceScore).reduce(0, +) / reviews.count
    }

    func averageSpeaking(from reviews: [PerformanceReview]) -> Int {
        guard !reviews.isEmpty else { return 0 }
        return reviews.map(\.speakingScore).reduce(0, +) / reviews.count
    }

    func averageEngagement(from reviews: [PerformanceReview]) -> Int {
        guard !reviews.isEmpty else { return 0 }
        return reviews.map(\.engagementScore).reduce(0, +) / reviews.count
    }
}
