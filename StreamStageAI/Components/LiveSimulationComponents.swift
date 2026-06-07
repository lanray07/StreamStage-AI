import SwiftUI

struct LiveSimulationView: View {
    @Bindable var engine: LiveSimulationEngine
    @Bindable var speechService: SpeechRecognitionService
    @Bindable var waveformManager: WaveformAnimationManager
    @Bindable var audioLevelMeter: AudioLevelMeter

    var onEnd: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                liveBadge
                simulatedViewerCount
                Spacer()
                timerLabel
            }

            CameraPreviewPlaceholder()
                .overlay(alignment: .topLeading) {
                    Text("Private simulation only")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.62), in: Capsule())
                        .padding(12)
                }
                .overlay(alignment: .bottomLeading) {
                    Text(engine.currentPrompt)
                        .font(.subheadline.weight(.semibold))
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.ultraThinMaterial)
                }

            HStack(spacing: 10) {
                AudienceMoodMeter(title: "Mood", value: engine.audienceMood, tint: .stageMint)
                AudienceMoodMeter(title: "Confidence", value: engine.confidenceLevel, tint: .stagePink)
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("AI live chat", systemImage: "message.badge.waveform")
                            .font(.headline)
                        Spacer()
                        if engine.isGeneratingChat {
                            ProgressView()
                                .scaleEffect(0.75)
                                .tint(Color.stageMint)
                        }
                    }

                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(engine.chatMessages) { message in
                                    SimulatedChatBubble(message: message)
                                        .id(message.id)
                                }
                            }
                        }
                        .frame(height: 220)
                        .onChange(of: engine.chatMessages.count) {
                            if let last = engine.chatMessages.last {
                                withAnimation(.smooth(duration: 0.25)) {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
            }

            voicePanel

            NeonButton(title: "End Session", systemImage: "stop.fill", style: .danger, action: onEnd)
        }
        .onChange(of: speechService.transcript) { _, newValue in
            engine.ingestTranscript(newValue)
        }
    }

    private var liveBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.stagePink)
                .frame(width: 8, height: 8)
            Text("SIM LIVE")
                .font(.caption.bold())
        }
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background(Color.stagePink.opacity(0.18), in: Capsule())
        .overlay(Capsule().stroke(Color.stagePink.opacity(0.45), lineWidth: 1))
    }

    private var simulatedViewerCount: some View {
        Label("\(engine.viewerCount.formatted()) simulated", systemImage: "eye")
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .frame(height: 30)
            .background(Color.white.opacity(0.08), in: Capsule())
    }

    private var timerLabel: some View {
        Text(durationString)
            .font(.caption.monospacedDigit().weight(.semibold))
            .padding(.horizontal, 10)
            .frame(height: 30)
            .background(Color.white.opacity(0.08), in: Capsule())
    }

    private var durationString: String {
        let minutes = engine.elapsedSeconds / 60
        let seconds = engine.elapsedSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var voicePanel: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Voice studio", systemImage: "waveform")
                        .font(.headline)
                    Spacer()
                    StudioAudioMeter(level: audioLevelMeter.normalizedLevel)
                        .frame(width: 74, height: 18)
                }

                VoiceWaveformView(samples: waveformManager.samples, tint: speechService.isRecording ? .stageMint : .stageBlue)
                    .frame(height: 54)

                LiveCaptionPanel(text: speechService.editedTranscript.isEmpty ? speechService.transcript : speechService.editedTranscript)

                HStack(spacing: 10) {
                    Button {
                        Task {
                            if speechService.isRecording {
                                speechService.pause()
                                waveformManager.stop()
                                audioLevelMeter.stop()
                            } else {
                                await speechService.start()
                                if speechService.isRecording {
                                    waveformManager.start()
                                    audioLevelMeter.start()
                                }
                            }
                        }
                    } label: {
                        Label(speechService.isRecording ? "Pause" : "Speak", systemImage: speechService.isRecording ? "pause.fill" : "mic.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(speechService.isRecording ? .stagePink : .stagePurple)

                    Button {
                        speechService.stop()
                        waveformManager.stop()
                        audioLevelMeter.stop()
                    } label: {
                        Image(systemName: "stop.circle")
                            .frame(width: 42)
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                    .accessibilityLabel("Stop voice input")
                }
            }
        }
    }
}

struct SimulatedChatBubble: View {
    var message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 40)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(message.tone)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(message.isUser ? Color.stageMint : Color.stageBlue)

                Text(message.content)
                    .font(.callout)
                    .foregroundStyle(.white)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(message.isUser ? Color.stageMint.opacity(0.16) : Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(message.isUser ? Color.stageMint.opacity(0.28) : Color.white.opacity(0.10), lineWidth: 1)
            )

            if !message.isUser {
                Spacer(minLength: 28)
            }
        }
    }
}

struct AudienceMoodMeter: View {
    var title: String
    var value: Double
    var tint: Color

    var body: some View {
        GlassCard(padding: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(.caption.weight(.semibold))
                    Spacer()
                    Text("\(Int(value * 100))")
                        .font(.caption.monospacedDigit().weight(.bold))
                        .foregroundStyle(tint)
                }

                ProgressView(value: value)
                    .tint(tint)
            }
        }
    }
}

struct VoiceWaveformView: View {
    var samples: [Double]
    var tint: Color

    var body: some View {
        GeometryReader { proxy in
            HStack(alignment: .center, spacing: 3) {
                ForEach(samples.indices, id: \.self) { index in
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [tint.opacity(0.35), tint, Color.stagePink.opacity(0.8)],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(
                            width: max(2, (proxy.size.width / CGFloat(max(samples.count, 1))) - 3),
                            height: max(5, proxy.size.height * samples[index])
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct StudioAudioMeter: View {
    var level: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.10))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.stageMint, .stageAmber, .stagePink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: proxy.size.width * level)
            }
        }
    }
}

struct LiveCaptionPanel: View {
    var text: String

    var body: some View {
        Text(text.isEmpty ? "Live captions appear here while you rehearse." : text)
            .font(.callout)
            .foregroundStyle(text.isEmpty ? .secondary : .white)
            .lineLimit(3)
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .topLeading)
            .padding(12)
            .background(Color.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
    }
}
