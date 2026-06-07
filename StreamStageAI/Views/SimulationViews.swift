import SwiftData
import SwiftUI

struct SimulationSetupView: View {
    var profile: CreatorProfile
    @State private var viewModel = SimulationSetupViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel

        PremiumBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Live Simulation Setup")
                            .font(.system(size: 30, weight: .black, design: .rounded))
                        Text("Private simulation only.")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.stageMint)
                    }
                    .padding(.top, 8)

                    setupSection(title: "Platform style") {
                        FlowLayout(spacing: 8) {
                            ForEach(PlatformStyle.allCases) { platform in
                                OptionChip(
                                    title: platform.rawValue,
                                    systemImage: "rectangle.inset.filled.and.person.filled",
                                    isSelected: viewModel.platformStyle == platform
                                ) {
                                    viewModel.platformStyle = platform
                                }
                            }
                        }
                    }

                    setupSection(title: "Audience tone") {
                        FlowLayout(spacing: 8) {
                            ForEach(AudienceTone.allCases) { tone in
                                OptionChip(
                                    title: tone.rawValue,
                                    systemImage: "bubble.left.and.bubble.right.fill",
                                    isSelected: viewModel.audienceTone == tone
                                ) {
                                    viewModel.audienceTone = tone
                                }
                            }
                        }
                    }

                    setupSection(title: "Audience size") {
                        HStack(spacing: 8) {
                            ForEach(viewModel.audienceSizes, id: \.self) { size in
                                OptionChip(
                                    title: size.formatted(),
                                    systemImage: "eye.fill",
                                    isSelected: viewModel.audienceSize == size
                                ) {
                                    viewModel.audienceSize = size
                                }
                            }
                        }
                    }

                    setupSection(title: "Scenario") {
                        FlowLayout(spacing: 8) {
                            ForEach(AudienceScenario.allCases) { scenario in
                                OptionChip(
                                    title: scenario.rawValue,
                                    systemImage: "sparkles.tv",
                                    isSelected: viewModel.scenario == scenario
                                ) {
                                    viewModel.scenario = scenario
                                }
                            }
                        }
                    }

                    NavigationLink {
                        LiveRoomView(
                            profile: profile,
                            platformStyle: viewModel.platformStyle,
                            audienceTone: viewModel.audienceTone,
                            audienceSize: viewModel.audienceSize,
                            scenario: viewModel.scenario
                        )
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start Private Simulation")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(
                            LinearGradient(
                                colors: [.stagePink, .stagePurple, .stageBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                        )
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
            }
        }
        .navigationTitle("Setup")
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func setupSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text(title)
                    .font(.headline)
                content()
            }
        }
    }
}

struct LiveRoomView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var profile: CreatorProfile
    var platformStyle: PlatformStyle
    var audienceTone: AudienceTone
    var audienceSize: Int
    var scenario: AudienceScenario

    @State private var didStart = false
    @State private var isFinishing = false
    @State private var completedReview: PerformanceReview?
    @State private var showCompletedReview = false

    var body: some View {
        PremiumBackground {
            ScrollView {
                VStack(spacing: 16) {
                    LiveSimulationView(
                        engine: appState.liveSimulationEngine,
                        speechService: appState.speechRecognitionService,
                        waveformManager: appState.waveformManager,
                        audioLevelMeter: appState.audioLevelMeter
                    ) {
                        Task {
                            await finishSession()
                        }
                    }

                    if isFinishing {
                        LoadingStateView(title: "Generating performance review")
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle(platformStyle.rawValue)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            guard !didStart else { return }
            didStart = true
            appState.liveSimulationEngine.start(
                creatorType: profile.creatorType,
                platformStyle: platformStyle,
                audienceTone: audienceTone,
                audienceSize: audienceSize,
                scenario: scenario
            )
        }
        .sheet(isPresented: $showCompletedReview) {
            if let completedReview {
                SessionCompleteView(review: completedReview) {
                    showCompletedReview = false
                    appState.liveSimulationEngine.reset()
                    dismiss()
                }
                .presentationDetents([.medium, .large])
            }
        }
        .onDisappear {
            guard !showCompletedReview else { return }
            appState.liveSimulationEngine.reset()
            appState.speechRecognitionService.stop()
            appState.waveformManager.stop()
            appState.audioLevelMeter.stop()
        }
    }

    private func finishSession() async {
        guard !isFinishing else { return }
        guard let snapshot = appState.liveSimulationEngine.finish() else { return }

        isFinishing = true
        appState.speechRecognitionService.stop()
        appState.waveformManager.stop()
        appState.audioLevelMeter.stop()

        let transcriptText = appState.speechRecognitionService.editedTranscript.isEmpty
            ? appState.speechRecognitionService.transcript
            : appState.speechRecognitionService.editedTranscript

        modelContext.insert(snapshot.session)
        snapshot.messages.forEach { modelContext.insert($0) }

        let transcript = VoiceTranscript(
            sessionId: snapshot.session.id,
            transcript: transcriptText,
            aiSummary: "Private rehearsal transcript captured for performance review."
        )
        modelContext.insert(transcript)

        let review = await appState.performanceCoachService.generateReview(
            session: snapshot.session,
            transcript: transcriptText,
            creatorType: profile.creatorType
        )

        modelContext.insert(review)

        do {
            try modelContext.save()
            completedReview = review
            showCompletedReview = true
        } catch {
            appState.globalErrorMessage = error.localizedDescription
        }

        isFinishing = false
    }
}

struct SessionCompleteView: View {
    var review: PerformanceReview
    var close: () -> Void

    var body: some View {
        PremiumBackground {
            VStack(alignment: .leading, spacing: 18) {
                Text("Replay Review")
                    .font(.system(size: 30, weight: .black, design: .rounded))

                PerformanceScoreCard(
                    title: "Confidence",
                    score: review.confidenceScore,
                    tint: .stagePink,
                    detail: review.betterOpeningLine
                )

                PerformanceScoreCard(
                    title: "Speaking",
                    score: review.speakingScore,
                    tint: .stageBlue,
                    detail: review.nextPracticeDrill
                )

                PerformanceScoreCard(
                    title: "Engagement",
                    score: review.engagementScore,
                    tint: .stageMint,
                    detail: review.betterClosingCTA
                )

                GlassCard {
                    Text(review.feedback)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                NeonButton(title: "Back to Studio", systemImage: "arrow.left", action: close)
            }
            .padding(20)
        }
    }
}
