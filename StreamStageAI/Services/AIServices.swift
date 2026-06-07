import Foundation

struct AIRequest: Codable {
    var module: String
    var creatorType: String
    var audienceTone: String
    var platformStyle: String
    var voiceTranscript: String
    var sessionContext: String
}

struct GeneratedChatMessage: Identifiable, Codable {
    var id: UUID
    var content: String
    var tone: String

    init(id: UUID = UUID(), content: String, tone: String) {
        self.id = id
        self.content = content
        self.tone = tone
    }
}

struct AIResponse: Codable {
    var chatMessages: [GeneratedChatMessage]
    var performanceFeedback: [String]
    var script: String
    var score: Int
}

protocol AIService {
    func respond(to request: AIRequest) async throws -> AIResponse
}

enum StreamStageServiceError: LocalizedError {
    case invalidResponse
    case failedVerification

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "The AI service returned an invalid response."
        case .failedVerification:
            "The StoreKit transaction could not be verified."
        }
    }
}

final class MockAIService: AIService {
    private let internalPrompt = "You are StreamStage AI, a live stream rehearsal coach and simulated audience engine. Help creators practise live communication, Q&A handling, sales pitches, and audience engagement in a private simulated environment. Do not help users fake public engagement or deceive real viewers."

    func respond(to request: AIRequest) async throws -> AIResponse {
        try await Task.sleep(for: .milliseconds(280))

        let messages = generateMessages(for: request)
        let score = Int.random(in: 72...94)

        return AIResponse(
            chatMessages: messages,
            performanceFeedback: generateFeedback(for: request, score: score),
            script: generateScript(for: request),
            score: score
        )
    }

    private func generateMessages(for request: AIRequest) -> [GeneratedChatMessage] {
        let tone = AudienceTone(rawValue: request.audienceTone) ?? .curious
        let platform = request.platformStyle

        let shared = [
            "Can you say that again in one punchier line?",
            "What makes this different from everything else out there?",
            "I like this angle. Can you show a real example?",
            "What should we do first if we are new to this?",
            "How would you explain this to someone joining late?"
        ]

        let toneSpecific: [String]
        switch tone {
        case .supportive:
            toneSpecific = [
                "You are coming across really clear.",
                "That opener feels confident.",
                "Keep going, this is landing.",
                "The story makes it easier to follow."
            ]
        case .curious:
            toneSpecific = [
                "What inspired this idea?",
                "Who is this best for?",
                "Can you compare two options?",
                "What would you avoid doing?"
            ]
        case .chaotic:
            toneSpecific = [
                "Wait, what are we talking about now?",
                "Show the main thing!",
                "Say the price again.",
                "Can you answer the pinned question?"
            ]
        case .skeptical:
            toneSpecific = [
                "How do we know this works?",
                "That sounds expensive. Why is it worth it?",
                "What is the catch?",
                "I am not convinced yet."
            ]
        case .funny:
            toneSpecific = [
                "This chat has officially joined rehearsal mode.",
                "Give us the trailer voice version.",
                "Rate your own pitch out of ten.",
                "That transition needs a drum sting."
            ]
        case .quiet:
            toneSpecific = [
                "Watching while working.",
                "Can you recap the first point?",
                "This is helpful.",
                "I missed the intro."
            ]
        case .highEnergy:
            toneSpecific = [
                "Run it back!",
                "This is the part people need.",
                "Drop the best tip.",
                "More examples!"
            ]
        case .salesFocused:
            toneSpecific = [
                "Does it come with a guarantee?",
                "Can I use this today?",
                "What is included if I buy now?",
                "Why should I choose this over the cheaper one?"
            ]
        case .expertAudience:
            toneSpecific = [
                "What is the strongest evidence for that claim?",
                "How would this scale?",
                "What assumptions are you making?",
                "Can you define the edge cases?"
            ]
        }

        let platformLine = "Private \(platform) rehearsal: simulated viewer reaction only."
        let pool = ([platformLine] + shared + toneSpecific).shuffled()

        return pool.prefix(Int.random(in: 3...5)).map {
            GeneratedChatMessage(content: $0, tone: tone.rawValue)
        }
    }

    private func generateFeedback(for request: AIRequest, score: Int) -> [String] {
        let transcriptSignal = request.voiceTranscript.isEmpty ? "Use a stronger spoken hook in the first 10 seconds." : "Your spoken answer had a clear through-line. Tighten the second sentence."

        return [
            "Confidence score: \(score). Your best moments came when you answered directly before adding context.",
            transcriptSignal,
            "Audience handling: acknowledge pressure comments quickly, then return to your main point.",
            "Better opening: \"Give me 60 seconds and I will show you the exact mistake I see creators make before going live.\"",
            "Better close: \"Comment practice if you want the rehearsal checklist, and I will send the next step.\"",
            "Next drill: repeat the opening three times, each version shorter than the last."
        ]
    }

