import SwiftData
import SwiftUI

struct ReplayReviewView: View {
    @Query(sort: \PerformanceReview.createdAt, order: .reverse) private var reviews: [PerformanceReview]
    @Query(sort: \SimulationSession.createdAt, order: .reverse) private var sessions: [SimulationSession]
    @Query(sort: \VoiceTranscript.createdAt, order: .reverse) private var transcripts: [VoiceTranscript]

    var body: some View {
        NavigationStack {
            PremiumBackground {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Replay Review")
                            .font(.system(size: 30, weight: .black, design: .rounded))

                        if reviews.isEmpty {
                            EmptyStateView(
                                systemImage: "play.rectangle.on.rectangle",
                                title: "No replay reviews",
                                message: "Completed simulations will save transcripts, feedback, best moments, and weak moments here."
                            )
                            .padding(.top, 80)
                        } else {
                            ForEach(reviews) { review in
                                replayCard(for: review)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Replays")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func replayCard(for review: PerformanceReview) -> some View {
        let session = sessions.first { $0.id == review.sessionId }
        let transcript = transcripts.first { $0.sessionId == review.sessionId }

        return GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(session?.scenario ?? "Rehearsal")
                            .font(.headline)
                        Text(session?.platformStyle ?? "Private simulation")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text("\(review.confidenceScore)")
                        .font(.title2.bold())
                        .foregroundStyle(Color.stageMint)
                }

                HStack(spacing: 10) {
                    MetricMini(title: "Speaking", value: "\(review.speakingScore)", tint: .stageBlue)
                    MetricMini(title: "Engagement", value: "\(review.engagementScore)", tint: .stagePink)
                    MetricMini(title: "Duration", value: duration(session?.duration ?? 0), tint: .stageAmber)
                }

                Text(review.feedback)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(5)

                DisclosureGroup("Transcript") {
                    Text(transcript?.transcript.isEmpty == false ? transcript?.transcript ?? "" : "Transcript placeholder saved with this replay.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }
                .tint(Color.stageMint)
            }
        }
    }

    private func duration(_ value: TimeInterval) -> String {
        let seconds = Int(value)
        return "\(seconds / 60)m"
    }
}

struct AnalyticsDashboardView: View {
    @State private var viewModel = AnalyticsViewModel()
    @Query(sort: \SimulationSession.createdAt, order: .forward) private var sessions: [SimulationSession]
    @Query(sort: \PerformanceReview.createdAt, order: .forward) private var reviews: [PerformanceReview]
    @Query(sort: \VoiceTranscript.createdAt, order: .forward) private var transcripts: [VoiceTranscript]

    var profile: CreatorProfile

    var body: some View {
        NavigationStack {
            PremiumBackground {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Creator Analytics")
                            .font(.system(size: 30, weight: .black, design: .rounded))

                        AnalyticsChartCard(reviews: reviews)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            MetricTile(
                                title: "Confidence trend",
                                value: "\(viewModel.averageConfidence(from: reviews))",
                                subtitle: "Average review score",
                                systemImage: "chart.line.uptrend.xyaxis",
                                tint: .stageMint
                            )

                            MetricTile(
                                title: "Speaking time",
                                value: speakingTime,
                                subtitle: "Total private rehearsal",
                                systemImage: "clock.fill",
                                tint: .stageBlue
                            )

                            MetricTile(
                                title: "Filler words",
                                value: "\(fillerPlaceholder)",
                                subtitle: "Placeholder analysis",
                                systemImage: "text.bubble.fill",
                                tint: .stageAmber
                            )

                            MetricTile(
                                title: "Completed",
                                value: "\(sessions.count)",
                                subtitle: "Practice sessions",
                                systemImage: "checkmark.seal.fill",
                                tint: .stagePink
                            )

                            MetricTile(
                                title: "Audience handling",
                                value: "\(viewModel.averageEngagement(from: reviews))",
                                subtitle: "Mood and pressure",
                                systemImage: "person.2.wave.2.fill",
                                tint: .stagePurple
                            )

                            MetricTile(
                                title: "Sales pitch",
                                value: "\(salesPitchScore)",
                                subtitle: "Sales live placeholder",
                                systemImage: "cart.fill",
                                tint: .stageMint
                            )

                            MetricTile(
                                title: "Q&A score",
                                value: "\(qaScore)",
                                subtitle: "Pressure mode placeholder",
                                systemImage: "questionmark.bubble.fill",
                                tint: .stageBlue
                            )
                        }

                        NavigationLink {
                            ShareProgressCardsView(profile: profile)
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Create Progress Card")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Analytics")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var speakingTime: String {
        let total = Int(sessions.map(\.duration).reduce(0, +))
        return "\(total / 60)m"
    }

    private var fillerPlaceholder: Int {
        transcripts
            .map { appTranscript in
                VoiceAnalysisService().analyze(transcript: appTranscript.transcript).fillerWordCount
            }
            .reduce(0, +)
    }

    private var salesPitchScore: Int {
        let base = reviews.last?.engagementScore ?? 72
        return min(96, base + (sessions.contains { $0.scenario.contains("selling") || $0.scenario.contains("Product") } ? 5 : 0))
    }

    private var qaScore: Int {
        let base = reviews.last?.speakingScore ?? 70
        return min(96, base + (sessions.contains { $0.scenario.contains("Q&A") } ? 6 : 0))
    }
}

struct ScriptBuilderView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ScriptBuilderViewModel()
    @Query(sort: \ScriptDraft.createdAt, order: .reverse) private var drafts: [ScriptDraft]

    var profile: CreatorProfile

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            PremiumBackground {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("AI Script Builder")
                            .font(.system(size: 30, weight: .black, design: .rounded))

                        GlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Category")
                                    .font(.headline)

                                FlowLayout(spacing: 8) {
                                    ForEach(ScriptCategory.allCases) { category in
                                        OptionChip(
                                            title: category.rawValue,
                                            systemImage: "text.quote",
                                            isSelected: viewModel.selectedCategory == category
                                        ) {
                                            viewModel.selectedCategory = category
                                        }
                                    }
                                }

                                Text("Platform")
                                    .font(.headline)

                                FlowLayout(spacing: 8) {
                                    ForEach(PlatformStyle.allCases) { platform in
                                        OptionChip(
                                            title: platform.rawValue,
                                            systemImage: "play.rectangle.fill",
                                            isSelected: viewModel.selectedPlatform == platform
                                        ) {
                                            viewModel.selectedPlatform = platform
                                        }
                                    }
                                }

                                TextField("Script goal", text: $viewModel.goal, axis: .vertical)
                                    .lineLimit(2...4)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }

                        NeonButton(title: viewModel.isGenerating ? "Generating" : "Generate Script", systemImage: "sparkles") {
                            Task {
                                guard let draft = await viewModel.generate(using: appState.scriptBuilderService, creatorType: profile.creatorType) else { return }
                                modelContext.insert(draft)
                                try? modelContext.save()
                            }
                        }

                        if viewModel.isGenerating {
                            LoadingStateView(title: "Building creator-ready script")
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Drafts")
                                .font(.headline)

                            if drafts.isEmpty {
                                EmptyStateView(
                                    systemImage: "text.badge.plus",
                                    title: "No drafts",
                                    message: "Generated scripts will appear here."
                                )
                                .padding(.vertical, 40)
                            } else {
                                ForEach(drafts) { draft in
                                    ScriptCard(draft: draft)
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Scripts")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

struct ShareProgressCardsView: View {
    @Query(sort: \SimulationSession.createdAt, order: .reverse) private var sessions: [SimulationSession]
    @Query(sort: \PerformanceReview.createdAt, order: .reverse) private var reviews: [PerformanceReview]
    @State private var activityItems: [Any] = []
    @State private var showShareSheet = false

    var profile: CreatorProfile

    private var cards: [ProgressCardData] {
        [
            ProgressCardData(
                title: "I completed \(sessions.count) live rehearsals",
                value: "\(sessions.count)",
                subtitle: "Private StreamStage AI practice sessions"
            ),
            ProgressCardData(
                title: "Confidence score improved",
                value: "\(reviews.first?.confidenceScore ?? profile.confidenceLevel)",
                subtitle: "Creator confidence rehearsal score"
            ),
            ProgressCardData(
                title: "Ready for my first TikTok Live",
                value: "LIVE",
                subtitle: "Built in private simulation mode"
            ),
            ProgressCardData(
                title: "Sales pitch upgraded",
                value: "\(reviews.first?.engagementScore ?? 78)",
                subtitle: "Practice card for Instagram, TikTok, LinkedIn, and X/Twitter"
            )
        ]
    }

    var body: some View {
        PremiumBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Progress Cards")
                        .font(.system(size: 30, weight: .black, design: .rounded))

                    ForEach(cards) { card in
                        VStack(alignment: .leading, spacing: 10) {
                            ShareCardPreview(title: card.title, value: card.value, subtitle: card.subtitle)

                            NeonButton(title: "Share", systemImage: "square.and.arrow.up", style: .secondary) {
                                activityItems = [card.shareText]
                                showShareSheet = true
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Share")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: activityItems)
        }
    }
}

struct ProgressCardData: Identifiable {
    let id = UUID()
    var title: String
    var value: String
    var subtitle: String

    var shareText: String {
        "\(title) - \(subtitle). Created with StreamStage AI private rehearsal."
    }
}
