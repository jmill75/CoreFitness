import SwiftUI
import SwiftData
import Contacts
import ContactsUI

struct ChallengesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager
    @Query(sort: \Challenge.startDate, order: .reverse) private var challenges: [Challenge]

    @State private var showCreateChallenge = false
    @State private var showJoinChallenge = false
    @State private var selectedChallenge: Challenge?
    @State private var searchText = ""
    @State private var selectedCategory = "All"

    // Colors matching HTML design
    private let bgPrimary = Color(hex: "0a0a0a")
    private let bgCard = Color(hex: "161616")
    private let coral = Color(hex: "ff6b6b")
    private let cyan = Color(hex: "54a0ff")
    private let gold = Color(hex: "feca57")
    private let teal = Color(hex: "00d2d3")
    private let lime = Color(hex: "1dd1a1")
    private let purple = Color(hex: "a55eea")

    private let categories = ["All", "Running", "Cycling", "Strength", "Swimming", "Yoga", "HIIT"]

    private var activeChallenge: Challenge? {
        challenges.first { $0.isActive && !$0.isCompleted }
    }

    private var completedChallenges: [Challenge] {
        challenges.filter { $0.isCompleted }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    challengeHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    // Search Bar
                    searchBar
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                    // Category Pills
                    categoryPills
                        .padding(.top, 20)

                    // Active Challenge Section
                    if let challenge = activeChallenge {
                        sectionHeader("Active Challenge", icon: "flame.fill", color: coral)
                            .padding(.top, 24)

                        RefinedActiveChallengeCard(challenge: challenge) {
                            selectedChallenge = challenge
                        }
                        .padding(.horizontal, 20)
                    }

                    // Popular Challenges Section
                    sectionHeader("Popular Now", icon: "flame.fill", color: coral)
                        .padding(.top, 24)

                    VStack(spacing: 16) {
                        PopularChallengeCard(
                            type: "Running",
                            typeColor: coral,
                            duration: "30-Day Challenge",
                            title: "5K Every Day",
                            description: "Run 5 kilometers daily for 30 days. Build endurance and mental toughness.",
                            participantCount: 847
                        ) {
                            showCreateChallenge = true
                        }

                        PopularChallengeCard(
                            type: "Cycling",
                            typeColor: cyan,
                            duration: "14-Day Challenge",
                            title: "200 Mile Sprint",
                            description: "Cycle 200 miles in 2 weeks. Perfect for intermediate riders.",
                            participantCount: 312
                        ) {
                            showCreateChallenge = true
                        }

                        PopularChallengeCard(
                            type: "Strength",
                            typeColor: gold,
                            duration: "21-Day Challenge",
                            title: "100 Push-ups",
                            description: "Work up to 100 push-ups in a single set. Progressive training plan included.",
                            participantCount: 1200
                        ) {
                            showCreateChallenge = true
                        }
                    }
                    .padding(.horizontal, 20)

                    // Friends Activity Section
                    HStack {
                        sectionHeader("Friends Activity", icon: "person.2.fill", color: cyan)
                        Spacer()
                        Text("See All")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(cyan)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                    FriendsActivityCard()
                        .padding(.horizontal, 20)

                    // Completed Challenges
                    if !completedChallenges.isEmpty {
                        sectionHeader("History", icon: "clock.fill", color: gold)
                            .padding(.top, 24)

                        VStack(spacing: 12) {
                            ForEach(completedChallenges.prefix(5)) { challenge in
                                RefinedCompletedChallengeRow(challenge: challenge)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 100)
            }
            .background(bgPrimary.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateChallenge = true
                    } label: {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [coral, coral.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                            )
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showCreateChallenge) {
            CreateChallengeView()
        }
        .fullScreenCover(isPresented: $showJoinChallenge) {
            JoinChallengeView()
        }
        .fullScreenCover(item: $selectedChallenge) { challenge in
            ChallengeDetailView(challenge: challenge)
        }
    }

    // MARK: - Header
    private var challengeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Challenges")
                .font(.system(size: 34, weight: .heavy))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, gold],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("Push your limits with friends")
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.3))

            TextField("Search challenges...", text: $searchText)
                .font(.system(size: 15))
                .foregroundStyle(.white)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
        }
        .padding(14)
        .background(Color(hex: "222222"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Category Pills
    private var categoryPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categories, id: \.self) { category in
                    CategoryPill(
                        title: category,
                        isSelected: selectedCategory == category,
                        color: coral
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Section Header
    private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                )

            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white.opacity(0.7))
                .tracking(1.5)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
}

// MARK: - Category Pill
private struct CategoryPill: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            Color(hex: "161616")
                        }
                    }
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color.white.opacity(0.06), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Popular Challenge Card
private struct PopularChallengeCard: View {
    let type: String
    let typeColor: Color
    let duration: String
    let title: String
    let description: String
    let participantCount: Int
    let onJoin: () -> Void

    @State private var isPressed = false

    private let bgCard = Color(hex: "161616")

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Accent bar
            typeColor
                .frame(height: 3)

            VStack(alignment: .leading, spacing: 14) {
                // Meta row
                HStack(spacing: 8) {
                    Text(type.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(typeColor)
                        .tracking(0.5)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(typeColor.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    Text(duration)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.3))
                }

                // Title
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)

                // Description
                Text(description)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineSpacing(2)

                // Bottom row
                HStack {
                    // Participants preview
                    HStack(spacing: -8) {
                        ForEach(0..<4, id: \.self) { i in
                            Circle()
                                .fill(participantColors[i % participantColors.count])
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .stroke(bgCard, lineWidth: 2)
                                )
                        }
                    }

