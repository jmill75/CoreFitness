import SwiftUI
import SwiftData

struct ChallengesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Challenge.startDate, order: .reverse) private var challenges: [Challenge]

    @State private var showCreateChallenge = false
    @State private var showJoinChallenge = false
    @State private var selectedChallenge: Challenge?

    private var activeChallenges: [Challenge] {
        challenges.filter { $0.isActive && !$0.isCompleted }
    }

    private var completedChallenges: [Challenge] {
        challenges.filter { $0.isCompleted }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Active Challenges
                    if !activeChallenges.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Active Challenges")
                                .font(.headline)
                                .fontWeight(.bold)
                                .padding(.horizontal)

                            ForEach(activeChallenges) { challenge in
                                ActiveChallengeCard(challenge: challenge) {
                                    selectedChallenge = challenge
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Quick Actions
                    HStack(spacing: 12) {
                        ChallengeActionButton(
                            title: "Create",
                            icon: "plus.circle.fill",
                            color: .accentBlue
                        ) {
                            showCreateChallenge = true
                        }

                        ChallengeActionButton(
                            title: "Join",
                            icon: "person.badge.plus",
                            color: .accentGreen
                        ) {
                            showJoinChallenge = true
                        }
                    }
                    .padding(.horizontal)

                    // Challenge Templates
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Challenge Templates")
                                .font(.headline)
                                .fontWeight(.bold)

                            Spacer()
                        }
                        .padding(.horizontal)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(ChallengeTemplate.templates) { template in
                                ChallengeTemplateCard(template: template) {
                                    createChallengeFromTemplate(template)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Completed Challenges
                    if !completedChallenges.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Completed")
                                .font(.headline)
                                .fontWeight(.bold)
                                .padding(.horizontal)

                            ForEach(completedChallenges) { challenge in
                                CompletedChallengeCard(challenge: challenge)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Challenges")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    DismissButton { dismiss() }
                }
            }
            .sheet(isPresented: $showCreateChallenge) {
                CreateChallengeView()
            }
            .sheet(isPresented: $showJoinChallenge) {
                JoinChallengeView()
            }
            .sheet(item: $selectedChallenge) { challenge in
                ChallengeDetailView(challenge: challenge)
            }
        }
    }

    private func createChallengeFromTemplate(_ template: ChallengeTemplate) {
        let challenge = Challenge(
            name: template.name,
            description: template.description,
            durationDays: template.durationDays,
            goalType: template.goalType,
            location: template.location,
            creatorId: "current_user" // TODO: Replace with actual user ID
        )

        // Add current user as participant
        let participant = ChallengeParticipant(
            oderId: "current_user",
            displayName: "You",
            avatarEmoji: "💪",
            isOwner: true
        )
        participant.challenge = challenge

        modelContext.insert(challenge)
        modelContext.insert(participant)

        try? modelContext.save()

        selectedChallenge = challenge
    }
}

