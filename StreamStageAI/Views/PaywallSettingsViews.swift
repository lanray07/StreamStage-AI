import AVFoundation
import Speech
import SwiftData
import SwiftUI

struct PaywallView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var subscription = appState.subscriptionService

        PremiumBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Unlock the creator studio")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .minimumScaleFactor(0.72)
                        Text("Practice going live before you go live.")
                            .font(.headline)
                            .foregroundStyle(Color.stageMint)
                    }
                    .padding(.top, 18)

                    PlanCard(
                        title: "Free",
                        price: "3 simulations/month",
                        features: [
                            "Basic audience mode",
                            "Limited feedback",
                            "Private simulation labels"
                        ],
                        tint: .stageBlue
                    ) {
                        activatePlaceholder(plan: .free)
                    }

                    PlanCard(
                        title: "Creator Pro",
                        price: "GBP 9.99 monthly or GBP 79.99 yearly",
                        features: [
                            "Unlimited simulations",
                            "Voice input",
                            "Advanced audience modes",
                            "AI performance coach",
                            "Replay review",
                            "Script builder"
                        ],
                        tint: .stagePink
                    ) {
                        Task {
                            if let product = subscription.products.first(where: { $0.id.contains("creatorpro.monthly") }) {
                                await subscription.purchase(product)
                            } else {
                                activatePlaceholder(plan: .creatorPro)
                            }
                        }
                    }

                    PlanCard(
                        title: "Stream Elite",
                        price: "GBP 19.99 monthly",
                        features: [
                            "Sales live practice",
                            "Intense Q&A mode",
                            "Advanced analytics",
                            "Premium creator templates",
                            "Product launch rehearsals",
                            "Exclusive visual themes"
                        ],
                        tint: .stageMint
                    ) {
                        Task {
                            if let product = subscription.products.first(where: { $0.id.contains("streamelite.monthly") }) {
                                await subscription.purchase(product)
                            } else {
                                activatePlaceholder(plan: .streamElite)
                            }
                        }
                    }

                    Text("All viewer counts, chat, reactions, and audience behavior in StreamStage AI are private simulations for rehearsal only.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
            }
        }
        .task {
            await appState.subscriptionService.loadProducts()
        }
    }

    private func activatePlaceholder(plan: SubscriptionPlan) {
        appState.subscriptionService.currentPlan = plan
        appState.subscriptionService.isActive = plan != .free
        appState.subscriptionService.statusMessage = plan == .free ? "Free plan" : "\(plan.rawValue) active"
        dismiss()
    }
}

struct PlanCard: View {
    var title: String
    var price: String
    var features: [String]
    var tint: Color
    var action: () -> Void

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.title2.bold())
                        Text(price)
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(tint)
                    }
                    Spacer()
                    Image(systemName: "crown.fill")
                        .foregroundStyle(tint)
                }

                ForEach(features, id: \.self) { feature in
                    Label(feature, systemImage: "checkmark.circle.fill")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                NeonButton(title: "Choose \(title)", systemImage: "arrow.right.circle", style: .secondary, action: action)
            }
        }
    }
}

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [CreatorProfile]
    @Query private var sessions: [SimulationSession]
    @Query private var messages: [ChatMessage]
    @Query private var transcripts: [VoiceTranscript]
    @Query private var reviews: [PerformanceReview]
    @Query private var scripts: [ScriptDraft]
    @Query private var subscriptions: [SubscriptionState]

    var profile: CreatorProfile

    var body: some View {
        NavigationStack {
            PremiumBackground {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Settings")
                            .font(.system(size: 30, weight: .black, design: .rounded))

                        settingsSection("Subscription") {
                            SettingRow(
                                title: appState.subscriptionService.statusMessage,
                                subtitle: "Manage StreamStage AI access",
                                systemImage: "crown.fill"
                            ) {
                                appState.showPaywall = true
                            }
                        }

                        settingsSection("Voice and camera") {
                            SettingRow(
                                title: "Voice settings",
                                subtitle: appState.speechRecognitionService.authorizationStatus.description,
                                systemImage: "waveform"
                            ) {
                                Task {
                                    await appState.speechRecognitionService.requestAuthorization()
                                }
                            }

                            SettingRow(
                                title: "Microphone permission",
                                subtitle: appState.voiceRecordingService.hasMicrophonePermission ? "Granted" : "Request access",
                                systemImage: "mic.fill"
                            ) {
                                Task {
                                    await appState.voiceRecordingService.requestMicrophonePermission()
                                }
                            }

                            SettingRow(
                                title: "Camera permission",
                                subtitle: "Preview placeholder ready",
                                systemImage: "camera.fill"
                            ) {
                                AVCaptureDevice.requestAccess(for: .video) { _ in }
                            }
                        }

                        settingsSection("Audience simulation") {
                            SettingStaticRow(title: "Default creator type", value: profile.creatorType, systemImage: "person.crop.circle")
                            SettingStaticRow(title: "Recommended audience", value: profile.recommendedAudienceMode, systemImage: "bubble.left.and.bubble.right.fill")
                            SettingStaticRow(title: "Simulation disclaimer", value: "Private rehearsal only", systemImage: "lock.fill")
                        }

                        settingsSection("Companion surfaces") {
                            ForEach(WidgetPlaceholderRegistry.snapshots) { snapshot in
                                SettingStaticRow(title: snapshot.title, value: snapshot.value, systemImage: "widget.small")
                            }

                            ForEach(WatchPlaceholderRegistry.prompts) { prompt in
                                SettingStaticRow(title: prompt.title, value: "\(prompt.durationSeconds)s", systemImage: "applewatch")
                            }
                        }

                        settingsSection("Legal") {
                            Link(destination: URL(string: "https://YOUR_DOMAIN.com/privacy")!) {
                                SettingStaticRow(title: "Privacy policy", value: "Placeholder URL", systemImage: "hand.raised.fill")
                            }
                            .buttonStyle(.plain)

                            Link(destination: URL(string: "https://YOUR_DOMAIN.com/terms")!) {
                                SettingStaticRow(title: "Terms of use", value: "Placeholder URL", systemImage: "doc.text.fill")
                            }
                            .buttonStyle(.plain)
                        }

                        settingsSection("Local data") {
                            SettingRow(
                                title: "Delete all data",
                                subtitle: "Removes profiles, sessions, chat, transcripts, reviews, and scripts",
                                systemImage: "trash.fill",
                                isDestructive: true
                            ) {
                                deleteAllData()
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Settings")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            GlassCard {
                VStack(spacing: 12) {
                    content()
                }
            }
        }
    }

    private func deleteAllData() {
        profiles.forEach { modelContext.delete($0) }
        sessions.forEach { modelContext.delete($0) }
        messages.forEach { modelContext.delete($0) }
        transcripts.forEach { modelContext.delete($0) }
        reviews.forEach { modelContext.delete($0) }
        scripts.forEach { modelContext.delete($0) }
        subscriptions.forEach { modelContext.delete($0) }
        try? modelContext.save()
    }
}

struct SettingRow: View {
    var title: String
    var subtitle: String
    var systemImage: String
    var isDestructive = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(isDestructive ? Color.red : Color.stageMint)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isDestructive ? Color.red : Color.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct SettingStaticRow: View {
    var title: String
    var value: String
    var systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(Color.stageBlue)
                .frame(width: 28)

            Text(title)
                .font(.subheadline.weight(.semibold))

            Spacer()

            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
    }
}

private extension SFSpeechRecognizerAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined: "Not requested"
        case .denied: "Denied"
        case .restricted: "Restricted"
        case .authorized: "Authorized"
        @unknown default: "Unknown"
        }
    }
}
