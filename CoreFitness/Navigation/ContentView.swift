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
    @EnvironmentObject var navigationState: NavigationState
    @EnvironmentObject var activeProgramManager: ActiveProgramManager

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            Group {
                switch selectedTab {
                case .home:
                    HomeView(selectedTab: $selectedTab)
                case .programs:
                    ProgramsView(selectedTab: $selectedTab)
                case .progress:
                    ProgressTabView(selectedTab: $selectedTab)
                case .health:
                    HealthView(selectedTab: $selectedTab)
                case .settings:
                    SettingsView(selectedTab: $selectedTab)
                }
            }

            // Custom Tab Bar
            CustomTabBar(
                selectedTab: $selectedTab,
                hasProgramActivity: activeProgramManager.hasCurrentWorkout || activeProgramManager.hasActiveProgram
            )
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $navigationState.showInvitationResponse) {
            if let inviteCode = navigationState.pendingInvitationCode {
                InvitationResponseView(inviteCode: inviteCode)
                    .onDisappear {
                        navigationState.pendingInvitationCode = nil
                    }
            }
        }
    }
}

// MARK: - Custom Tab Bar (Liquid Glass Style)
struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    let hasProgramActivity: Bool

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                TabBarButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    isInactive: tab == .programs && !hasProgramActivity
                ) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(
            ZStack {
                // Liquid glass effect
                Rectangle()
                    .fill(.ultraThinMaterial)

                // Subtle gradient overlay for depth
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.08),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Top border highlight
                VStack {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 0.5)
                    Spacer()
                }
            }
        )
    }
}

// MARK: - Tab Bar Button
struct TabBarButton: View {
    let tab: Tab
    let isSelected: Bool
    let isInactive: Bool
    let action: () -> Void

    private var iconColor: Color {
        if isSelected {
            return .white
        } else if isInactive {
            return Color.white.opacity(0.2)
        } else {
            return Color.white.opacity(0.5)
        }
    }

    private var labelColor: Color {
        if isSelected {
            return .white
        } else if isInactive {
            return Color.white.opacity(0.2)
        } else {
            return Color.white.opacity(0.5)
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(iconColor)
                    .symbolEffect(.bounce, value: isSelected)

                Text(tab.rawValue)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(labelColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
        .environmentObject(ThemeManager())
        .environmentObject(HealthKitManager())
        .environmentObject(NavigationState())
        .environmentObject(ActiveProgramManager.shared)
}
