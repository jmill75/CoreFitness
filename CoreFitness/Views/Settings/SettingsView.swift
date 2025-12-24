import SwiftUI

struct SettingsView: View {

    // MARK: - Environment
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager

    // MARK: - State
    @State private var showSubscription = false
    @State private var showSignOutAlert = false

    var body: some View {
        NavigationStack {
            List {
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
                } header: {
                    Text("Workout")
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

                // Integrations Section
                Section {
                    NavigationLink {
                        HealthKitSettingsView()
                    } label: {
                        Label("Apple Health", systemImage: "heart.fill")
                    }

                    NavigationLink {
                        WatchSettingsView()
                    } label: {
                        Label("Apple Watch", systemImage: "applewatch")
                    }
                } header: {
                    Text("Integrations")
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
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "gearshape.fill")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Settings")
                            .font(.headline)
                            .fontWeight(.semibold)
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

// MARK: - Placeholder Settings Views
struct RestTimerSettingsView: View {
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
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
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

    @StateObject private var notificationManager = NotificationManager.shared
    @State private var showPermissionAlert = false

    var body: some View {
        List {
            // Daily Check-In Section
            Section {
                Toggle(isOn: $notificationManager.dailyCheckInReminderEnabled) {
                    Label("Daily Check-In Reminder", systemImage: "bell.badge.fill")
                }
                .onChange(of: notificationManager.dailyCheckInReminderEnabled) { _, newValue in
                    if newValue && !notificationManager.isAuthorized {
                        Task {
                            let granted = await notificationManager.requestAuthorization()
                            if !granted {
                                notificationManager.dailyCheckInReminderEnabled = false
                                showPermissionAlert = true
                            }
                        }
                    }
                    // Haptic feedback
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }

                if notificationManager.dailyCheckInReminderEnabled {
                    Picker("Reminder Time", selection: Binding(
                        get: { notificationManager.dailyCheckInTime },
                        set: { notificationManager.dailyCheckInTime = $0 }
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
                Text("Allow CoreFitness to read and write health data from Apple Health.")
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
        .navigationTitle("Apple Health")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WatchSettingsView: View {

    @EnvironmentObject var watchConnectivityManager: WatchConnectivityManager
    @AppStorage("watchMirrorWorkouts") private var mirrorWorkouts = true
    @AppStorage("watchShowHeartRate") private var showHeartRate = true
    @AppStorage("watchHapticAlerts") private var hapticAlerts = true

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
                Toggle("Mirror Workouts", isOn: $mirrorWorkouts)
                    .tint(Color.brandPrimary)

                Toggle("Show Heart Rate", isOn: $showHeartRate)
                    .tint(Color.brandPrimary)

                Toggle("Haptic Alerts", isOn: $hapticAlerts)
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

#Preview {
    SettingsView()
        .environmentObject(AuthManager())
        .environmentObject(ThemeManager())
}