    private func generateScript(for request: AIRequest) -> String {
        let creatorType = request.creatorType.isEmpty ? "creator" : request.creatorType
        let platform = request.platformStyle.isEmpty ? "live stream" : request.platformStyle

        return """
        Hook: If you are joining this \(platform), here is the one thing I want you to leave with.

        Context: I am a \(creatorType) practising a clear, useful live moment that feels natural under pressure.

        Demo: First, I will show the problem. Then I will show the simple fix. Watch the before-and-after.

        Audience bridge: Drop your question as soon as it comes up. I will answer the most useful ones live.

        CTA: If this helped, save it and come back for the next rehearsal.
        """
    }
}

struct RemoteAIService: AIService {
    var endpoint: URL = URL(string: "https://YOUR_BACKEND_URL.com/streamstage-ai")!

    func respond(to request: AIRequest) async throws -> AIResponse {
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw StreamStageServiceError.invalidResponse
        }

        return try JSONDecoder().decode(AIResponse.self, from: data)
    }
}

struct AudienceSimulationService {
    let aiService: any AIService

    func generateBurst(
        creatorType: String,
        platformStyle: PlatformStyle,
        audienceTone: AudienceTone,
        transcript: String,
        scenario: AudienceScenario
    ) async -> [GeneratedChatMessage] {
        let request = AIRequest(
            module: "audience_simulation",
            creatorType: creatorType,
            audienceTone: audienceTone.rawValue,
            platformStyle: platformStyle.rawValue,
            voiceTranscript: transcript,
            sessionContext: scenario.rawValue
        )

        do {
            return try await aiService.respond(to: request).chatMessages
        } catch {
            return [
                GeneratedChatMessage(
                    content: "Private simulation paused for a moment. Reset your point and continue.",
                    tone: AudienceTone.supportive.rawValue
                )
            ]
        }
    }
}

struct PerformanceCoachService {
    let aiService: any AIService

    func generateReview(
        session: SimulationSession,
        transcript: String,
        creatorType: String
    ) async -> PerformanceReview {
        let request = AIRequest(
            module: "performance_coach",
            creatorType: creatorType,
            audienceTone: session.audienceTone,
            platformStyle: session.platformStyle,
            voiceTranscript: transcript,
            sessionContext: session.scenario
        )

        let response = try? await aiService.respond(to: request)
        let score = response?.score ?? Int.random(in: 70...90)
        let feedback = (response?.performanceFeedback ?? []).joined(separator: "\n\n")

        return PerformanceReview(
            sessionId: session.id,
            confidenceScore: score,
            speakingScore: max(60, score - Int.random(in: 0...8)),
            engagementScore: min(98, score + Int.random(in: 0...6)),
            feedback: feedback.isEmpty ? "You stayed present, answered pressure moments, and kept the rehearsal moving." : feedback,
            betterOpeningLine: "Give me 60 seconds and I will make this easier to understand.",
            betterClosingCTA: "Save this, then practise the same answer in your own words.",
            nextPracticeDrill: "Run a 90-second opening with one example and one audience question."
        )
    }
}

struct ScriptBuilderService {
    let aiService: any AIService

    func buildScript(
        category: ScriptCategory,
        creatorType: String,
        platformStyle: PlatformStyle,
        goal: String
    ) async -> ScriptDraft {
        let request = AIRequest(
            module: "script_builder",
            creatorType: creatorType,
            audienceTone: AudienceTone.curious.rawValue,
            platformStyle: platformStyle.rawValue,
            voiceTranscript: "",
            sessionContext: "\(category.rawValue): \(goal)"
        )

        let response = try? await aiService.respond(to: request)
        let content = response?.script ?? "Open with the audience problem, show one proof point, ask for a question, and close with one clear next step."

        return ScriptDraft(
            title: category.rawValue,
            content: content,
            category: category.rawValue
        )
    }
}

struct SalesPracticeService {
    func buyerObjections(for platformStyle: PlatformStyle) -> [String] {
        [
            "That price feels high. What makes it worth it?",
            "How fast would I see a result?",
            "Can you show exactly what is included?",
            "I am interested, but I need to think about it.",
            "What happens if this does not work for me?",
            "Is this better for beginners or advanced users?",
            "Can you compare it with the cheaper option on \(platformStyle.rawValue)?"
        ]
    }

    func urgencyPrompts() -> [String] {
        [
            "Explain the limited-time offer without sounding pushy.",
            "Give a customer-friendly guarantee line.",
            "Turn a price objection into a benefit explanation.",
            "Close with one clear action."
        ]
    }
}

struct QAPressureService {
    func questions(for level: QAPressureLevel, creatorType: String) -> [String] {
        let base = [
            "Who is this for?",
            "Why should anyone trust your take?",
            "What is the fastest way to start?",
            "What would you do if someone disagrees?",
            "Can you explain that without jargon?"
        ]

        let advanced = [
            "What are the limits of your advice?",
            "What evidence would change your mind?",
            "How do you handle a bad-faith question live?",
            "Where does this approach break down?",
            "What would you tell an expert \(creatorType) who already knows the basics?"
        ]

        switch level {
        case .beginner:
            return Array(base.prefix(4))
        case .intermediate:
            return base + Array(advanced.prefix(2))
        case .intense, .hostileButSafe, .expertAudience:
            return (base + advanced).shuffled()
        }
    }
}
