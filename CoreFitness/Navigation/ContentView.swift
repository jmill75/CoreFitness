import SwiftUI

struct ContentView: View {

    // MARK: - Environment
    @EnvironmentObject var authManager: AuthManager

    // MARK: - State
    @State private var selectedTab: Tab = .home

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView(selectedTab: $selectedTab)
            } else {
                OnboardingView()
            }
        }
        .animation(.easeInOut, value: authManager.isAuthenticated)
    }
}

// MARK: - Tab Enum
enum Tab: String, CaseIterable {
    case home = "Home"
    case programs = "Programs"
    case progress = "Progress"
    case health = "Health"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .programs: return "figure.run"
        case .progress: return "trophy.fill"
        case .health: return "heart.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {

    @Binding var selectedTab: Tab

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Label(Tab.home.rawValue, systemImage: Tab.home.icon)
                }
                .tag(Tab.home)

            ProgramsView(selectedTab: $selectedTab)
                .tabItem {
                    Label(Tab.programs.rawValue, systemImage: Tab.programs.icon)
                }
                .tag(Tab.programs)

            ProgressTabView(selectedTab: $selectedTab)
                .tabItem {
                    Label(Tab.progress.rawValue, systemImage: Tab.progress.icon)
                }
                .tag(Tab.progress)

            HealthView(selectedTab: $selectedTab)
                .tabItem {
                    Label(Tab.health.rawValue, systemImage: Tab.health.icon)
                }
                .tag(Tab.health)

            SettingsView(selectedTab: $selectedTab)
                .tabItem {
                    Label(Tab.settings.rawValue, systemImage: Tab.settings.icon)
                }
                .tag(Tab.settings)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
        .environmentObject(ThemeManager())
        .environmentObject(HealthKitManager())
}