                    Text("+\(participantCount) joined")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.leading, 8)

                    Spacer()

                    // Join button
                    Button(action: onJoin) {
                        Text("Join")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "ff6b6b"), Color(hex: "e55555")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(16)
        }
        .background(bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }

    private var participantColors: [LinearGradient] {
        [
            LinearGradient(colors: [Color(hex: "ff6b6b"), Color(hex: "ee5a5a")], startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(colors: [Color(hex: "54a0ff"), Color(hex: "4494f0")], startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(colors: [Color(hex: "feca57"), Color(hex: "f5b041")], startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(colors: [Color(hex: "1dd1a1"), Color(hex: "17b38a")], startPoint: .topLeading, endPoint: .bottomTrailing)
        ]
    }
}

// MARK: - Friends Activity Card
private struct FriendsActivityCard: View {
    private let bgCard = Color(hex: "161616")
    private let cyan = Color(hex: "54a0ff")
    private let lime = Color(hex: "1dd1a1")
    private let gold = Color(hex: "feca57")

    var body: some View {
        VStack(spacing: 0) {
            // Accent bar
            cyan
                .frame(height: 3)

            VStack(spacing: 0) {
                FriendActivityRow(
                    name: "Sarah M.",
                    challenge: "5K Every Day • Day 12",
                    status: "Active",
                    statusColor: lime,
                    avatarColor: Color(hex: "feca57")
                )

                Divider()
                    .background(Color.white.opacity(0.06))

                FriendActivityRow(
                    name: "Mike T.",
                    challenge: "200 Mile Sprint • Day 8",
                    status: "Active",
                    statusColor: lime,
                    avatarColor: Color(hex: "a55eea")
                )

                Divider()
                    .background(Color.white.opacity(0.06))

                FriendActivityRow(
                    name: "Emma K.",
                    challenge: "Yoga Flow • Completed!",
                    status: "Winner",
                    statusColor: gold,
                    avatarColor: Color(hex: "ff6b6b"),
                    showTrophy: true
                )
            }
            .padding(16)
        }
        .background(bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - Friend Activity Row
private struct FriendActivityRow: View {
    let name: String
    let challenge: String
    let status: String
    let statusColor: Color
    let avatarColor: Color
    var showTrophy: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [avatarColor, avatarColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)

                Text(challenge)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            // Status badge
            HStack(spacing: 4) {
                if showTrophy {
                    Text("🏆")
                        .font(.system(size: 12))
                }
                Text(status)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(statusColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(statusColor.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Refined Active Challenge Card
private struct RefinedActiveChallengeCard: View {
    let challenge: Challenge
    let onTap: () -> Void

    @State private var isPressed = false

    private let bgCard = Color(hex: "161616")
    private let coral = Color(hex: "ff6b6b")
    private let coralDark = Color(hex: "e55555")

    private var progress: Double {
        Double(challenge.currentDay - 1) / Double(challenge.durationDays)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Accent bar
                LinearGradient(
                    colors: [coral, coralDark],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 3)

                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    HStack(spacing: 16) {
                        // Icon
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [coral, coralDark],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .overlay(
                                Image(systemName: challenge.goalType.icon)
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundStyle(.white)
                            )
                            .shadow(color: coral.opacity(0.3), radius: 8, y: 4)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(challenge.name.uppercased())
                                .font(.system(size: 20, weight: .bold))
                                .tracking(1)
                                .foregroundStyle(.white)
                                .lineLimit(1)

                            Text("\(challenge.durationDays)-Day Challenge • \(challenge.sortedParticipants.count) participants")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.7))
                        }

                        Spacer()
                    }

                    // Progress section
                    VStack(spacing: 12) {
                        HStack {
                            Text("Your Progress")
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.7))

                            Spacer()

                            Text("\(challenge.currentDay) of \(challenge.durationDays) days")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(coral)
                        }

                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(hex: "222222"))
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [coral, Color(hex: "feca57")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * progress, height: 8)
                            }
                        }
                        .frame(height: 8)

                        // Stats row
                        HStack(spacing: 12) {
                            ProgressStatItem(value: "\(challenge.currentDay)", label: "Days Done", color: coral)
                            ProgressStatItem(value: "\(challenge.participants?.first(where: { $0.ownerId == "current_user" })?.currentStreak ?? 0)", label: "Day Streak", color: Color(hex: "feca57"))
                            ProgressStatItem(value: "\(challenge.daysRemaining)", label: "Remaining", color: Color(hex: "1dd1a1"))
                        }
                    }
                    .padding(16)
                    .background(Color(hex: "111111"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(20)
            }
            .background(bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
            // Radial glow
            .overlay(
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [coral.opacity(0.15), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 150, height: 150)
                    .offset(x: 60, y: -60)
                , alignment: .topTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Progress Stat Item
private struct ProgressStatItem: View {
    var icon: String? = nil
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }
            Text(value)
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(color)

            Text(label.uppercased())
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.3))
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(hex: "222222"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Refined Completed Challenge Row
private struct RefinedCompletedChallengeRow: View {
    let challenge: Challenge

    private let bgCard = Color(hex: "161616")
    private let gold = Color(hex: "feca57")
    private let lime = Color(hex: "1dd1a1")

    private var didWin: Bool {
        challenge.sortedParticipants.first?.ownerId == "current_user"
    }

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: didWin ? [gold, gold.opacity(0.7)] : [lime, lime.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: didWin ? "trophy.fill" : "flag.checkered")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(challenge.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)

                Text("\(challenge.durationDays) days • \(challenge.sortedParticipants.count) participants")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Text(challenge.startDate.formatted(.dateTime.month().day()))
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(14)
        .background(bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

#Preview {
    ChallengesView()
        .environmentObject(ThemeManager())
}
struct CreateChallengeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager

    @State private var selectedGoal: ChallengeGoalType?
    @State private var selectedTemplate: ChallengeTemplate?
    @State private var startDate = Date()
    @State private var selectedContacts: [SelectedContact] = []
    @State private var showContactPicker = false
    @State private var showConfirmationPopup = false

    // Button animation states
    @State private var buttonScale: CGFloat = 1.0
    @State private var buttonGlow: CGFloat = 0.0

    private var filteredTemplates: [ChallengeTemplate] {
        guard let goal = selectedGoal else { return [] }
        return ChallengeTemplate.templates.filter { $0.goalType == goal }
    }

    private func goalColor(_ goal: ChallengeGoalType) -> Color {
        switch goal {
        case .fitness: return .accentBlue
        case .strength, .muscle: return .accentOrange
        case .cardio: return .accentRed
        case .flexibility: return .purple
        case .weightLoss, .wellness: return .accentGreen
        case .endurance: return .accentYellow
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 24) {
                        // Step 1: Choose Goal
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("1")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Color.accentBlue)
                                    .clipShape(Circle())

                                Text("Choose Your Goal")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }

                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(ChallengeGoalType.allCases, id: \.self) { goal in
                                    GoalSelectionCard(
                                        goal: goal,
                                        color: goalColor(goal),
                                        isSelected: selectedGoal == goal
                                    ) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            if selectedGoal == goal {
                                                selectedGoal = nil
                                                selectedTemplate = nil
                                            } else {
                                                selectedGoal = goal
                                                selectedTemplate = nil
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Step 2: Choose Challenge (shown after goal selection)
                        if selectedGoal != nil {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("2")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                        .frame(width: 24, height: 24)
                                        .background(Color.accentOrange)
                                        .clipShape(Circle())

                                    Text("Select a Challenge")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                }

                                if filteredTemplates.isEmpty {
                                    Text("No challenges available for this goal yet.")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                } else {
                                    VStack(spacing: 12) {
                                        ForEach(filteredTemplates) { template in
                                            ChallengeOptionCard(
                                                template: template,
                                                color: goalColor(selectedGoal!),
                                                isSelected: selectedTemplate?.id == template.id
                                            ) {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    selectedTemplate = template
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        // Step 3: Start Date (shown after template selection)
                        if selectedTemplate != nil {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("3")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                        .frame(width: 24, height: 24)
                                        .background(Color.accentGreen)
                                        .clipShape(Circle())

                                    Text("When to Start?")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                }

                                DatePicker("Start Date", selection: $startDate, in: Date()..., displayedComponents: .date)
                                    .datePickerStyle(.graphical)
                                    .tint(goalColor(selectedGoal!))
                                    .padding()
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .padding(.horizontal)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        // Step 4: Invite Friends (shown after template selection)
                        if selectedTemplate != nil {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("4")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                        .frame(width: 24, height: 24)
                                        .background(Color.purple)
                                        .clipShape(Circle())

                                    Text("Invite Friends & Family")
                                        .font(.headline)
                                        .fontWeight(.bold)

                                    Text("(Required)")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                }

                                // Selected contacts display
                                if !selectedContacts.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(selectedContacts) { contact in
                                                SelectedContactChip(contact: contact) {
                                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                        selectedContacts.removeAll { $0.id == contact.id }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // Add friends button
                                Button {
                                    showContactPicker = true
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "person.badge.plus")
                                            .font(.title2)
                                            .foregroundStyle(Color.purple)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Add from Contacts")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.primary)

                                            Text(selectedContacts.isEmpty ? "Challenge your friends and family" : "\(selectedContacts.count) selected • Tap to add more")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                    .padding()
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        Spacer(minLength: 120)
                    }
                    .padding(.top)
                }
                .background(.ultraThinMaterial)
                .blur(radius: showConfirmationPopup ? 8 : 0)
                .animation(.easeInOut(duration: 0.25), value: showConfirmationPopup)

                // Blur overlay and confirmation popup
                if showConfirmationPopup {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showConfirmationPopup = false
                            }
                        }

                    ChallengeConfirmationPopup(
                        template: selectedTemplate,
                        startDate: startDate,
                        selectedContacts: selectedContacts,
                        goalColor: selectedGoal != nil ? goalColor(selectedGoal!) : .accentBlue,
                        onConfirm: {
                            createChallenge()
                        },
                        onCancel: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showConfirmationPopup = false
                            }
                        }
                    )
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                }
            }
            .navigationTitle("Create Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if selectedTemplate != nil {
                    VStack(spacing: 8) {
                        if selectedContacts.isEmpty {
                            Text("Add at least one friend or family member to create a challenge")
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .multilineTextAlignment(.center)
                        }

                        Button {
                            guard !selectedContacts.isEmpty else { return }

                            // Animate button press
                            withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
                                buttonScale = 0.95
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    buttonScale = 1.05
                                }
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                    buttonScale = 1.0
                                }
                                // Show confirmation popup
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    showConfirmationPopup = true
                                }
                            }

                            themeManager.mediumImpact()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "sparkles")
                                    .font(.headline)
                                Text("Create Challenge")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                ZStack {
                                    selectedContacts.isEmpty ? Color.gray : goalColor(selectedGoal!)

                                    // Glow effect
                                    goalColor(selectedGoal!)
                                        .blur(radius: 20)
                                        .opacity(selectedContacts.isEmpty ? 0 : buttonGlow)
                                }
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: (selectedContacts.isEmpty ? Color.gray : goalColor(selectedGoal!)).opacity(0.4), radius: 8, y: 4)
                        }
                        .disabled(selectedContacts.isEmpty)
                        .scaleEffect(buttonScale)
                        .onAppear {
                            startButtonGlowAnimation()
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                }
            }
            .fullScreenCover(isPresented: $showContactPicker) {
                ContactPickerView(selectedContacts: $selectedContacts)
                    .background(.ultraThinMaterial)
            }
        }
    }

    private func startButtonGlowAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatCount(3, autoreverses: true)) {
            buttonGlow = 0.3
        }
        // Settle to subtle glow after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                buttonGlow = 0.15
            }
        }
    }

    private func createChallenge() {
        guard let template = selectedTemplate else { return }

        let challenge = Challenge(
            name: template.name,
            description: template.description,
            durationDays: template.durationDays,
            startDate: startDate,
            goalType: template.goalType,
            location: .anywhere,
            creatorId: "current_user"
        )

        // Add current user as owner
        let ownerParticipant = ChallengeParticipant(
            ownerId: "current_user",
            displayName: "You",
            avatarEmoji: "💪",
            isOwner: true
        )
        ownerParticipant.challenge = challenge
        modelContext.insert(ownerParticipant)

        // Add selected contacts as participants
        let emojis = ["😀", "🎯", "🔥", "⭐️", "🚀", "💫", "🌟", "✨"]
        for (index, contact) in selectedContacts.prefix(5).enumerated() {
            let participant = ChallengeParticipant(
                ownerId: contact.id,
                displayName: contact.name,
                avatarEmoji: emojis[index % emojis.count],
                isOwner: false
            )
            participant.challenge = challenge
            modelContext.insert(participant)
        }

        modelContext.insert(challenge)
        try? modelContext.save()

        themeManager.notifySuccess()

        dismiss()
    }
}

