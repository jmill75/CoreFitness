import SwiftUI
import SwiftData
import UIKit

/// Service for sharing workout summaries to social platforms
@MainActor
class SocialSharingService: ObservableObject {

    private var modelContext: ModelContext?

    init() {}

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Share Workout

    /// Generate and share a workout summary
    func shareWorkout(
        session: WorkoutSession,
        platform: SharePlatform = .other,
        caption: String? = nil
    ) -> WorkoutShare? {
        guard let context = modelContext,
              let workout = session.workout else { return nil }

        // Calculate workout stats
        let duration = session.totalDuration ?? 0
        let exerciseCount = workout.exercises?.count ?? 0
        let totalSets = session.completedSets?.count ?? 0
        let totalVolume = session.completedSets?.reduce(0.0) { $0 + ($1.weight * Double($1.reps)) } ?? 0

        // Create share record
        let share = WorkoutShare(
            sessionId: session.id,
            platform: platform,
            workoutName: workout.name,
            duration: duration,
            exerciseCount: exerciseCount,
            totalSets: totalSets,
            totalVolume: totalVolume,
            caption: caption
        )

        context.insert(share)
        try? context.save()

        return share
    }

    /// Generate shareable image for a workout
    func generateShareImage(for session: WorkoutSession) -> UIImage? {
        guard let workout = session.workout else { return nil }

        let duration = session.totalDuration ?? 0
        let exerciseCount = workout.exercises?.count ?? 0
        let totalSets = session.completedSets?.count ?? 0
        let totalVolume = session.completedSets?.reduce(0.0) { $0 + ($1.weight * Double($1.reps)) } ?? 0

        // Create a SwiftUI view for the share card
        let shareView = WorkoutShareCard(
            workoutName: workout.name,
            duration: formatDuration(duration),
            exerciseCount: exerciseCount,
            setsCompleted: totalSets,
            totalVolume: formatVolume(totalVolume),
            date: session.completedAt ?? session.startedAt
        )

        // Render to image
        let controller = UIHostingController(rootView: shareView)
        controller.view.bounds = CGRect(origin: .zero, size: CGSize(width: 400, height: 500))
        controller.view.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: controller.view.bounds.size)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }

    /// Generate share text for a workout
    func generateShareText(for session: WorkoutSession) -> String {
        guard let workout = session.workout else { return "" }

        let duration = session.totalDuration ?? 0
        let exerciseCount = workout.exercises?.count ?? 0
        let totalSets = session.completedSets?.count ?? 0
        let totalVolume = session.completedSets?.reduce(0.0) { $0 + ($1.weight * Double($1.reps)) } ?? 0

        return """
        Just crushed \(workout.name)!

        Duration: \(formatDuration(duration))
        Exercises: \(exerciseCount)
        Sets: \(totalSets)
        Volume: \(formatVolume(totalVolume))

        #CoreFitness #Workout #FitnessGoals
        """
    }

    /// Present share sheet
    func presentShareSheet(for session: WorkoutSession, from viewController: UIViewController? = nil) {
        let text = generateShareText(for: session)
        var items: [Any] = [text]

        if let image = generateShareImage(for: session) {
            items.append(image)
        }

        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)

        // Get the root view controller if none provided
        let presenter = viewController ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController

        presenter?.present(activityVC, animated: true)
    }

    // MARK: - Share History

    /// Get all shared workouts
    func getShareHistory() -> [WorkoutShare] {
        guard let context = modelContext else { return [] }

        let descriptor = FetchDescriptor<WorkoutShare>(
            sortBy: [SortDescriptor(\.sharedAt, order: .reverse)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    /// Get share count by platform
    func getShareCountByPlatform() -> [SharePlatform: Int] {
        let shares = getShareHistory()
        var counts: [SharePlatform: Int] = [:]
        for share in shares {
            counts[share.platform, default: 0] += 1
        }
        return counts
    }

    // MARK: - Helpers

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m"
        }
        return "\(minutes):\(String(format: "%02d", secs))"
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fK lbs", volume / 1000)
        }
        return String(format: "%.0f lbs", volume)
    }
}

// MARK: - Share Card View

struct WorkoutShareCard: View {
    let workoutName: String
    let duration: String
    let exerciseCount: Int
    let setsCompleted: Int
    let totalVolume: String
    let date: Date

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 50))
                    .foregroundStyle(.white)

                Text("WORKOUT COMPLETE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.top, 30)

            // Workout Name
            Text(workoutName)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            // Date
            Text(date, style: .date)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))

            // Stats Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ShareStatItem(value: duration, label: "Duration", icon: "clock.fill")
                ShareStatItem(value: "\(exerciseCount)", label: "Exercises", icon: "figure.walk")
                ShareStatItem(value: "\(setsCompleted)", label: "Sets", icon: "checkmark.circle.fill")
                ShareStatItem(value: totalVolume, label: "Volume", icon: "scalemass.fill")
            }
            .padding(.horizontal, 20)

            Spacer()

            // App branding
            HStack(spacing: 8) {
                Image(systemName: "dumbbell.fill")
                    .font(.caption)
                Text("CoreFitness")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white.opacity(0.6))
            .padding(.bottom, 20)
        }
        .frame(width: 400, height: 500)
        .background(
            LinearGradient(
                colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

struct ShareStatItem: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white.opacity(0.8))

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Share Button View

struct WorkoutShareButton: View {
    let session: WorkoutSession
    @EnvironmentObject var sharingService: SocialSharingService
    @State private var showShareSheet = false

    var body: some View {
        Button {
            showShareSheet = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                Text("Share Workout")
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.brandPrimary)
            .clipShape(Capsule())
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheetView(session: session)
                .environmentObject(sharingService)
        }
    }
}

struct ShareSheetView: View {
    let session: WorkoutSession
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var sharingService: SocialSharingService
    @State private var caption = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Preview
                if let workout = session.workout {
                    WorkoutShareCard(
                        workoutName: workout.name,
                        duration: formatDuration(session.totalDuration ?? 0),
                        exerciseCount: workout.exercises?.count ?? 0,
                        setsCompleted: session.completedSets?.count ?? 0,
                        totalVolume: formatVolume(session),
                        date: session.completedAt ?? session.startedAt
                    )
                    .scaleEffect(0.6)
                    .frame(height: 300)
                }

                // Caption
                TextField("Add a caption...", text: $caption, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...5)
                    .padding(.horizontal)

                // Share buttons
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(SharePlatform.allCases, id: \.self) { platform in
                        Button {
                            shareToplatform(platform)
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: platform.icon)
                                    .font(.title2)
                                Text(platform.displayName)
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .foregroundStyle(.primary)
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Share Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func shareToplatform(_ platform: SharePlatform) {
        _ = sharingService.shareWorkout(session: session, platform: platform, caption: caption)
        sharingService.presentShareSheet(for: session)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return "\(minutes):\(String(format: "%02d", secs))"
    }

    private func formatVolume(_ session: WorkoutSession) -> String {
        let volume = session.completedSets?.reduce(0.0) { $0 + ($1.weight * Double($1.reps)) } ?? 0
        if volume >= 1000 {
            return String(format: "%.1fK lbs", volume / 1000)
        }
        return String(format: "%.0f lbs", volume)
    }
}

#Preview {
    WorkoutShareCard(
        workoutName: "Push Day",
        duration: "45:32",
        exerciseCount: 5,
        setsCompleted: 15,
        totalVolume: "12.5K lbs",
        date: Date()
    )
}
