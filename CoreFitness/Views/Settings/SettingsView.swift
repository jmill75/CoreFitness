import SwiftUI

struct SettingsView: View {

    // MARK: - Environment
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userProfileManager: UserProfileManager

    // MARK: - Bindings
    @Binding var selectedTab: Tab

    // MARK: - State
    @State private var showSubscription = false
    @State private var showSignOutAlert = false

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List {
                    // Header Section
                    Section {
                        Text("Settings")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                    }
                    .listRowBackground(Color.clear)
                    .id("top")

                // User Profile Section
                Section {
                    UserProfileCard()
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                // Subscription Section
                Section {
                    Button {
                        showSubscription = true
                    } label: {
                        HStack {
                            Label("Subscription", systemImage: "crown.fill")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("Free")
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Account")
                }

                // Appearance Section
                Section {
                    // Theme Picker
                    Picker(selection: $themeManager.selectedTheme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    } label: {
                        Label("Theme", systemImage: "paintpalette.fill")
                    }

                    // Color Scheme
                    Picker(selection: $themeManager.colorSchemePreference) {
                        Text("System").tag(ColorSchemePreference.system)
                        Text("Light").tag(ColorSchemePreference.light)
                        Text("Dark").tag(ColorSchemePreference.dark)
                    } label: {
                        Label("Appearance", systemImage: "circle.lefthalf.filled")
                    }
                } header: {
                    Text("Appearance")
                }

                // Workout Settings Section
                Section {
                    NavigationLink {
                        RestTimerSettingsView()
                    } label: {
                        Label("Rest Timer", systemImage: "timer")
                    }

                    Picker(selection: $themeManager.useMetric) {
                        Text("lbs").tag(false)
                        Text("kg").tag(true)
                    } label: {
                        Label("Units", systemImage: "scalemass.fill")
                    }

                    Toggle(isOn: $userProfileManager.autoPlayExerciseVideos) {
                        Label("Auto-Play Exercise Videos", systemImage: "play.circle.fill")
                    }
                } header: {
                    Text("Workout")
                } footer: {
                    Text("When enabled, exercise demonstration videos will play automatically. Disable to tap to play.")
                }

                // Feedback Section
                Section {
                    Toggle(isOn: $themeManager.hapticsEnabled) {
                        Label("Haptic Feedback", systemImage: "hand.tap.fill")
                    }

                    Toggle(isOn: $themeManager.soundsEnabled) {
                        Label("Sound Effects", systemImage: "speaker.wave.2.fill")
                    }
                } header: {
                    Text("Feedback")
                }

                // Notifications Section
                Section {
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        Label("Notifications", systemImage: "bell.fill")
                    }
                } header: {
                    Text("Notifications")
                }

                // Features Section
                Section {
                    NavigationLink {
                        WaterIntakeSettingsView()
                    } label: {
                        Label("Water Intake", systemImage: "drop.fill")
                    }

                    NavigationLink {
                        MusicSettingsView()
                    } label: {
                        Label("Music", systemImage: "music.note")
                    }

                    NavigationLink {
                        QuickActionsSettingsView()
                    } label: {
                        Label("Quick Actions", systemImage: "square.grid.2x2")
                    }
                } header: {
                    Text("Features")
                }

                // AI Section
                Section {
                    NavigationLink {
                        AISettingsView()
                    } label: {
                        Label("AI Insights", systemImage: "sparkles")
                    }
                } header: {
                    Text("AI")
                } footer: {
                    Text("Get personalized advice and motivation based on your health data and activity patterns.")
                }

                // Integrations Section
                Section {
                    NavigationLink {
                        HealthKitSettingsView()
                    } label: {
                        Label("My Health Data", systemImage: "heart.fill")
                    }

                    NavigationLink {
                        WatchSettingsView()
                    } label: {
                        Label("Apple Watch", systemImage: "applewatch")
                    }
                } header: {
                    Text("Integrations")
                }

                // Data & Sync Section
                Section {
                    iCloudSyncStatusRow()
                } header: {
                    Text("Data & Sync")
                }

                // Support Section
                Section {
                    NavigationLink {
                        Text("Help & FAQ")
                    } label: {
                        Label("Help & FAQ", systemImage: "questionmark.circle")
                    }

                    NavigationLink {
                        Text("Privacy Policy")
                    } label: {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }

                    NavigationLink {
                        Text("Terms of Service")
                    } label: {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                } header: {
                    Text("Support")
                }

                // Sign Out Section
                Section {
                    Button(role: .destructive) {
                        showSignOutAlert = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                            Spacer()
                        }
                    }
                }

                // Developer Section
                #if DEBUG
                Section {
                    NavigationLink {
                        DebugDataView()
                    } label: {
                        Label("View All Data", systemImage: "ladybug.fill")
                    }

                    NavigationLink {
                        DebugActionsView()
                    } label: {
                        Label("Debug Actions", systemImage: "hammer.fill")
                    }
                } header: {
                    Text("Developer")
                } footer: {
                    Text("Debug tools for viewing and managing app data.")
                }
                #endif

                // App Version
                Section {
                    HStack {
                        Spacer()
                        Text("CoreFitness v1.0.0")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
            }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(.hidden, for: .navigationBar)
                .onChange(of: selectedTab) { _, newTab in
                    if newTab == .settings {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo("top", anchor: .top)
                        }
                    }
                }
            }
            .sheet(isPresented: $showSubscription) {
                SubscriptionView()
                    .presentationBackground(.regularMaterial)
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authManager.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}

// MARK: - User Profile Card
struct UserProfileCard: View {

    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        HStack(spacing: 16) {
            // Profile Image with gradient
            Circle()
                .fill(AppGradients.primary)
                .frame(width: 70, height: 70)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                }
                .shadow(color: Color.brandPrimary.opacity(0.3), radius: 8, y: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(authManager.currentUser?.displayName ?? "User")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(authManager.currentUser?.email ?? "user@example.com")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.accentYellow)
                    Text("Free Plan")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.brandPrimary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.brandPrimary.opacity(0.1))
                .clipShape(Capsule())
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - iCloud Sync Status Row
struct iCloudSyncStatusRow: View {
    @StateObject private var cloudStatus = CloudKitStatusService.shared

    var body: some View {
        HStack {
            Label {
                Text("iCloud Sync")
            } icon: {
                Image(systemName: "icloud.fill")
            }

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: cloudStatus.syncStatus.icon)
                    .font(.caption)
                    .foregroundStyle(cloudStatus.syncStatus.color)

                Text(cloudStatus.syncStatus.statusText)
                    .font(.subheadline)
                    .foregroundColor(cloudStatus.syncStatus.isAvailable ? .secondary : .orange)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            Task {
                await cloudStatus.checkStatus()
            }
        }
    }
}

// MARK: - Placeholder Settings Views
struct RestTimerSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var restTime: Double = 90

    private var timerColor: Color {
        switch restTime {
        case 30..<60: return .accentGreen
        case 60..<120: return .brandPrimary
        case 120..<180: return .accentOrange
        default: return .accentRed
        }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("\(Int(restTime))")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(timerColor)
                        Text("seconds")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }

                    GlassSlider(
                        value: $restTime,
                        in: 30...300,
                        step: 15,
                        tint: timerColor
                    )

                    // Quick presets
                    HStack(spacing: 8) {
                        ForEach([60, 90, 120, 180], id: \.self) { seconds in
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    restTime = Double(seconds)
                                }
                                themeManager.lightImpact()
                            } label: {
                                Text("\(seconds)s")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(restTime == Double(seconds) ? .white : .primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(restTime == Double(seconds) ? timerColor : Color(.systemGray5))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Default Rest Time")
            } footer: {
                Text("This is the default rest time between sets. You can adjust it during your workout.")
            }

            Section {
                Toggle("Auto-start Timer", isOn: .constant(true))
                    .tint(Color.brandPrimary)
                Toggle("Vibrate When Done", isOn: .constant(true))
                    .tint(Color.brandPrimary)
                Toggle("Sound Alert", isOn: .constant(false))
                    .tint(Color.brandPrimary)
            } header: {
                Text("Timer Options")
            }
        }
        .navigationTitle("Rest Timer")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct NotificationSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userProfileManager: UserProfileManager
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var showPermissionAlert = false

    private var dailyCheckInTime: CheckInTime {
        CheckInTime(rawValue: userProfileManager.dailyCheckInTimeRaw) ?? .morning
    }

    var body: some View {
        List {
            // Daily Check-In Section
            Section {
                Toggle(isOn: $userProfileManager.dailyCheckInReminderEnabled) {
                    Label("Daily Check-In Reminder", systemImage: "bell.badge.fill")
                }
                .onChange(of: userProfileManager.dailyCheckInReminderEnabled) { _, newValue in
                    if newValue && !notificationManager.isAuthorized {
                        Task {
                            let granted = await notificationManager.requestAuthorization()
                            if !granted {
                                userProfileManager.dailyCheckInReminderEnabled = false
                                showPermissionAlert = true
                            }
                        }
                    }
                    // Update notification scheduling
                    Task {
                        await notificationManager.updateDailyCheckInNotification()
                    }
                    // Haptic feedback
                    themeManager.lightImpact()
                }

                if userProfileManager.dailyCheckInReminderEnabled {
                    Picker("Reminder Time", selection: Binding(
                        get: { dailyCheckInTime },
                        set: { newTime in
                            userProfileManager.dailyCheckInTimeRaw = newTime.rawValue
                            Task {
                                await notificationManager.updateDailyCheckInNotification()
                            }
                        }
                    )) {
                        ForEach(CheckInTime.allCases, id: \.self) { time in
                            Label {
                                Text("\(time.rawValue) (\(time.description))")
                            } icon: {
                                Image(systemName: time.icon)
                            }
                            .tag(time)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
            } header: {
                Text("Daily Check-In")
            } footer: {
                Text("Get a daily reminder to log your mood, stress, and recovery levels.")
            }

            // Summaries Section
            Section {
                Toggle("Weekly Summary", isOn: .constant(true))
                Toggle("Monthly Summary", isOn: .constant(true))
            } header: {
                Text("Summaries")
            }

            // Workout Section
            Section {
                Toggle("Workout Reminders", isOn: .constant(true))
                Toggle("Rest Day Reminders", isOn: .constant(false))
                Toggle("Achievement Alerts", isOn: .constant(true))
            } header: {
                Text("Workout")
            }

            // Challenges Section
            Section {
                Toggle("Challenge Updates", isOn: .constant(true))
                Toggle("Challenge Reminders", isOn: .constant(true))
                Toggle("Leaderboard Changes", isOn: .constant(true))
                Toggle("Buddy Invitations", isOn: .constant(true))
            } header: {
                Text("Challenges")
            } footer: {
                Text("Stay updated on challenge progress, leaderboard changes, and invitations from workout buddies.")
            }

            // Notification Status
            Section {
                HStack {
                    Text("Notification Permission")
                    Spacer()
                    Text(notificationManager.isAuthorized ? "Enabled" : "Disabled")
                        .foregroundStyle(notificationManager.isAuthorized ? .green : .red)
                }

                if !notificationManager.isAuthorized {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            } header: {
                Text("System")
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Notifications Disabled", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable notifications in Settings to receive daily check-in reminders.")
        }
        .onAppear {
            Task {
                await notificationManager.checkAuthorizationStatus()
            }
        }
    }
}

struct HealthKitSettingsView: View {
    var body: some View {
        List {
            Section {
                Toggle("Sync Health Data", isOn: .constant(true))
            } footer: {
                Text("Allow CoreFitness to read and write your health data.")
            }

            Section {
                Toggle("Heart Rate", isOn: .constant(true))
                Toggle("HRV", isOn: .constant(true))
                Toggle("Sleep", isOn: .constant(true))
                Toggle("Steps", isOn: .constant(true))
                Toggle("Workouts", isOn: .constant(true))
            } header: {
                Text("Data Types")
            }
        }
        .navigationTitle("My Health Data")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WatchSettingsView: View {

    @EnvironmentObject var watchConnectivityManager: WatchConnectivityManager
    @EnvironmentObject var userProfileManager: UserProfileManager

    private var statusColor: Color {
        if watchConnectivityManager.isReachable {
            return .green
        } else if watchConnectivityManager.isPaired {
            return .orange
        } else {
            return .red
        }
    }

    var body: some View {
        List {
            // Connection Status Section
            Section {
                HStack {
                    Text("Status")
                    Spacer()
                    HStack(spacing: 6) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                        Text(watchConnectivityManager.connectionStatus)
                            .foregroundStyle(.secondary)
                    }
                }

                if watchConnectivityManager.isPaired {
                    HStack {
                        Text("Watch App")
                        Spacer()
                        Text(watchConnectivityManager.isWatchAppInstalled ? "Installed" : "Not Installed")
                            .foregroundStyle(watchConnectivityManager.isWatchAppInstalled ? .green : .orange)
                    }
                }
            } header: {
                Text("Connection")
            } footer: {
                if !watchConnectivityManager.isPaired {
                    Text("Pair an Apple Watch to enable workout mirroring and quick logging.")
                } else if !watchConnectivityManager.isWatchAppInstalled {
                    Text("Install CoreFitness on your Apple Watch to sync workouts.")
                }
            }

            // Watch Options Section
            Section {
                Toggle("Mirror Workouts", isOn: $userProfileManager.watchMirrorWorkouts)
                    .tint(Color.brandPrimary)

                Toggle("Show Heart Rate", isOn: $userProfileManager.watchShowHeartRate)
                    .tint(Color.brandPrimary)

                Toggle("Haptic Alerts", isOn: $userProfileManager.watchHapticAlerts)
                    .tint(Color.brandPrimary)
            } header: {
                Text("Watch Options")
            } footer: {
                Text("When enabled, your active workout will be mirrored to your Apple Watch.")
            }

            // Features Section
            Section {
                WatchFeatureRow(icon: "figure.strengthtraining.traditional", title: "Workout Display", description: "See current exercise and sets")
                WatchFeatureRow(icon: "timer", title: "Rest Timer", description: "Track rest periods on your wrist")
                WatchFeatureRow(icon: "heart.fill", title: "Heart Rate", description: "Monitor heart rate during workouts")
                WatchFeatureRow(icon: "checkmark.circle", title: "Quick Log", description: "Log sets directly from Watch")
            } header: {
                Text("Watch Features")
            }
        }
        .navigationTitle("Apple Watch")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct WatchFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Color.brandPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Hero
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(AppGradients.primary)
                            .frame(width: 100, height: 100)

                        Image(systemName: "crown.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: Color.brandPrimary.opacity(0.4), radius: 15, y: 8)

                    Text("Upgrade to Pro")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Unlock all features and take your fitness to the next level.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 40)

                // Features
                VStack(alignment: .leading, spacing: 12) {
                    SubscriptionFeatureRow(icon: "sparkles", text: "AI-Powered Workouts", color: .brandPrimary)
                    SubscriptionFeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Advanced Analytics", color: .accentGreen)
                    SubscriptionFeatureRow(icon: "person.2.fill", text: "Workout Sharing", color: .accentBlue)
                    SubscriptionFeatureRow(icon: "applewatch", text: "Apple Watch App", color: .accentOrange)
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                Spacer()

                GradientButton("Coming Soon", icon: "crown.fill", gradient: AppGradients.primary) {
                    dismiss()
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .navigationTitle("Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    DismissButton { dismiss() }
                }
            }
        }
    }
}

struct SubscriptionFeatureRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)

            Spacer()

            Image(systemName: "checkmark")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
    }
}

// MARK: - Water Intake Settings View
struct WaterIntakeSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userProfileManager: UserProfileManager

    var body: some View {
        List {
            // Enable/Disable Section
            Section {
                Toggle(isOn: $userProfileManager.waterIntakeEnabled) {
                    Label("Track Water Intake", systemImage: "drop.fill")
                }
                .tint(Color.accentBlue)
            } footer: {
                Text("When enabled, water intake tracking will appear in the Health tab and home screen.")
            }

            if userProfileManager.waterIntakeEnabled {
                // Goal Section
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Daily Goal")
                                .font(.subheadline)
                            Spacer()
                            Text("\(Int(userProfileManager.waterGoalOz)) oz")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.accentBlue)
                        }

                        Slider(value: $userProfileManager.waterGoalOz, in: 32...128, step: 8) {
                            Text("Goal")
                        }
                        .tint(Color.accentBlue)

                        // Quick presets
                        HStack(spacing: 8) {
                            ForEach([48, 64, 80, 96], id: \.self) { oz in
                                Button {
                                    withAnimation {
                                        userProfileManager.waterGoalOz = Double(oz)
                                    }
                                    themeManager.lightImpact()
                                } label: {
                                    Text("\(oz)oz")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(userProfileManager.waterGoalOz == Double(oz) ? .white : .primary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(userProfileManager.waterGoalOz == Double(oz) ? Color.accentBlue : Color(.systemGray5))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Daily Goal")
                } footer: {
                    Text("Recommended: 64oz (8 glasses) for most adults. Increase for active days or hot weather.")
                }

                // Reminders Section
                Section {
                    Toggle(isOn: $userProfileManager.waterReminderEnabled) {
                        Label("Hydration Reminders", systemImage: "bell.fill")
                    }
                    .tint(Color.accentBlue)

                    if userProfileManager.waterReminderEnabled {
                        Picker(selection: $userProfileManager.waterReminderInterval) {
                            Text("Every hour").tag(1.0)
                            Text("Every 2 hours").tag(2.0)
                            Text("Every 3 hours").tag(3.0)
                            Text("Every 4 hours").tag(4.0)
                        } label: {
                            Label("Reminder Frequency", systemImage: "clock")
                        }
                    }
                } header: {
                    Text("Reminders")
                } footer: {
                    Text("Get gentle reminders to stay hydrated throughout the day.")
                }

                // Container sizes info
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        ContainerSizeRow(name: "Glass", size: "8 oz", icon: "cup.and.saucer.fill")
                        ContainerSizeRow(name: "Small Bottle", size: "16 oz", icon: "waterbottle.fill")
                        ContainerSizeRow(name: "Medium Bottle", size: "24 oz", icon: "waterbottle.fill")
                        ContainerSizeRow(name: "Large Bottle", size: "32 oz", icon: "waterbottle.fill")
                        ContainerSizeRow(name: "XL Bottle", size: "64 oz", icon: "waterbottle.fill")
                    }
                } header: {
                    Text("Quick Add Sizes")
                } footer: {
                    Text("Tap these buttons in the Water Intake card to quickly log your intake.")
                }
            }
        }
        .navigationTitle("Water Intake")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ContainerSizeRow: View {
    let name: String
    let size: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(Color.accentBlue)
                .frame(width: 24)

            Text(name)
                .font(.subheadline)

            Spacer()

            Text(size)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Music Settings View
struct MusicSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userProfileManager: UserProfileManager

    @StateObject private var musicService = MusicService.shared

    var body: some View {
        List {
            // Enable/Disable Section
            Section {
                Toggle(isOn: $userProfileManager.musicEnabled) {
                    Label("Music Integration", systemImage: "music.note")
                }
                .tint(Color.brandPrimary)
            } footer: {
                Text("Enable music controls during workouts and access to workout playlists.")
            }

            if userProfileManager.musicEnabled {
                // Provider Selection
                Section {
                    ForEach(MusicService.MusicProvider.allCases) { provider in
                        Button {
                            userProfileManager.musicProvider = provider.rawValue
                            musicService.selectedProvider = provider
                            themeManager.lightImpact()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: provider.icon)
                                    .font(.title3)
                                    .foregroundStyle(provider.color)
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(provider.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)

                                    if musicService.isAppInstalled(provider) {
                                        Text("Installed")
                                            .font(.caption2)
                                            .foregroundStyle(.green)
                                    } else {
                                        Text("Not Installed")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                if userProfileManager.musicProvider == provider.rawValue {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(provider.color)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Music App")
                } footer: {
                    Text("Select your preferred music app for workout playlists.")
                }

                // Workout options
                Section {
                    Toggle(isOn: $userProfileManager.showMusicDuringWorkout) {
                        Label("Show During Workout", systemImage: "speaker.wave.2.fill")
                    }
                    .tint(Color.brandPrimary)

                    Toggle(isOn: $userProfileManager.autoPlayOnWorkoutStart) {
                        Label("Auto-Play on Start", systemImage: "play.fill")
                    }
                    .tint(Color.brandPrimary)
                } header: {
                    Text("Workout Options")
                } footer: {
                    Text("Show music controls during active workouts and optionally start playback automatically.")
                }

                // Open music app
                Section {
                    Button {
                        musicService.openMusicApp()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Open \(userProfileManager.musicProvider)", systemImage: "arrow.up.forward.app")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
            }
        }
        .navigationTitle("Music")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Sync provider selection
            if let provider = MusicService.MusicProvider.allCases.first(where: { $0.rawValue == userProfileManager.musicProvider }) {
                musicService.selectedProvider = provider
            }
        }
    }
}

// MARK: - Quick Actions Settings View
struct QuickActionsSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @AppStorage("quickActions") private var quickActionsData: Data = Data()
    @State private var showResetConfirmation = false
    @State private var showResetSuccess = false

    private var currentActions: [QuickActionType] {
        if let decoded = try? JSONDecoder().decode([QuickActionType].self, from: quickActionsData),
           !decoded.isEmpty {
            return decoded
        }
        return QuickOptionsGrid.defaultActions
    }

    private var isDefault: Bool {
        currentActions == QuickOptionsGrid.defaultActions
    }

    var body: some View {
        List {
            // Current Quick Actions Preview
            Section {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(currentActions) { action in
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(action.color.opacity(0.15))
                                    .frame(width: 40, height: 40)

                                Image(systemName: action.icon)
                                    .font(.subheadline)
                                    .foregroundStyle(action.color)
                            }

                            Text(action.title)
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Current Shortcuts")
            } footer: {
                Text("You have \(currentActions.count) quick action\(currentActions.count == 1 ? "" : "s") configured.")
            }

            // Reset Section
            Section {
                Button(role: .destructive) {
                    showResetConfirmation = true
                } label: {
                    HStack {
                        Label("Reset to Default", systemImage: "arrow.counterclockwise")
                        Spacer()
                        if isDefault {
                            Text("Already Default")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(isDefault)
            } header: {
                Text("Reset")
            } footer: {
                Text("This will restore quick actions to the default configuration: Check-In, Water, Exercises, Progress, Health, Programs, Challenges, and Settings.")
            }

            // Info Section
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.accentBlue)

                    Text("You can customize quick actions by tapping \"Edit\" on the Quick Actions section on the Home screen.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Quick Actions")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Reset Quick Actions?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetToDefault()
            }
        } message: {
            Text("This will restore all quick actions to their default configuration. This cannot be undone.")
        }
        .alert("Reset Complete", isPresented: $showResetSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Quick actions have been reset to default.")
        }
    }

    private func resetToDefault() {
        if let encoded = try? JSONEncoder().encode(QuickOptionsGrid.defaultActions) {
            quickActionsData = encoded
        }
        themeManager.mediumImpact()
        showResetSuccess = true
    }
}

// MARK: - AI Settings View
struct AISettingsView: View {
    @StateObject private var aiService = AIInsightsService.shared
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        List {
            // Enable/Disable Section
            Section {
                Toggle(isOn: Binding(
                    get: { aiService.aiEnabled },
                    set: { aiService.setAIEnabled($0) }
                )) {
                    Label("AI Insights", systemImage: "sparkles")
                }
                .tint(.purple)
            } footer: {
                Text("When enabled, you'll receive personalized advice and reminders based on your health data and activity patterns.")
            }

            if aiService.aiEnabled {
                // Insight Types Section
                Section {
                    InsightTypeRow(
                        icon: "heart.text.square",
                        title: "Health Advice",
                        description: "Get alerts when your recovery or health metrics need attention",
                        color: .red
                    )

                    InsightTypeRow(
                        icon: "face.smiling",
                        title: "Mood Support",
                        description: "Receive encouragement when you're feeling down",
                        color: .pink
                    )

                    InsightTypeRow(
                        icon: "flag.fill",
                        title: "Challenge Motivation",
                        description: "Witty reminders to stay on track with challenges",
                        color: .orange
                    )

                    InsightTypeRow(
                        icon: "drop.fill",
                        title: "Hydration Reminders",
                        description: "Gentle nudges to meet your water intake goals",
                        color: .cyan
                    )

                    InsightTypeRow(
                        icon: "figure.run",
                        title: "Activity Nudges",
                        description: "Suggestions to stay active and explore app features",
                        color: .green
                    )
                } header: {
                    Text("What AI Insights Include")
                }

                // Privacy Section
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .font(.title3)
                            .foregroundStyle(.green)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your Data Stays Private")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Text("AI insights are generated locally on your device. Your health data is never sent to external servers.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Privacy")
                }
            }
        }
        .navigationTitle("AI Insights")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InsightTypeRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SettingsView(selectedTab: .constant(.settings))
        .environmentObject(AuthManager())
        .environmentObject(ThemeManager())
        .environmentObject(UserProfileManager())
}
