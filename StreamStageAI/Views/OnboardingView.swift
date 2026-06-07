import SwiftData
import SwiftUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel

        PremiumBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("StreamStage AI")
                            .font(.system(size: 42, weight: .black, design: .rounded))
                            .minimumScaleFactor(0.72)

                        Text("Practice going live before you go live.")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Color.stageMint)

                        Text("Step on stage before the world sees you.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 28)

                    GlassCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Creator type")
                                .font(.headline)

                            FlowLayout(spacing: 8) {
                                ForEach(CreatorType.allCases) { type in
                                    OptionChip(
                                        title: type.rawValue,
                                        systemImage: "person.crop.circle",
                                        isSelected: viewModel.creatorType == type
                                    ) {
                                        viewModel.creatorType = type
                                    }
                                }
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Main goal")
                                .font(.headline)

                            FlowLayout(spacing: 8) {
                                ForEach(CreatorGoal.allCases) { goal in
                                    OptionChip(
                                        title: goal.rawValue,
                                        systemImage: "target",
                                        isSelected: viewModel.mainGoal == goal
                                    ) {
                                        viewModel.mainGoal = goal
                                    }
                                }
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("Starting confidence")
                                    .font(.headline)
                                Spacer()
                                Text("\(Int(viewModel.confidenceLevel))")
                                    .font(.title3.monospacedDigit().bold())
                                    .foregroundStyle(Color.stagePink)
                            }

                            Slider(value: $viewModel.confidenceLevel, in: 10...100, step: 1)
                                .tint(Color.stagePink)
                        }
                    }

                    NeonButton(title: "Create Practice Profile", systemImage: "sparkles") {
                        let profile = viewModel.makeProfile()
                        modelContext.insert(profile)
                        modelContext.insert(SubscriptionState())
                    }
                }
                .padding(20)
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 320
        var rows: [CGFloat] = [0]
        var currentWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentWidth + size.width > width, currentWidth > 0 {
                rows.append(size.height)
                currentWidth = size.width + spacing
            } else {
                rows[rows.count - 1] = max(rows[rows.count - 1], size.height)
                currentWidth += size.width + spacing
            }
        }

        return CGSize(width: width, height: rows.reduce(0, +) + CGFloat(max(0, rows.count - 1)) * spacing)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }

            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: size.width, height: size.height))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
