import SwiftData
import SwiftUI

struct RootView: View {
    @Query(sort: \CreatorProfile.createdAt, order: .reverse) private var profiles: [CreatorProfile]

    var body: some View {
        if let profile = profiles.first {
            MainTabView(profile: profile)
        } else {
            OnboardingView()
        }
    }
}

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    var profile: CreatorProfile

    var body: some View {
        @Bindable var appState = appState

        TabView(selection: $appState.selectedTab) {
            DashboardView(profile: profile)
                .tabItem {
                    Label(AppTab.dashboard.rawValue, systemImage: AppTab.dashboard.systemImage)
                }
                .tag(AppTab.dashboard)

            AnalyticsDashboardView(profile: profile)
                .tabItem {
                    Label(AppTab.analytics.rawValue, systemImage: AppTab.analytics.systemImage)
                }
                .tag(AppTab.analytics)

            ScriptBuilderView(profile: profile)
                .tabItem {
                    Label(AppTab.scripts.rawValue, systemImage: AppTab.scripts.systemImage)
                }
                .tag(AppTab.scripts)

            ReplayReviewView()
                .tabItem {
                    Label(AppTab.replays.rawValue, systemImage: AppTab.replays.systemImage)
                }
                .tag(AppTab.replays)

            SettingsView(profile: profile)
                .tabItem {
                    Label(AppTab.settings.rawValue, systemImage: AppTab.settings.systemImage)
                }
                .tag(AppTab.settings)
        }
        .tint(Color.stageMint)
        .sheet(isPresented: $appState.showPaywall) {
            PaywallView()
                .presentationDetents([.large])
        }
    }
}
