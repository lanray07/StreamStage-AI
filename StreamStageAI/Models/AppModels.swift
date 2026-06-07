import Foundation
import SwiftData

enum CreatorType: String, CaseIterable, Identifiable, Codable {
    case tiktokCreator = "TikTok creator"
    case youtuber = "YouTuber"
    case twitchStreamer = "Twitch streamer"
    case instagramCreator = "Instagram creator"
    case tiktokShopSeller = "TikTok Shop seller"
    case coach = "Coach"
    case educator = "Educator"
    case founder = "Founder"
    case onlineSeller = "Online seller"

    var id: String { rawValue }
}

enum CreatorGoal: String, CaseIterable, Identifiable, Codable {
    case buildConfidence = "Build confidence"
    case practiceSalesLives = "Practice sales lives"
    case improveSpeaking = "Improve speaking"
    case handleQuestions = "Handle questions"
    case reduceNerves = "Reduce nerves"
    case practiceProductDemos = "Practice product demos"
    case improveAudienceEngagement = "Improve audience engagement"

    var id: String { rawValue }
}

enum PlatformStyle: String, CaseIterable, Identifiable, Codable {
    case tiktokLive = "TikTok Live"
    case youtubeLive = "YouTube Live"
    case twitch = "Twitch"
    case instagramLive = "Instagram Live"
    case webinar = "Webinar"
    case tiktokShop = "TikTok Shop"

    var id: String { rawValue }
}

enum AudienceTone: String, CaseIterable, Identifiable, Codable {
    case supportive = "Supportive"
    case curious = "Curious"
    case chaotic = "Chaotic"
    case skeptical = "Skeptical"
    case funny = "Funny"
    case quiet = "Quiet"
    case highEnergy = "High-energy"
    case salesFocused = "Sales-focused"
    case expertAudience = "Expert audience"

    var id: String { rawValue }
}

enum AudienceScenario: String, CaseIterable, Identifiable, Codable {
    case firstLiveStream = "First live stream"
    case productLaunch = "Product launch"
    case tiktokShopSelling = "TikTok Shop selling session"
    case coachingWebinar = "Coaching webinar"
    case gamingStream = "Gaming stream"
    case qaSession = "Q&A session"
    case courseLaunch = "Course launch"
    case founderDemo = "Founder demo"

    var id: String { rawValue }
}

enum QAPressureLevel: String, CaseIterable, Identifiable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case intense = "Intense"
    case hostileButSafe = "Hostile but safe"
    case expertAudience = "Expert audience"

    var id: String { rawValue }
}

enum SubscriptionPlan: String, CaseIterable, Identifiable, Codable {
    case free = "Free"
    case creatorPro = "Creator Pro"
    case streamElite = "Stream Elite"

    var id: String { rawValue }

    var productIDs: [String] {
        switch self {
        case .free:
            []
        case .creatorPro:
            ["com.streamstage.creatorpro.monthly", "com.streamstage.creatorpro.yearly"]
        case .streamElite:
            ["com.streamstage.streamelite.monthly"]
        }
    }
}

enum ScriptCategory: String, CaseIterable, Identifiable, Codable {
    case liveOpening = "Live stream opening"
    case productDemo = "Product demo"
    case qaPrompts = "Q&A prompts"
    case salesPitch = "Sales pitch"
    case closingCTA = "Closing CTA"
    case contentOutline = "Content outline"

    var id: String { rawValue }
}

@Model
final class CreatorProfile {
    @Attribute(.unique) var id: UUID
    var creatorType: String
    var mainGoal: String
    var confidenceLevel: Int
    var firstPracticeScenario: String
    var recommendedAudienceMode: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        creatorType: String,
        mainGoal: String,
        confidenceLevel: Int = 54,
        firstPracticeScenario: String,
        recommendedAudienceMode: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.creatorType = creatorType
        self.mainGoal = mainGoal
        self.confidenceLevel = confidenceLevel
        self.firstPracticeScenario = firstPracticeScenario
        self.recommendedAudienceMode = recommendedAudienceMode
        self.createdAt = createdAt
    }
}

@Model
final class SimulationSession {
    @Attribute(.unique) var id: UUID
    var platformStyle: String
    var audienceTone: String
    var audienceSize: Int
    var duration: TimeInterval
    var score: Int
    var scenario: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        platformStyle: String,
        audienceTone: String,
        audienceSize: Int,
        duration: TimeInterval = 0,
        score: Int = 0,
        scenario: String = AudienceScenario.firstLiveStream.rawValue,
        createdAt: Date = .now
    ) {
        self.id = id
        self.platformStyle = platformStyle
        self.audienceTone = audienceTone
        self.audienceSize = audienceSize
        self.duration = duration
        self.score = score
        self.scenario = scenario
        self.createdAt = createdAt
    }
}

@Model
final class ChatMessage {
    @Attribute(.unique) var id: UUID
    var sessionId: UUID
    var content: String
    var tone: String
    var timestamp: Date
    var isUser: Bool

    init(
        id: UUID = UUID(),
        sessionId: UUID,
        content: String,
        tone: String,
        timestamp: Date = .now,
        isUser: Bool = false
    ) {
        self.id = id
        self.sessionId = sessionId
        self.content = content
        self.tone = tone
        self.timestamp = timestamp
        self.isUser = isUser
    }
}

@Model
final class VoiceTranscript {
    @Attribute(.unique) var id: UUID
    var sessionId: UUID
    var transcript: String
    var aiSummary: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        sessionId: UUID,
        transcript: String,
        aiSummary: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.sessionId = sessionId
        self.transcript = transcript
        self.aiSummary = aiSummary
        self.createdAt = createdAt
    }
}

@Model
final class PerformanceReview {
    @Attribute(.unique) var id: UUID
    var sessionId: UUID
    var confidenceScore: Int
    var speakingScore: Int
    var engagementScore: Int
    var feedback: String
    var betterOpeningLine: String
    var betterClosingCTA: String
    var nextPracticeDrill: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        sessionId: UUID,
        confidenceScore: Int,
        speakingScore: Int,
        engagementScore: Int,
        feedback: String,
        betterOpeningLine: String,
        betterClosingCTA: String,
        nextPracticeDrill: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.sessionId = sessionId
        self.confidenceScore = confidenceScore
        self.speakingScore = speakingScore
        self.engagementScore = engagementScore
        self.feedback = feedback
        self.betterOpeningLine = betterOpeningLine
        self.betterClosingCTA = betterClosingCTA
        self.nextPracticeDrill = nextPracticeDrill
        self.createdAt = createdAt
    }
}

@Model
final class ScriptDraft {
    @Attribute(.unique) var id: UUID
    var title: String
    var content: String
    var category: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        category: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.category = category
        self.createdAt = createdAt
    }
}

@Model
final class SubscriptionState {
    @Attribute(.unique) var id: UUID
    var plan: String
    var isActive: Bool

    init(id: UUID = UUID(), plan: String = SubscriptionPlan.free.rawValue, isActive: Bool = false) {
        self.id = id
        self.plan = plan
        self.isActive = isActive
    }
}