// MARK: - Active Challenge Card
struct ActiveChallengeCard: View {
    let challenge: Challenge
    let onTap: () -> Void

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
        Button(action: onTap) {
            VStack(spacing: 16) {
                // Header
                HStack {
                    // Goal icon
                    Image(systemName: challenge.goalType.icon)
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(goalColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(challenge.name)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text("Day \(challenge.currentDay) of \(challenge.durationDays)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Participants count
                    HStack(spacing: -8) {
                        ForEach(Array(challenge.sortedParticipants.prefix(3).enumerated()), id: \.offset) { index, participant in
                            Text(participant.avatarEmoji)
                                .font(.title3)
                                .frame(width: 28, height: 28)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
                        }

                        if (challenge.participants?.count ?? 0) > 3 {
                            Text("+\((challenge.participants?.count ?? 0) - 3)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .frame(width: 28, height: 28)
                                .background(Color.gray)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
                        }
                    }
                }

                // Progress bar
                VStack(spacing: 4) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(goalColor.opacity(0.2))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(goalColor)
                                .frame(width: geometry.size.width * challenge.progress, height: 8)
                        }
                    }
                    .frame(height: 8)

                    HStack {
                        Text("\(Int(challenge.progress * 100))% complete")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text("\(challenge.daysRemaining) days left")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Challenge Action Button
struct ChallengeActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Challenge Template Card
struct ChallengeTemplateCard: View {
    let template: ChallengeTemplate
    let onSelect: () -> Void

    private var goalColor: Color {
        switch template.goalType {
        case .fitness: return .accentBlue
        case .strength, .muscle: return .accentOrange
        case .cardio: return .accentRed
        case .flexibility: return .purple
        case .weightLoss, .wellness: return .accentGreen
        case .endurance: return .accentYellow
        }
    }

    private var difficultyColor: Color {
        switch template.difficulty {
        case .beginner: return .accentGreen
        case .intermediate: return .accentOrange
        case .advanced: return .accentRed
        }
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                // Icon and duration
                HStack {
                    Image(systemName: template.icon)
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(goalColor)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    Spacer()

                    Text("\(template.durationDays)d")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(goalColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(goalColor.opacity(0.15))
                        .clipShape(Capsule())
                }

                // Title
                Text(template.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Badges
                HStack(spacing: 6) {
                    Text(template.difficulty.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(difficultyColor)

                    Text("•")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Image(systemName: template.location.icon)
                        .font(.caption2)
                    Text(template.location.displayName)
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Completed Challenge Card
struct CompletedChallengeCard: View {
    let challenge: Challenge

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(Color.accentGreen)

            VStack(alignment: .leading, spacing: 2) {
                Text(challenge.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Text("Completed • \(challenge.participants?.count ?? 0) participants")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Create Challenge View
struct CreateChallengeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var description = ""
    @State private var durationDays = 30
    @State private var selectedGoal: ChallengeGoalType = .fitness
    @State private var selectedLocation: ChallengeLocation = .anywhere
    @State private var startDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Challenge Details") {
                    TextField("Challenge Name", text: $name)

                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Duration") {
                    Picker("Days", selection: $durationDays) {
                        Text("7 days").tag(7)
                        Text("14 days").tag(14)
                        Text("21 days").tag(21)
                        Text("30 days").tag(30)
                    }

                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                }

                Section("Goal") {
                    Picker("Goal Type", selection: $selectedGoal) {
                        ForEach(ChallengeGoalType.allCases, id: \.self) { goal in
                            Label(goal.displayName, systemImage: goal.icon)
                                .tag(goal)
                        }
                    }
                }

                Section("Location") {
                    Picker("Where", selection: $selectedLocation) {
                        ForEach(ChallengeLocation.allCases, id: \.self) { location in
                            Label(location.displayName, systemImage: location.icon)
                                .tag(location)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Create Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        createChallenge()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func createChallenge() {
        let challenge = Challenge(
            name: name,
            description: description,
            durationDays: durationDays,
            startDate: startDate,
            goalType: selectedGoal,
            location: selectedLocation,
            creatorId: "current_user"
        )

        let participant = ChallengeParticipant(
            oderId: "current_user",
            displayName: "You",
            avatarEmoji: "💪",
            isOwner: true
        )
        participant.challenge = challenge

        modelContext.insert(challenge)
        modelContext.insert(participant)

        try? modelContext.save()
        dismiss()
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
        // TODO: In production, this would query Firebase for the challenge
        // For now, search local challenges
        let descriptor = FetchDescriptor<Challenge>(
            predicate: #Predicate { $0.inviteCode == inviteCode }
        )

        if let challenges = try? modelContext.fetch(descriptor),
           let challenge = challenges.first {
            // Check if already a participant
            let currentUserId = "current_user"
            if challenge.participants?.contains(where: { $0.oderId == currentUserId }) == true {
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
                oderId: currentUserId,
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
    let challenge: Challenge

    @State private var showShareSheet = false
    @State private var showLeaveConfirmation = false

    private var currentUserParticipant: ChallengeParticipant? {
        challenge.participants?.first { $0.oderId == "current_user" }
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
                                    isCurrentUser: participant.oderId == "current_user"
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
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
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
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    DismissButton { dismiss() }
                }
            }
        }
    }
}

// MARK: - Today Check-In Card
struct TodayCheckInCard: View {
    @Environment(\.modelContext) private var modelContext
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

        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
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

#Preview {
    ChallengesView()
}