// MARK: - Selected Contact Model
struct SelectedContact: Identifiable, Equatable {
    let id: String
    let name: String
    let initials: String
}

// MARK: - Selected Contact Chip
struct SelectedContactChip: View {
    let contact: SelectedContact
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text(contact.initials)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.purple)
                .clipShape(Circle())

            Text(contact.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.leading, 4)
        .padding(.trailing, 10)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(Capsule())
    }
}

// MARK: - Contact Picker View
struct ContactPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var selectedContacts: [SelectedContact]

    @State private var contacts: [CNContact] = []
    @State private var searchText = ""
    @State private var hasPermission = false
    @State private var showPermissionDenied = false

    private let maxFriends = 5

    private var filteredContacts: [CNContact] {
        if searchText.isEmpty {
            return contacts
        }
        return contacts.filter { contact in
            let fullName = "\(contact.givenName) \(contact.familyName)".lowercased()
            return fullName.contains(searchText.lowercased())
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Selection counter header
                HStack {
                    Text("Selected")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(selectedContacts.count)/\(maxFriends)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(selectedContacts.count == maxFriends ? .orange : .accentColor)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))

                Group {
                    if showPermissionDenied {
                        VStack(spacing: 16) {
                            Image(systemName: "person.crop.circle.badge.exclamationmark")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)

                            Text("Contacts Access Required")
                                .font(.headline)

                            Text("Please enable contacts access in Settings to invite friends to your challenge.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)

                            Button("Open Settings") {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(filteredContacts, id: \.identifier) { contact in
                                ContactRow(
                                    contact: contact,
                                    isSelected: selectedContacts.contains { $0.id == contact.identifier },
                                    isDisabled: !selectedContacts.contains { $0.id == contact.identifier } && selectedContacts.count >= maxFriends
                                ) {
                                    toggleContact(contact)
                                }
                            }
                        }
                        .searchable(text: $searchText, prompt: "Search contacts")
                    }
                }
            }
            .background(.ultraThinMaterial)
            .navigationTitle("Select Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    dismiss()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding()
                .background(.ultraThinMaterial)
            }
        }
        .onAppear {
            requestContactsPermission()
        }
    }

    private func requestContactsPermission() {
        let store = CNContactStore()

        store.requestAccess(for: .contacts) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    hasPermission = true
                    loadContacts()
                } else {
                    showPermissionDenied = true
                }
            }
        }
    }

    private func loadContacts() {
        let store = CNContactStore()
        let keysToFetch: [CNKeyDescriptor] = [
            CNContactIdentifierKey as CNKeyDescriptor,
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor
        ]

        let request = CNContactFetchRequest(keysToFetch: keysToFetch)
        request.sortOrder = .givenName

        var fetchedContacts: [CNContact] = []

        do {
            try store.enumerateContacts(with: request) { contact, _ in
                if !contact.givenName.isEmpty || !contact.familyName.isEmpty {
                    fetchedContacts.append(contact)
                }
            }
            contacts = fetchedContacts
        } catch {
            print("Failed to fetch contacts: \(error)")
        }
    }

    private func toggleContact(_ contact: CNContact) {
        let fullName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
        let initials = "\(contact.givenName.prefix(1))\(contact.familyName.prefix(1))".uppercased()

        if let index = selectedContacts.firstIndex(where: { $0.id == contact.identifier }) {
            selectedContacts.remove(at: index)
        } else if selectedContacts.count < 5 {
            let selectedContact = SelectedContact(
                id: contact.identifier,
                name: fullName,
                initials: initials.isEmpty ? "?" : initials
            )
            selectedContacts.append(selectedContact)
        }

        themeManager.lightImpact()
    }
}

