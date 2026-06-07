import Foundation
import Observation

@MainActor
@Observable
final class LiveSimulationEngine {
    var currentSession: SimulationSession?
    var chatMessages: [ChatMessage] = []
    var elapsedSeconds = 0
    var viewerCount = 10
    var audienceMood = 0.68
    var confidenceLevel = 0.64
    var currentPrompt = "Open with one clear promise."
    var isRunning = false
    var isGeneratingChat = false

    @ObservationIgnored private let audienceService: AudienceSimulationService
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var chatTask: Task<Void, Never>?
    @ObservationIgnored private var configuredCreatorType = CreatorType.tiktokCreator.rawValue
    @ObservationIgnored private var configuredPlatform = PlatformStyle.tiktokLive
    @ObservationIgnored private var configuredTone = AudienceTone.supportive
    @ObservationIgnored private var configuredScenario = AudienceScenario.firstLiveStream

    private let prompts = [
        "Open with one clear promise.",
        "Answer the newest question in one sentence first.",
        "Bring late viewers back with a clean recap.",
        "Turn the objection into a benefit.",
        "Name the next action without overexplaining.",
        "Pause for two beats before the strongest line.",
        "Give one example from a real audience moment."
    ]

    init(audienceService: AudienceSimulationService) {
        self.audienceService = audienceService
    }

    func start(
        creatorType: String,
        platformStyle: PlatformStyle,
        audienceTone: AudienceTone,
        audienceSize: Int,
        scenario: AudienceScenario
    ) {
        stopTimer()
        chatTask?.cancel()

        configuredCreatorType = creatorType
        configuredPlatform = platformStyle
        configuredTone = audienceTone
        configuredScenario = scenario

        currentSession = SimulationSession(
            platformStyle: platformStyle.rawValue,
            audienceTone: audienceTone.rawValue,
            audienceSize: audienceSize,
            scenario: scenario.rawValue
        )

        chatMessages = []
        elapsedSeconds = 0
        viewerCount = audienceSize
        audienceMood = 0.68
        confidenceLevel = 0.64
        currentPrompt = prompts[0]
        isRunning = true

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }

        generateChatBurst(transcript: "")
    }

    func ingestTranscript(_ transcript: String) {
        guard let sessionId = currentSession?.id else { return }
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 12 else { return }

        if chatMessages.last?.isUser != true {
            chatMessages.append(
                ChatMessage(
                    sessionId: sessionId,
                    content: trimmed,
                    tone: "Creator response",
                    isUser: true
                )
            )
        }
    }

    func finish(scoreOverride: Int? = nil) -> (session: SimulationSession, messages: [ChatMessage])? {
        guard let session = currentSession else { return nil }

        session.duration = TimeInterval(elapsedSeconds)
        session.score = scoreOverride ?? Int((confidenceLevel * 48) + (audienceMood * 48) + Double.random(in: 0...4))

        isRunning = false
        stopTimer()
        chatTask?.cancel()

        return (session, chatMessages)
    }

    func reset() {
        currentSession = nil
        chatMessages = []
        elapsedSeconds = 0
        viewerCount = 10
        audienceMood = 0.68
        confidenceLevel = 0.64
        currentPrompt = prompts[0]
        isRunning = false
        stopTimer()
        chatTask?.cancel()
    }

    private func tick() {
        guard isRunning else { return }

        elapsedSeconds += 1
        currentPrompt = prompts[(elapsedSeconds / 8) % prompts.count]

        let volatility = max(1, Int(Double(viewerCount) * 0.018))
        viewerCount = max(1, viewerCount + Int.random(in: -volatility...volatility))

        audienceMood = clamp(audienceMood + Double.random(in: -0.04...0.05))
        confidenceLevel = clamp(confidenceLevel + Double.random(in: -0.035...0.045))

        if elapsedSeconds % 6 == 0 {
            generateChatBurst(transcript: "")
        }
    }

    private func generateChatBurst(transcript: String) {
        guard !isGeneratingChat else { return }

        isGeneratingChat = true
        chatTask = Task { [audienceService, configuredCreatorType, configuredPlatform, configuredTone, configuredScenario] in
            let generated = await audienceService.generateBurst(
                creatorType: configuredCreatorType,
                platformStyle: configuredPlatform,
                audienceTone: configuredTone,
                transcript: transcript,
                scenario: configuredScenario
            )

            await MainActor.run {
                self.appendGeneratedMessages(generated)
                self.isGeneratingChat = false
            }
        }
    }

    private func appendGeneratedMessages(_ generated: [GeneratedChatMessage]) {
        guard let sessionId = currentSession?.id else { return }

        let mapped = generated.map {
            ChatMessage(
                sessionId: sessionId,
                content: $0.content,
                tone: $0.tone
            )
        }

        chatMessages.append(contentsOf: mapped)

        if mapped.contains(where: { $0.content.localizedCaseInsensitiveContains("worth") || $0.content.localizedCaseInsensitiveContains("trust") }) {
            audienceMood = clamp(audienceMood - 0.04)
        } else {
            audienceMood = clamp(audienceMood + 0.03)
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func clamp(_ value: Double) -> Double {
        min(1.0, max(0.08, value))
    }
}
