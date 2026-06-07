import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \SimulationSession.createdAt, order: .reverse) private var sessions: [SimulationSession]
    @Query(sort: \PerformanceReview.createdAt, order: .reverse) private var reviews: [PerformanceReview]

    var profile: CreatorProfile

    private var latestReview: PerformanceReview? { reviews.first }

    var body: some View {
        NavigationStack {
            PremiumBackground {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header

                        UpgradeBanner {
                            appState.showPaywall = true
                        }

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            MetricTile(
                                title: "Confidence",
                                value: "\(latestReview?.confidenceScore ?? profile.confidenceLevel)",
                                subtitle: "Current rehearsal score",
                                systemImage: "bolt.heart.fill",
                                tint: .stagePink
                            )

                            MetricTile(
                                title: "Speaking",
                                value: "\(latestReview?.speakingScore ?? 68)",
                                subtitle: "Pace and clarity",
                                systemImage: "waveform",
                                tint: .stageBlue
                            )

                            MetricTile(
                                title: "Engagement",
                                value: "\(latestReview?.engagementScore ?? 72)",
                                subtitle: "Audience handling",
                                systemImage: "person.2.fill",
                                tint: .stageMint
                            )

                            MetricTile(
                                title: "Sessions",
                                value: "\(sessions.count)",
                                subtitle: appState.subscriptionService.statusMessage,
                                systemImage: "play.rectangle.fill",
                                tint: .stageAmber
                            )
                        }

                        quickActions

                        coachingInsight

                        recentReviews
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Studio")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(profile.creatorType)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.stageMint)
            Text("Step on stage before the world sees you.")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .minimumScaleFactor(0.7)
            Text("Next: \(profile.firstPracticeScenario) with a \(profile.recommendedAudienceMode.lowercased()) audience.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick actions")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                QuickActionLink(title: "Start Live Simulation", systemImage: "dot.radiowaves.left.and.right") {
                    SimulationSetupView(profile: profile)
                }

                QuickActionLink(title: "Voice Warm-Up", systemImage: "mic.and.signal.meter") {
                    VoiceWarmUpView(profile: profile)
                }

                QuickActionLink(title: "Product Demo Practice", systemImage: "bag.fill") {
                    SalesPracticeView(profile: profile)
                }

                QuickActionLink(title: "Q&A Practice", systemImage: "questionmark.bubble.fill") {
                    QAPressureView(profile: profile)
                }

                QuickActionLink(title: "Sales Live Practice", systemImage: "cart.fill") {
                    SalesPracticeView(profile: profile)
                }

                QuickActionLink(title: "Replay Review", systemImage: "play.rectangle.on.rectangle") {
                    ReplayReviewView()
                }
            }
        }
    }

    private var coachingInsight: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("AI coaching insight", systemImage: "sparkle.magnifyingglass")
                    .font(.headline)

                Text(latestReview?.feedback ?? "Run your first private simulation to unlock tailored coaching, stronger openings, cleaner CTAs, and pressure-handling drills.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(5)
            }
        }
    }

    private var recentReviews: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent replay reviews")
                .font(.headline)

            if reviews.isEmpty {
                EmptyStateView(
                    systemImage: "play.slash",
                    title: "No replays yet",
                    message: "Complete a private rehearsal to create your first review."
                )
                .padding(.vertical, 24)
            } else {
                ForEach(reviews.prefix(3)) { review in
                    PerformanceScoreCard(
                        title: "Session review",
                        score: review.confidenceScore,
                        tint: .stageMint,
                        detail: review.nextPracticeDrill
                    )
                }
            }
        }
    }
}

struct QuickActionLink<Destination: View>: View {
    var title: String
    var systemImage: String
    private let destination: Destination

    init(title: String, systemImage: String, @ViewBuilder destination: () -> Destination) {
        self.title = title
        self.systemImage = systemImage
        self.destination = destination()
    }

    var body: some View {
        NavigationLink {
            destination
        } label: {
            GlassCard(padding: 14) {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: systemImage)
                        .font(.title3)
                        .foregroundStyle(Color.stagePink)
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, minHeight: 74, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}