// MARK: - Contact Row
struct ContactRow: View {
    let contact: CNContact
    let isSelected: Bool
    var isDisabled: Bool = false
    let onTap: () -> Void

    private var fullName: String {
        "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
    }

    private var initials: String {
        let first = contact.givenName.prefix(1)
        let last = contact.familyName.prefix(1)
        return "\(first)\(last)".uppercased()
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text(initials)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(isDisabled ? Color.gray.opacity(0.5) : Color.purple.opacity(0.8))
                    .clipShape(Circle())

                Text(fullName)
                    .font(.body)
                    .foregroundStyle(isDisabled ? .secondary : .primary)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.purple : (isDisabled ? Color.gray.opacity(0.2) : Color.gray.opacity(0.3)))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

// MARK: - Challenge Confirmation Popup
struct ChallengeConfirmationPopup: View {
    let template: ChallengeTemplate?
    let startDate: Date
    let selectedContacts: [SelectedContact]
    let goalColor: Color
    let onConfirm: () -> Void
    let onCancel: () -> Void

    @State private var animateIn = false

    var body: some View {
        VStack(spacing: 20) {
            // Header icon
            ZStack {
                Circle()
                    .fill(goalColor.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: template?.icon ?? "star.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(goalColor)
            }
            .scaleEffect(animateIn ? 1 : 0.5)
            .opacity(animateIn ? 1 : 0)

            // Challenge name
            Text(template?.name ?? "Challenge")
                .font(.title3)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            // Details
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(goalColor)
                    Text("Starts \(startDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline)
                    Spacer()
                }

                HStack {
                    Image(systemName: "clock")
                        .foregroundStyle(goalColor)
                    Text("\(template?.durationDays ?? 0) days")
                        .font(.subheadline)
                    Spacer()
                }

                HStack {
                    Image(systemName: "person.2")
                        .foregroundStyle(goalColor)
                    Text(selectedContacts.isEmpty ? "Just you" : "You + \(selectedContacts.count) friend\(selectedContacts.count == 1 ? "" : "s")")
                        .font(.subheadline)
                    Spacer()
                }
            }
            .padding()
            .background(Color(.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Participants preview
            if !selectedContacts.isEmpty {
                HStack(spacing: -8) {
                    Text("💪")
                        .font(.title2)
                        .frame(width: 36, height: 36)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))

                    ForEach(Array(selectedContacts.prefix(4).enumerated()), id: \.element.id) { index, contact in
                        Text(contact.initials)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.purple)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
                    }
                }
            }

            // Buttons
            VStack(spacing: 10) {
                Button(action: onConfirm) {
                    HStack {
                        Image(systemName: "checkmark")
                            .fontWeight(.bold)
                        Text("Let's Go!")
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(goalColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button(action: onCancel) {
                    Text("Go Back")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(24)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        .padding(.horizontal, 32)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                animateIn = true
            }
        }
    }
}

// MARK: - Goal Selection Card
struct GoalSelectionCard: View {
    let goal: ChallengeGoalType
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                Image(systemName: goal.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : color)

                Text(goal.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(isSelected ? color : color.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Challenge Option Card
struct ChallengeOptionCard: View {
    let template: ChallengeTemplate
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Icon
                Image(systemName: template.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : color)
                    .frame(width: 50, height: 50)
                    .background(isSelected ? color : color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(template.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Label("\(template.durationDays) days", systemImage: "calendar")
                        Label(template.difficulty.displayName, systemImage: "chart.bar.fill")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? color : Color.gray.opacity(0.3))
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Join Challenge View
struct JoinChallengeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var inviteCode = ""
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.accentGreen.opacity(0.1))
                        .frame(width: 100, height: 100)

                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.accentGreen)
                }
                .padding(.top, 40)

                VStack(spacing: 8) {
                    Text("Join a Challenge")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Enter the 6-character invite code shared by your friend.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Code input
                TextField("INVITE CODE", text: $inviteCode)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 32)
                    .onChange(of: inviteCode) { _, newValue in
                        inviteCode = String(newValue.prefix(6)).uppercased()
                    }

                Spacer()

                Button {
                    joinChallenge()
                } label: {
                    Text("Join Challenge")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(inviteCode.count == 6 ? Color.accentGreen : Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(inviteCode.count != 6)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .background(.ultraThinMaterial)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    DismissButton { dismiss() }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func joinChallenge() {
        // Query iCloud for shared challenges, fallback to local
        let descriptor = FetchDescriptor<Challenge>(
            predicate: #Predicate { $0.inviteCode == inviteCode }
        )

        if let challenges = try? modelContext.fetch(descriptor),
           let challenge = challenges.first {
            // Check if already a participant
            let currentUserId = "current_user"
            if challenge.participants?.contains(where: { $0.ownerId == currentUserId }) == true {
                errorMessage = "You're already in this challenge!"
                showError = true
                return
            }

            // Check participant limit (5 + owner = 6 max)
            if (challenge.participants?.count ?? 0) >= 6 {
                errorMessage = "This challenge is full (max 6 participants)."
                showError = true
                return
            }

            // Add participant
            let participant = ChallengeParticipant(
                ownerId: currentUserId,
                displayName: "You",
                avatarEmoji: ["😀", "🎯", "🔥", "⭐️", "🚀"].randomElement()!,
                isOwner: false
            )
            participant.challenge = challenge

            modelContext.insert(participant)
            try? modelContext.save()

            dismiss()
        } else {
            errorMessage = "Challenge not found. Please check the code and try again."
            showError = true
        }
    }
}

// MARK: - Challenge Detail View
struct ChallengeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager
    let challenge: Challenge

    @State private var showShareSheet = false
    @State private var showLeaveConfirmation = false
    @State private var showShutdownSheet = false

    private var currentUserParticipant: ChallengeParticipant? {
        challenge.participants?.first { $0.ownerId == "current_user" }
    }

    private var isOwner: Bool {
        challenge.creatorId == "current_user"
    }

    private var goalColor: Color {
        switch challenge.goalType {
        case .fitness: return .accentBlue
        case .strength, .muscle: return .accentOrange
        case .cardio: return .accentRed
        case .flexibility: return .purple
        case .weightLoss, .wellness: return .accentGreen
        case .endurance: return .accentYellow
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero card
                    VStack(spacing: 16) {
                        // Icon and progress
                        ZStack {
                            Circle()
                                .stroke(goalColor.opacity(0.2), lineWidth: 8)
                                .frame(width: 100, height: 100)

                            Circle()
                                .trim(from: 0, to: challenge.progress)
                                .stroke(goalColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .frame(width: 100, height: 100)
                                .rotationEffect(.degrees(-90))

                            VStack(spacing: 2) {
                                Text("Day")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(challenge.currentDay)")
                                    .font(.title)
                                    .fontWeight(.bold)
                            }
                        }

                        Text(challenge.name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        // Stats row
                        HStack(spacing: 24) {
                            VStack {
                                Text("\(challenge.durationDays)")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text("Total Days")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            VStack {
                                Text("\(challenge.daysRemaining)")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text("Remaining")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            VStack {
                                Text("\(challenge.participants?.count ?? 0)")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text("Participants")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        // Segmented Progress Indicator
                        SegmentedProgressIndicator(
                            currentDay: challenge.currentDay,
                            totalDays: challenge.durationDays,
                            completedDays: currentUserParticipant?.completedDays ?? 0,
                            accentColor: goalColor,
                            isLightBackground: true
                        )
                        .padding(.top, 8)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal)

                    // Today's check-in
                    if !challenge.isCompleted {
                        TodayCheckInCard(
                            challenge: challenge,
                            participant: currentUserParticipant,
                            goalColor: goalColor
                        )
                        .padding(.horizontal)
                    }

                    // Leaderboard
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Leaderboard")
                            .font(.headline)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        VStack(spacing: 8) {
                            ForEach(Array(challenge.sortedParticipants.enumerated()), id: \.element.id) { index, participant in
                                ParticipantRow(
                                    rank: index + 1,
                                    participant: participant,
                                    totalDays: challenge.durationDays,
                                    isCurrentUser: participant.ownerId == "current_user"
                                )
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Invite section
                    VStack(spacing: 12) {
                        Text("Invite Friends")
                            .font(.headline)
                            .fontWeight(.bold)

                        HStack(spacing: 12) {
                            Text(challenge.inviteCode)
                                .font(.title2)
                                .fontWeight(.bold)
                                .tracking(4)

                            Button {
                                UIPasteboard.general.string = challenge.inviteCode
                                themeManager.mediumImpact()
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .font(.title3)
                                    .foregroundStyle(Color.accentBlue)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        Text("Share this code with up to 5 friends")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)

                    // Shutdown Option (only for owner)
                    if isOwner && !challenge.isCompleted && !challenge.isShutdown {
                        VStack(spacing: 12) {
                            Text("Challenge Management")
                                .font(.headline)
                                .fontWeight(.bold)

                            Button {
                                showShutdownSheet = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.headline)
                                    Text("End Challenge Early")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.red.opacity(0.8))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            Text("This will notify all participants and end the challenge immediately")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                    }

                    // Show if challenge was shutdown
                    if challenge.isShutdown {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text("Challenge Ended Early")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }

                            if let reason = challenge.shutdownReason, !reason.isEmpty {
                                Text("\"\(reason)\"")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .italic()
                                    .multilineTextAlignment(.center)
                            }

                            if let date = challenge.shutdownDate {
                                Text("Ended on \(date.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(.ultraThinMaterial)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    DismissButton { dismiss() }
                }
            }
            .sheet(isPresented: $showShutdownSheet) {
                ShutdownChallengeSheet(challenge: challenge) {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Shutdown Challenge Sheet
struct ShutdownChallengeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager
    let challenge: Challenge
    let onShutdown: () -> Void

    @State private var shutdownReason = ""
    @FocusState private var isReasonFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Warning Icon
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 80, height: 80)

                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.red)
                }

                // Title and description
                VStack(spacing: 8) {
                    Text("End Challenge?")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("This will immediately end the challenge for all \(challenge.participants?.count ?? 0) participants. They will be notified.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Reason input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reason (shared with participants)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    TextField("e.g., Schedule conflict, health issue, etc.", text: $shutdownReason, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .lineLimit(3...5)
                        .focused($isReasonFocused)
                }

                Spacer()

                // Buttons
                VStack(spacing: 12) {
                    Button {
                        shutdownChallenge()
                    } label: {
                        Text("End Challenge")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .padding(24)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                isReasonFocused = true
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func shutdownChallenge() {
        challenge.isShutdown = true
        challenge.isActive = false
        challenge.shutdownDate = Date()
        challenge.shutdownReason = shutdownReason.isEmpty ? nil : shutdownReason
        challenge.shutdownByUserId = "current_user"

        try? modelContext.save()
        themeManager.notifyWarning()

        dismiss()
        onShutdown()
    }
}

// MARK: - Today Check-In Card
struct TodayCheckInCard: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager
    let challenge: Challenge
    let participant: ChallengeParticipant?
    let goalColor: Color

    @State private var hasCheckedInToday = false

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Day \(challenge.currentDay) Check-In")
                        .font(.headline)
                        .fontWeight(.bold)

                    Text(hasCheckedInToday ? "Completed!" : "Mark today as complete")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    checkInToday()
                } label: {
                    Image(systemName: hasCheckedInToday ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 44))
                        .foregroundStyle(hasCheckedInToday ? Color.accentGreen : goalColor.opacity(0.3))
                }
                .disabled(hasCheckedInToday)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            checkTodayStatus()
        }
    }

    private func checkTodayStatus() {
        guard let participant = participant else { return }
        hasCheckedInToday = participant.dayLogs?.contains { $0.dayNumber == challenge.currentDay && $0.isCompleted } ?? false
    }

    private func checkInToday() {
        guard let participant = participant else { return }

        let dayLog = ChallengeDayLog(dayNumber: challenge.currentDay, isCompleted: true)
        dayLog.participant = participant

        participant.logDay(day: challenge.currentDay, completed: true)

        modelContext.insert(dayLog)
        try? modelContext.save()

        hasCheckedInToday = true

        themeManager.notifySuccess()
    }
}

// MARK: - Participant Row
struct ParticipantRow: View {
    let rank: Int
    let participant: ChallengeParticipant
    let totalDays: Int
    let isCurrentUser: Bool

    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .clear
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Rank
            ZStack {
                if rank <= 3 {
                    Circle()
                        .fill(rankColor.opacity(0.2))
                        .frame(width: 28, height: 28)
                }

                Text("\(rank)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(rank <= 3 ? rankColor : .secondary)
            }
            .frame(width: 28)

            // Avatar
            Text(participant.avatarEmoji)
                .font(.title2)

            // Name and stats
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(participant.displayName)
                        .font(.subheadline)
                        .fontWeight(isCurrentUser ? .bold : .medium)

                    if isCurrentUser {
                        Text("(You)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text("\(participant.completedDays)/\(totalDays) days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Streak
            if participant.currentStreak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text("\(participant.currentStreak)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }

            // Progress
            Text("\(Int(participant.completionPercentage * 100))%")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.accentGreen)
        }
        .padding()
        .background(isCurrentUser ? Color.accentBlue.opacity(0.1) : Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Leaderboard Card
private struct LeaderboardCard: View {
    let participants: [ChallengeParticipant]
    let totalDays: Int

    private var topThree: [ChallengeParticipant] {
        Array(participants.prefix(3))
    }

    private var remaining: [ChallengeParticipant] {
        Array(participants.dropFirst(3))
    }

    var body: some View {
        VStack(spacing: 20) {
            // Podium for top 3
            if participants.count >= 1 {
                PodiumView(participants: topThree, totalDays: totalDays)
            }

            // Remaining participants
            if !remaining.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(remaining.enumerated()), id: \.element.id) { index, participant in
                        LeaderboardListRow(
                            rank: index + 4,
                            participant: participant,
                            totalDays: totalDays,
                            isCurrentUser: participant.ownerId == "current_user"
                        )

                        if index < remaining.count - 1 {
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Podium View
private struct PodiumView: View {
    let participants: [ChallengeParticipant]
    let totalDays: Int

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // 2nd place (left)
            if participants.count >= 2 {
                PodiumPlace(
                    participant: participants[1],
                    rank: 2,
                    totalDays: totalDays,
                    height: 100
                )
            } else {
                Spacer()
                    .frame(maxWidth: .infinity)
            }

            // 1st place (center, tallest)
            if participants.count >= 1 {
                PodiumPlace(
                    participant: participants[0],
                    rank: 1,
                    totalDays: totalDays,
                    height: 130
                )
            }

            // 3rd place (right)
            if participants.count >= 3 {
                PodiumPlace(
                    participant: participants[2],
                    rank: 3,
                    totalDays: totalDays,
                    height: 80
                )
            } else {
                Spacer()
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Podium Place
private struct PodiumPlace: View {
    let participant: ChallengeParticipant
    let rank: Int
    let totalDays: Int
    let height: CGFloat

    @State private var isAnimating = false

    private var medalColor: Color {
        switch rank {
        case 1: return Color(hex: "fbbf24") // Gold
        case 2: return Color(hex: "9ca3af") // Silver
        case 3: return Color(hex: "f97316") // Bronze
        default: return .gray
        }
    }

    private var medalIcon: String {
        switch rank {
        case 1: return "crown.fill"
        case 2, 3: return "medal.fill"
        default: return "circle.fill"
        }
    }

    private var podiumGradient: LinearGradient {
        switch rank {
        case 1:
            return LinearGradient(
                colors: [Color(hex: "fbbf24"), Color(hex: "f59e0b")],
                startPoint: .top,
                endPoint: .bottom
            )
        case 2:
            return LinearGradient(
                colors: [Color(hex: "9ca3af"), Color(hex: "6b7280")],
                startPoint: .top,
                endPoint: .bottom
            )
        case 3:
            return LinearGradient(
                colors: [Color(hex: "f97316"), Color(hex: "ea580c")],
                startPoint: .top,
                endPoint: .bottom
            )
        default:
            return LinearGradient(colors: [.gray], startPoint: .top, endPoint: .bottom)
        }
    }

    private var isCurrentUser: Bool {
        participant.ownerId == "current_user"
    }

    var body: some View {
        VStack(spacing: 8) {
            // Avatar with medal
            ZStack {
                // Glow for 1st place
                if rank == 1 {
                    Circle()
                        .fill(medalColor.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .blur(radius: 10)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                }

                // Avatar circle
                Text(participant.avatarEmoji)
                    .font(.system(size: rank == 1 ? 40 : 32))
                    .frame(width: rank == 1 ? 70 : 56, height: rank == 1 ? 70 : 56)
                    .background(
                        Circle()
                            .fill(Color(.tertiarySystemGroupedBackground))
                    )
                    .overlay(
                        Circle()
                            .stroke(medalColor, lineWidth: rank == 1 ? 4 : 3)
                    )

                // Medal badge
                Image(systemName: medalIcon)
                    .font(.system(size: rank == 1 ? 18 : 14))
                    .foregroundStyle(medalColor)
                    .background(
                        Circle()
                            .fill(Color(.secondarySystemGroupedBackground))
                            .frame(width: rank == 1 ? 28 : 24, height: rank == 1 ? 28 : 24)
                    )
                    .offset(y: rank == 1 ? -35 : -28)
            }

            // Name
            Text(participant.displayName)
                .font(rank == 1 ? .subheadline : .caption)
                .fontWeight(isCurrentUser ? .bold : .semibold)
                .lineLimit(1)

            // Stats
            VStack(spacing: 2) {
                Text("\(Int(participant.completionPercentage * 100))%")
                    .font(rank == 1 ? .title2 : .headline)
                    .fontWeight(.bold)
                    .foregroundStyle(medalColor)

                if participant.currentStreak > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text("\(participant.currentStreak)")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                }
            }

            // Podium base
            RoundedRectangle(cornerRadius: 8)
                .fill(podiumGradient)
                .frame(height: height - 60)
                .overlay(
                    Text("\(rank)")
                        .font(.title2)
                        .fontWeight(.heavy)
                        .foregroundStyle(.white.opacity(0.5))
                )
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            if rank == 1 {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
        }
    }
}

// MARK: - Leaderboard List Row
private struct LeaderboardListRow: View {
    let rank: Int
    let participant: ChallengeParticipant
    let totalDays: Int
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: 14) {
            // Rank
            Text("\(rank)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
                .frame(width: 28)

            // Avatar
            Text(participant.avatarEmoji)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(Circle())

            // Name and streak
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(participant.displayName)
                        .font(.subheadline)
                        .fontWeight(isCurrentUser ? .bold : .medium)

                    if isCurrentUser {
                        Text("You")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentBlue)
                            .clipShape(Capsule())
                    }
                }

                if participant.currentStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text("\(participant.currentStreak) day streak")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Progress
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(participant.completionPercentage * 100))%")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.accentGreen)

                Text("\(participant.completedDays)/\(totalDays)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(isCurrentUser ? Color.accentBlue.opacity(0.08) : Color.clear)
    }
}

// MARK: - Segmented Progress Indicator
private struct SegmentedProgressIndicator: View {
    let currentDay: Int
    let totalDays: Int
    let completedDays: Int
    var accentColor: Color = .white
    var isLightBackground: Bool = false

    // Determine how to display segments based on total days
    private var displayMode: DisplayMode {
        if totalDays <= 14 {
            return .daily
        } else if totalDays <= 60 {
            return .weekly
        } else {
            return .monthly
        }
    }

    private enum DisplayMode {
        case daily, weekly, monthly
    }

    private var segments: [SegmentData] {
        switch displayMode {
        case .daily:
            return (1...totalDays).map { day in
                SegmentData(
                    index: day,
                    label: "\(day)",
                    isCompleted: day < currentDay,
                    isCurrent: day == currentDay,
                    isFuture: day > currentDay
                )
            }
        case .weekly:
            let weeks = (totalDays + 6) / 7
            let currentWeek = (currentDay + 6) / 7
            return (1...weeks).map { week in
                SegmentData(
                    index: week,
                    label: "W\(week)",
                    isCompleted: week < currentWeek,
                    isCurrent: week == currentWeek,
                    isFuture: week > currentWeek
                )
            }
        case .monthly:
            let months = (totalDays + 29) / 30
            let currentMonth = (currentDay + 29) / 30
            return (1...months).map { month in
                SegmentData(
                    index: month,
                    label: "M\(month)",
                    isCompleted: month < currentMonth,
                    isCurrent: month == currentMonth,
                    isFuture: month > currentMonth
                )
            }
        }
    }

    private var labelColor: Color {
        isLightBackground ? .secondary : .white.opacity(0.5)
    }

    private var currentLabelColor: Color {
        isLightBackground ? accentColor : .white.opacity(0.8)
    }

    var body: some View {
        VStack(spacing: 8) {
            // Segment bar
            HStack(spacing: 3) {
                ForEach(segments, id: \.index) { segment in
                    SegmentView(
                        segment: segment,
                        totalSegments: segments.count,
                        accentColor: accentColor,
                        isLightBackground: isLightBackground
                    )
                }
            }
            .frame(height: 24)

            // Labels for key points
            HStack {
                Text("Day 1")
                    .font(.caption2)
                    .foregroundStyle(labelColor)

                Spacer()

                if currentDay > 1 && currentDay < totalDays {
                    Text("Day \(currentDay)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(currentLabelColor)

                    Spacer()
                }

                Text("Day \(totalDays)")
                    .font(.caption2)
                    .foregroundStyle(labelColor)
            }
        }
    }
}

// MARK: - Segment Data
private struct SegmentData {
    let index: Int
    let label: String
    let isCompleted: Bool
    let isCurrent: Bool
    let isFuture: Bool
}

// MARK: - Segment View
private struct SegmentView: View {
    let segment: SegmentData
    let totalSegments: Int
    var accentColor: Color = .white
    var isLightBackground: Bool = false

    @State private var isPulsing = false

    private var fillColor: Color {
        if isLightBackground {
            if segment.isCompleted {
                return accentColor
            } else if segment.isCurrent {
                return accentColor.opacity(0.7)
            } else {
                return accentColor.opacity(0.2)
            }
        } else {
            if segment.isCompleted {
                return .white
            } else if segment.isCurrent {
                return .white.opacity(0.7)
            } else {
                return .white.opacity(0.2)
            }
        }
    }

    private var pulseColor: Color {
        isLightBackground ? accentColor : .white
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: totalSegments <= 14 ? 4 : 2)
                .fill(fillColor)
                .frame(maxWidth: .infinity)

            if segment.isCurrent {
                // Pulse glow effect
                RoundedRectangle(cornerRadius: totalSegments <= 14 ? 4 : 2)
                    .fill(pulseColor)
                    .opacity(isPulsing ? 0.3 : 0.6)
                    .scaleEffect(isPulsing ? 1.0 : 1.1)
                    .animation(
                        .easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true),
                        value: isPulsing
                    )

                // Border pulse
                RoundedRectangle(cornerRadius: totalSegments <= 14 ? 4 : 2)
                    .stroke(pulseColor, lineWidth: isPulsing ? 1 : 2)
                    .opacity(isPulsing ? 0.5 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true),
                        value: isPulsing
                    )
            }
        }
        .onAppear {
            if segment.isCurrent {
                isPulsing = true
            }
        }
    }
}

// MARK: - Leaderboard Row Compact
private struct LeaderboardRowCompact: View {
    let rank: Int
    let participant: ChallengeParticipant
    let totalDays: Int
    let isCurrentUser: Bool

    private var rankColor: Color {
        switch rank {
        case 1: return Color(hex: "eab308") // Gold
        case 2: return Color(hex: "9ca3af") // Silver
        case 3: return Color(hex: "f97316") // Bronze
        default: return .secondary
        }
    }

    private var rankIcon: String? {
        switch rank {
        case 1: return "crown.fill"
        case 2: return "medal.fill"
        case 3: return "medal.fill"
        default: return nil
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Rank badge
            ZStack {
                if rank <= 3 {
                    Circle()
                        .fill(rankColor.opacity(0.15))
                        .frame(width: 32, height: 32)

                    if let icon = rankIcon {
                        Image(systemName: icon)
                            .font(.caption)
                            .foregroundStyle(rankColor)
                    }
                } else {
                    Text("\(rank)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                        .frame(width: 32)
                }
            }

            // Avatar
            Text(participant.avatarEmoji)
                .font(.title3)
                .frame(width: 36, height: 36)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(Circle())

            // Name and streak
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(participant.displayName)
                        .font(.subheadline)
                        .fontWeight(isCurrentUser ? .bold : .medium)

                    if isCurrentUser {
                        Text("You")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentBlue)
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 4) {
                    if participant.currentStreak > 0 {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text("\(participant.currentStreak) day streak")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(participant.completedDays) days completed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Progress
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(participant.completionPercentage * 100))%")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(rank == 1 ? rankColor : Color.accentGreen)

                Text("\(participant.completedDays)/\(totalDays)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(isCurrentUser ? Color.accentBlue.opacity(0.08) : Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isCurrentUser ? Color.accentBlue.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Your Progress Card
private struct YourProgressCard: View {
    let participant: ChallengeParticipant
    let challenge: Challenge

    var body: some View {
        VStack(spacing: 16) {
            // Stats grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ProgressStatItem(
                    icon: "checkmark.circle.fill",
                    value: "\(participant.completedDays)",
                    label: "Days Done",
                    color: .accentGreen
                )

                ProgressStatItem(
                    icon: "flame.fill",
                    value: "\(participant.currentStreak)",
                    label: "Streak",
                    color: .orange
                )

                ProgressStatItem(
                    icon: "trophy.fill",
                    value: "\(participant.longestStreak)",
                    label: "Best Streak",
                    color: .yellow
                )
            }

            Divider()

            // Type-specific stats
            switch challenge.goalType {
            case .cardio, .endurance:
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ProgressStatItem(
                        icon: "figure.run",
                        value: participant.formattedTotalDistance,
                        label: "Distance",
                        color: .accentBlue
                    )
                    ProgressStatItem(
                        icon: "clock.fill",
                        value: participant.formattedTotalDuration,
                        label: "Total Time",
                        color: .purple
                    )
                }
            case .strength, .muscle:
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ProgressStatItem(
                        icon: "dumbbell.fill",
                        value: participant.formattedTotalWeight,
                        label: "Lifted",
                        color: .accentOrange
                    )
                    ProgressStatItem(
                        icon: "star.fill",
                        value: "\(participant.prsAchieved ?? 0)",
                        label: "PRs",
                        color: .yellow
                    )
                }
            default:
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ProgressStatItem(
                        icon: "clock.fill",
                        value: participant.formattedTotalDuration,
                        label: "Total Time",
                        color: .purple
                    )
                    ProgressStatItem(
                        icon: "flame.fill",
                        value: "\(participant.totalCaloriesBurned ?? 0)",
                        label: "Calories",
                        color: .accentRed
                    )
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Challenge Info Card
private struct ChallengeInfoCard: View {
    let challenge: Challenge

    private var goalColor: Color {
        switch challenge.goalType {
        case .fitness: return .accentBlue
        case .strength, .muscle: return .accentOrange
        case .cardio: return .accentRed
        case .flexibility: return .purple
        case .weightLoss, .wellness: return .accentGreen
        case .endurance: return .accentYellow
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Goal type and location
            HStack(spacing: 16) {
                // Goal type
                HStack(spacing: 8) {
                    Image(systemName: challenge.goalType.icon)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(goalColor)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Goal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(challenge.goalType.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }

                Spacer()

                // Location
                HStack(spacing: 8) {
                    Image(systemName: challenge.location.icon)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.accentTeal)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Location")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(challenge.location.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
            }

            Divider()

            // Dates
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Started")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(challenge.startDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Ends")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(challenge.endDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }

            // Description if available
            if !challenge.challengeDescription.isEmpty {
                Divider()

                Text(challenge.challengeDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Invite code
            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Invite Code")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(challenge.inviteCode)
                        .font(.headline)
                        .fontWeight(.bold)
                        .tracking(2)
                }

                Spacer()

                Button {
                    UIPasteboard.general.string = challenge.inviteCode
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.body)
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.accentBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ChallengesView()
}
