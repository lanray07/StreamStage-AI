import SwiftUI

struct VoiceWarmUpView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = VoicePracticeViewModel()

    var profile: CreatorProfile

    var body: some View {
        @Bindable var viewModel = viewModel
        @Bindable var speech = appState.speechRecognitionService

        PremiumBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Voice Warm-Up")
                        .font(.system(size: 30, weight: .black, design: .rounded))

                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Drill")
                                .font(.headline)

                            FlowLayout(spacing: 8) {
                                ForEach(viewModel.drills, id: \.self) { drill in
                                    OptionChip(
                                        title: drill,
                                        systemImage: "waveform",
                                        isSelected: viewModel.selectedDrill == drill
                                    ) {
                                        viewModel.selectedDrill = drill
                                    }
                                }
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("Studio meter", systemImage: "mic.and.signal.meter")
                                .font(.headline)

                            VoiceWaveformView(samples: appState.waveformManager.samples, tint: speech.isRecording ? .stageMint : .stageBlue)
                                .frame(height: 70)

                            StudioAudioMeter(level: appState.audioLevelMeter.normalizedLevel)
                                .frame(height: 14)

                            Text(warmUpPrompt)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Live transcript")
                                .font(.headline)

                            TextEditor(text: $speech.editedTranscript)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 140)
                                .padding(10)
                                .background(Color.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                                )
                        }
                    }

                    analysisCard

                    HStack(spacing: 10) {
                        NeonButton(title: speech.isRecording ? "Pause" : "Start Voice", systemImage: speech.isRecording ? "pause.fill" : "mic.fill") {
                            Task {
                                if speech.isRecording {
                                    speech.pause()
                                    appState.waveformManager.stop()
                                    appState.audioLevelMeter.stop()
                                } else {
                                    await speech.start()
                                    if speech.isRecording {
                                        appState.waveformManager.start()
                                        appState.audioLevelMeter.start()
                                    }
                                }
                            }
                        }

                        NeonButton(title: "Stop", systemImage: "stop.circle", style: .secondary) {
                            speech.stop()
                            appState.waveformManager.stop()
                            appState.audioLevelMeter.stop()
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Voice")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onDisappear {
            speech.stop()
            appState.waveformManager.stop()
            appState.audioLevelMeter.stop()
        }
    }

    private var warmUpPrompt: String {
        switch viewModel.selectedDrill {
        case "Breathing prompt":
            "Inhale, hold, then deliver your opening line slowly."
        case "Vocal clarity":
            "Say the same sentence three ways: calm, bright, urgent."
        case "Product pitch":
            "Name the problem, show the product, state the outcome."
        case "Closing statement":
            "Give one next action and stop talking."
        default:
            "Give me 30 seconds and I will make this live worth your time."
        }
    }

    private var analysisCard: some View {
        let result = appState.voiceAnalysisService.analyze(
            transcript: appState.speechRecognitionService.editedTranscript
        )

        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Voice analysis")
                    .font(.headline)

                HStack(spacing: 10) {
                    MetricMini(title: "Fillers", value: "\(result.fillerWordCount)", tint: .stageAmber)
                    MetricMini(title: "Pace", value: "\(result.estimatedWordsPerMinute)", tint: .stageBlue)
                    MetricMini(title: "Confidence", value: "\(result.confidenceScore)", tint: .stageMint)
                }

                ForEach(result.notes, id: \.self) { note in
                    Label(note, systemImage: "checkmark.seal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct SalesPracticeView: View {
    @Environment(AppState.self) private var appState
    @State private var objectionIndex = 0

    var profile: CreatorProfile

    private var objections: [String] {
        appState.salesPracticeService.buyerObjections(for: .tiktokShop)
    }

    var body: some View {
        PremiumBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Sales Live Practice")
                        .font(.system(size: 30, weight: .black, design: .rounded))

                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Buyer objection", systemImage: "cart.badge.questionmark")
                                .font(.headline)

                            Text(objections[objectionIndex])
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.white)

                            NeonButton(title: "Next Objection", systemImage: "arrow.right.circle") {
                                objectionIndex = (objectionIndex + 1) % objections.count
                            }
                        }
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        SalesStepCard(title: "Product intro", detail: "Name the product and who it helps.", icon: "megaphone.fill", tint: .stagePink)
                        SalesStepCard(title: "Benefit", detail: "Translate the feature into a visible outcome.", icon: "sparkles", tint: .stageMint)
                        SalesStepCard(title: "Objection", detail: "Agree with the concern, then reframe.", icon: "bubble.left.and.exclamationmark.bubble.right.fill", tint: .stageAmber)
                        SalesStepCard(title: "Close", detail: "One offer, one reason, one action.", icon: "checkmark.seal.fill", tint: .stageBlue)
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Urgency prompts")
                                .font(.headline)

                            ForEach(appState.salesPracticeService.urgencyPrompts(), id: \.self) { prompt in
                                Label(prompt, systemImage: "timer")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    NavigationLink {
                        SimulationSetupView(profile: profile)
                    } label: {
                        HStack {
                            Image(systemName: "dot.radiowaves.left.and.right")
                            Text("Run Sales Simulation")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Color.stagePink, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
            }
        }
        .navigationTitle("Sales")
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct QAPressureView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = QAPressureViewModel()
    @State private var isRapidFireRunning = false
    @State private var timer: Timer?

    var profile: CreatorProfile

    private var questions: [String] {
        appState.qaPressureService.questions(for: viewModel.selectedLevel, creatorType: profile.creatorType)
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        PremiumBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Q&A Pressure Mode")
                        .font(.system(size: 30, weight: .black, design: .rounded))

                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Mode")
                                .font(.headline)

                            FlowLayout(spacing: 8) {
                                ForEach(QAPressureLevel.allCases) { level in
                                    OptionChip(
                                        title: level.rawValue,
                                        systemImage: "bolt.bubble",
                                        isSelected: viewModel.selectedLevel == level
                                    ) {
                                        viewModel.selectedLevel = level
                                        viewModel.activeQuestionIndex = 0
                                    }
                                }
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Label("Question \(viewModel.activeQuestionIndex + 1)", systemImage: "questionmark.circle.fill")
                                    .font(.headline)
                                Spacer()
                                Text(isRapidFireRunning ? "Rapid" : "Ready")
                                    .font(.caption.bold())
                                    .foregroundStyle(isRapidFireRunning ? Color.stagePink : Color.stageMint)
                            }

                            Text(questions[safe: viewModel.activeQuestionIndex] ?? "Who is this for?")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .minimumScaleFactor(0.7)

                            HStack(spacing: 10) {
                                NeonButton(title: "Next", systemImage: "arrow.right.circle") {
                                    viewModel.nextQuestion(total: questions.count)
                                }

                                NeonButton(title: isRapidFireRunning ? "Stop" : "Rapid Fire", systemImage: isRapidFireRunning ? "stop.circle" : "timer", style: .secondary) {
                                    toggleRapidFire()
                                }
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Answer frame")
                                .font(.headline)
                            Label("Answer the question first.", systemImage: "1.circle")
                            Label("Add one proof point.", systemImage: "2.circle")
                            Label("Bridge back to your topic.", systemImage: "3.circle")
                        }
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Q&A")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func toggleRapidFire() {
        if isRapidFireRunning {
            timer?.invalidate()
            timer = nil
            isRapidFireRunning = false
        } else {
            isRapidFireRunning = true
            timer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { _ in
                Task { @MainActor in
                    viewModel.nextQuestion(total: questions.count)
                }
            }
        }
    }
}

struct MetricMini: View {
    var title: String
    var value: String
    var tint: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(tint)
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct SalesStepCard: View {
    var title: String
    var detail: String
    var icon: String
    var tint: Color

    var body: some View {
        GlassCard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
        }
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
