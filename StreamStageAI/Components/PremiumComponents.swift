import Charts
import SwiftUI
import UIKit

extension Color {
    static let stagePurple = Color(red: 0.54, green: 0.18, blue: 1.0)
    static let stageBlue = Color(red: 0.10, green: 0.55, blue: 1.0)
    static let stagePink = Color(red: 1.0, green: 0.12, blue: 0.48)
    static let stageMint = Color(red: 0.20, green: 0.92, blue: 0.76)
    static let stageAmber = Color(red: 1.0, green: 0.72, blue: 0.25)
    static let stagePanel = Color.white.opacity(0.075)
}

struct PremiumBackground<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.stagePurple.opacity(0.34),
                    Color.clear,
                    Color.stageBlue.opacity(0.18),
                    Color.stagePink.opacity(0.16)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            content
        }
    }
}

struct GlassCard<Content: View>: View {
    var padding: CGFloat = 16
    let content: Content

    init(padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
    }
}

struct NeonButton: View {
    enum Style {
        case primary
        case secondary
        case danger
    }

    var title: String
    var systemImage: String
    var style: Style = .primary
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .font(.callout)
            .frame(maxWidth: .infinity, minHeight: 48)
            .foregroundStyle(foreground)
            .background(background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private var background: AnyShapeStyle {
        switch style {
        case .primary:
            AnyShapeStyle(
                LinearGradient(
                    colors: [.stagePink, .stagePurple, .stageBlue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        case .secondary:
            AnyShapeStyle(Color.white.opacity(0.10))
        case .danger:
            AnyShapeStyle(Color.red.opacity(0.22))
        }
    }

    private var foreground: Color {
        switch style {
        case .primary: .white
        case .secondary: .white
        case .danger: .red.opacity(0.95)
        }
    }

    private var border: Color {
        switch style {
        case .primary: .white.opacity(0.20)
        case .secondary: .white.opacity(0.16)
        case .danger: .red.opacity(0.35)
        }
    }
}

struct OptionChip: View {
    var title: String
    var systemImage: String?
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                if let systemImage {
                    Image(systemName: systemImage)
                }

                Text(title)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .font(.footnote)
            .foregroundStyle(isSelected ? Color.black : Color.white)
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(isSelected ? Color.stageMint : Color.white.opacity(0.10), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.stageMint.opacity(0.7) : Color.white.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

struct MetricTile: View {
    var title: String
    var value: String
    var subtitle: String
    var systemImage: String
    var tint: Color

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: systemImage)
                        .font(.headline)
                        .foregroundStyle(tint)

                    Spacer()
                }

                Text(value)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct PerformanceScoreCard: View {
    var title: String
    var score: Int
    var tint: Color
    var detail: String

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(title)
                        .font(.headline)
                    Spacer()
                    Text("\(score)")
                        .font(.title2.bold())
                        .foregroundStyle(tint)
                }

                ProgressView(value: Double(score), total: 100)
                    .tint(tint)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }
}

struct ScriptCard: View {
    var draft: ScriptDraft

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(draft.title)
                        .font(.headline)
                    Spacer()
                    Text(draft.category)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.stageMint)
                }

                Text(draft.content)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(5)
            }
        }
    }
}

struct AnalyticsChartCard: View {
    struct Point: Identifiable {
        let id = UUID()
        var index: Int
        var metric: String
        var value: Int
    }

    var reviews: [PerformanceReview]

    private var points: [Point] {
        reviews.enumerated().flatMap { index, review in
            [
                Point(index: index + 1, metric: "Confidence", value: review.confidenceScore),
                Point(index: index + 1, metric: "Speaking", value: review.speakingScore),
                Point(index: index + 1, metric: "Engagement", value: review.engagementScore)
            ]
        }
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Performance trend")
                    .font(.headline)

                if points.isEmpty {
                    EmptyStateView(
                        systemImage: "chart.xyaxis.line",
                        title: "No trend yet",
                        message: "Complete a rehearsal to fill this chart."
                    )
                    .frame(height: 180)
                } else {
                    Chart(points) { point in
                        LineMark(
                            x: .value("Session", point.index),
                            y: .value(point.metric, point.value)
                        )
                        .foregroundStyle(by: .value("Metric", point.metric))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Session", point.index),
                            y: .value(point.metric, point.value)
                        )
                        .foregroundStyle(by: .value("Metric", point.metric))
                    }
                    .chartYScale(domain: 0...100)
                    .frame(height: 220)
                }
            }
        }
    }
}

struct ShareCardPreview: View {
    var title: String
    var value: String
    var subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("StreamStage AI")
                    .font(.headline)
                Spacer()
                Image(systemName: "dot.radiowaves.left.and.right")
                    .foregroundStyle(Color.stagePink)
            }

            Spacer()

            Text(value)
                .font(.system(size: 44, weight: .black, design: .rounded))
                .minimumScaleFactor(0.6)
            Text(title)
                .font(.title3.bold())
            Text(subtitle)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(height: 260)
        .background(
            LinearGradient(
                colors: [
                    Color.stagePurple.opacity(0.88),
                    Color.black,
                    Color.stageBlue.opacity(0.76)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(0.20), lineWidth: 1)
        )
    }
}

struct UpgradeBanner: View {
    var title: String = "Creator Pro unlocks the full studio."
    var message: String = "Voice input, advanced audience modes, replay review, and AI coaching."
    var action: () -> Void

    var body: some View {
        GlassCard {
            HStack(spacing: 12) {
                Image(systemName: "crown")
                    .font(.title3)
                    .foregroundStyle(Color.stageAmber)
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Button(action: action) {
                    Image(systemName: "arrow.up.right")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(Color.white.opacity(0.10), in: Circle())
                }
                .accessibilityLabel("Open paywall")
            }
        }
    }
}

struct LoadingStateView: View {
    var title: String

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(Color.stageMint)
            Text(title)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 180)
    }
}

struct EmptyStateView: View {
    var systemImage: String
    var title: String
    var message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.largeTitle)
                .foregroundStyle(Color.stageBlue)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ActivityView: UIViewControllerRepresentable {
    var activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
