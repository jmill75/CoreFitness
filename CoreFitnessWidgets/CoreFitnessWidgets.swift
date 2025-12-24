//
//  CoreFitnessWidgets.swift
//  CoreFitnessWidgets
//
//  Created by Jeff Miller on 12/23/25.
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Shared Data (App Group)
struct WidgetData {
    static let appGroupId = "group.com.corefitness.shared"

    static var waterIntakeOz: Double {
        get {
            UserDefaults(suiteName: appGroupId)?.double(forKey: "waterIntakeOz") ?? 0
        }
        set {
            UserDefaults(suiteName: appGroupId)?.set(newValue, forKey: "waterIntakeOz")
        }
    }

    static var waterGoalOz: Double {
        get {
            UserDefaults(suiteName: appGroupId)?.double(forKey: "waterGoalOz") ?? 64
        }
        set {
            UserDefaults(suiteName: appGroupId)?.set(newValue, forKey: "waterGoalOz")
        }
    }

    static var todayWorkoutName: String {
        UserDefaults(suiteName: appGroupId)?.string(forKey: "todayWorkoutName") ?? "Full Body Workout"
    }

    static var todayWorkoutDuration: Int {
        UserDefaults(suiteName: appGroupId)?.integer(forKey: "todayWorkoutDuration") ?? 45
    }

    static var todayWorkoutExercises: Int {
        UserDefaults(suiteName: appGroupId)?.integer(forKey: "todayWorkoutExercises") ?? 8
    }

    static var steps: Int {
        UserDefaults(suiteName: appGroupId)?.integer(forKey: "todaySteps") ?? 0
    }

    static var activeCalories: Int {
        UserDefaults(suiteName: appGroupId)?.integer(forKey: "activeCalories") ?? 0
    }

    static var sleepHours: Double {
        UserDefaults(suiteName: appGroupId)?.double(forKey: "sleepHours") ?? 0
    }

    static var recoveryScore: Int {
        UserDefaults(suiteName: appGroupId)?.integer(forKey: "recoveryScore") ?? 75
    }
}

// MARK: - App Intent for Water
struct AddWaterIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Water"
    static var description = IntentDescription("Add water to your daily intake")

    @Parameter(title: "Amount (oz)")
    var amount: Int

    init() {
        self.amount = 8
    }

    init(amount: Int) {
        self.amount = amount
    }

    func perform() async throws -> some IntentResult {
        WidgetData.waterIntakeOz += Double(amount)
        return .result()
    }
}

// MARK: - Water Intake Widget
struct WaterIntakeProvider: TimelineProvider {
    func placeholder(in context: Context) -> WaterIntakeEntry {
        WaterIntakeEntry(date: Date(), currentOz: 40, goalOz: 64)
    }

    func getSnapshot(in context: Context, completion: @escaping (WaterIntakeEntry) -> ()) {
        let entry = WaterIntakeEntry(
            date: Date(),
            currentOz: WidgetData.waterIntakeOz,
            goalOz: WidgetData.waterGoalOz
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WaterIntakeEntry>) -> ()) {
        let entry = WaterIntakeEntry(
            date: Date(),
            currentOz: WidgetData.waterIntakeOz,
            goalOz: WidgetData.waterGoalOz
        )
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * 15)))
        completion(timeline)
    }
}

struct WaterIntakeEntry: TimelineEntry {
    let date: Date
    let currentOz: Double
    let goalOz: Double

    var progress: Double {
        min(currentOz / goalOz, 1.0)
    }

    var percentage: Int {
        Int(progress * 100)
    }
}

struct WaterIntakeWidgetView: View {
    var entry: WaterIntakeProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    var smallView: some View {
        VStack(spacing: 8) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.cyan.opacity(0.2), lineWidth: 8)
                    .frame(width: 70, height: 70)

                Circle()
                    .trim(from: 0, to: entry.progress)
                    .stroke(
                        LinearGradient(
                            colors: [.cyan, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.cyan)
                    Text("\(entry.percentage)%")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
            }

            Text("\(Int(entry.currentOz)) / \(Int(entry.goalOz)) oz")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Quick add button
            Button(intent: AddWaterIntent(amount: 8)) {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                        .font(.caption)
                    Text("8oz")
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.cyan)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }

    var mediumView: some View {
        HStack(spacing: 16) {
            // Left side - progress
            ZStack {
                Circle()
                    .stroke(Color.cyan.opacity(0.2), lineWidth: 10)
                    .frame(width: 90, height: 90)

                Circle()
                    .trim(from: 0, to: entry.progress)
                    .stroke(
                        LinearGradient(
                            colors: [.cyan, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 90, height: 90)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(Int(entry.currentOz))")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    Text("oz")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Water Intake")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("\(entry.percentage)% of daily goal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Quick add buttons
                HStack(spacing: 8) {
                    ForEach([8, 16, 24], id: \.self) { oz in
                        Button(intent: AddWaterIntent(amount: oz)) {
                            Text("+\(oz)oz")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.cyan)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

struct WaterIntakeWidget: Widget {
    let kind: String = "WaterIntakeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WaterIntakeProvider()) { entry in
            WaterIntakeWidgetView(entry: entry)
        }
        .configurationDisplayName("Water Intake")
        .description("Track your daily water intake and add water quickly.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Today's Workout Widget
struct WorkoutProvider: TimelineProvider {
    func placeholder(in context: Context) -> WorkoutEntry {
        WorkoutEntry(
            date: Date(),
            workoutName: "Full Body Workout",
            duration: 45,
            exerciseCount: 8
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WorkoutEntry) -> ()) {
        let entry = WorkoutEntry(
            date: Date(),
            workoutName: WidgetData.todayWorkoutName,
            duration: WidgetData.todayWorkoutDuration,
            exerciseCount: WidgetData.todayWorkoutExercises
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WorkoutEntry>) -> ()) {
        let entry = WorkoutEntry(
            date: Date(),
            workoutName: WidgetData.todayWorkoutName,
            duration: WidgetData.todayWorkoutDuration,
            exerciseCount: WidgetData.todayWorkoutExercises
        )
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * 60)))
        completion(timeline)
    }
}

struct WorkoutEntry: TimelineEntry {
    let date: Date
    let workoutName: String
    let duration: Int
    let exerciseCount: Int
}

struct WorkoutWidgetView: View {
    var entry: WorkoutProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title2)
                    .foregroundStyle(.orange)
                Spacer()
                Text("TODAY")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.orange.opacity(0.15))
                    .clipShape(Capsule())
            }

            Spacer()

            Text(entry.workoutName)
                .font(.subheadline)
                .fontWeight(.bold)
                .lineLimit(2)

            HStack(spacing: 8) {
                Label("\(entry.duration)m", systemImage: "clock")
                Label("\(entry.exerciseCount)", systemImage: "list.bullet")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)

            Link(destination: URL(string: "corefitness://workout/start")!) {
                HStack {
                    Image(systemName: "play.fill")
                        .font(.caption)
                    Text("Start")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(.orange)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color.orange.opacity(0.1), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var mediumView: some View {
        HStack(spacing: 16) {
            // Workout icon
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 70, height: 70)

                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Today's Workout")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("READY")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.green.opacity(0.15))
                        .clipShape(Capsule())
                }

                Text(entry.workoutName)
                    .font(.headline)
                    .fontWeight(.bold)

                HStack(spacing: 16) {
                    Label("\(entry.duration) min", systemImage: "clock.fill")
                    Label("\(entry.exerciseCount) exercises", systemImage: "list.bullet")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Link(destination: URL(string: "corefitness://workout/start")!) {
                VStack {
                    Image(systemName: "play.fill")
                        .font(.title2)
                    Text("Start")
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(width: 60, height: 70)
                .background(.orange)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

struct TodayWorkoutWidget: Widget {
    let kind: String = "TodayWorkoutWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WorkoutProvider()) { entry in
            WorkoutWidgetView(entry: entry)
        }
        .configurationDisplayName("Today's Workout")
        .description("Quick access to start your scheduled workout.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Health Stats Widget
struct HealthStatsProvider: TimelineProvider {
    func placeholder(in context: Context) -> HealthStatsEntry {
        HealthStatsEntry(
            date: Date(),
            steps: 8500,
            activeCalories: 450,
            sleepHours: 7.5,
            recoveryScore: 82
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (HealthStatsEntry) -> ()) {
        let entry = HealthStatsEntry(
            date: Date(),
            steps: WidgetData.steps > 0 ? WidgetData.steps : 8500,
            activeCalories: WidgetData.activeCalories > 0 ? WidgetData.activeCalories : 450,
            sleepHours: WidgetData.sleepHours > 0 ? WidgetData.sleepHours : 7.5,
            recoveryScore: WidgetData.recoveryScore
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HealthStatsEntry>) -> ()) {
        let entry = HealthStatsEntry(
            date: Date(),
            steps: WidgetData.steps > 0 ? WidgetData.steps : 8500,
            activeCalories: WidgetData.activeCalories > 0 ? WidgetData.activeCalories : 450,
            sleepHours: WidgetData.sleepHours > 0 ? WidgetData.sleepHours : 7.5,
            recoveryScore: WidgetData.recoveryScore
        )
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * 30)))
        completion(timeline)
    }
}

struct HealthStatsEntry: TimelineEntry {
    let date: Date
    let steps: Int
    let activeCalories: Int
    let sleepHours: Double
    let recoveryScore: Int
}

struct HealthStatsWidgetView: View {
    var entry: HealthStatsProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
                Text("Health")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
            }

            Spacer()

            // Recovery score
            HStack {
                Text("\(entry.recoveryScore)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreColor)
                Text("Recovery")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Steps
            HStack(spacing: 4) {
                Image(systemName: "figure.walk")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Text(formatNumber(entry.steps))
                    .font(.caption)
                    .fontWeight(.medium)
                Text("steps")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }

    var mediumView: some View {
        HStack(spacing: 20) {
            // Recovery score
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .stroke(scoreColor.opacity(0.2), lineWidth: 8)
                        .frame(width: 70, height: 70)

                    Circle()
                        .trim(from: 0, to: Double(entry.recoveryScore) / 100.0)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))

                    Text("\(entry.recoveryScore)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }
                Text("Recovery")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // Stats grid
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 20) {
                    HealthStatItem(
                        icon: "figure.walk",
                        value: formatNumber(entry.steps),
                        label: "Steps",
                        color: .orange
                    )
                    HealthStatItem(
                        icon: "flame.fill",
                        value: "\(entry.activeCalories)",
                        label: "Calories",
                        color: .red
                    )
                }

                HStack(spacing: 20) {
                    HealthStatItem(
                        icon: "moon.fill",
                        value: String(format: "%.1f", entry.sleepHours),
                        label: "Sleep hrs",
                        color: .indigo
                    )
                    HealthStatItem(
                        icon: "heart.fill",
                        value: "\(entry.recoveryScore)%",
                        label: "Ready",
                        color: scoreColor
                    )
                }
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }

    private var scoreColor: Color {
        switch entry.recoveryScore {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .orange
        default: return .red
        }
    }

    private func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            return String(format: "%.1fk", Double(number) / 1000.0)
        }
        return "\(number)"
    }
}

struct HealthStatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text(label)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 70, alignment: .leading)
    }
}

struct HealthStatsWidget: Widget {
    let kind: String = "HealthStatsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HealthStatsProvider()) { entry in
            HealthStatsWidgetView(entry: entry)
        }
        .configurationDisplayName("Health Stats")
        .description("View your recovery score, steps, and health metrics at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Legacy Widget (for backward compatibility)
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), emoji: "💪")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), emoji: "💪")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, emoji: "💪")
            entries.append(entry)
        }
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let emoji: String
}

struct CoreFitnessWidgetsEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text("CoreFitness")
                .font(.headline)
            Text(entry.emoji)
                .font(.largeTitle)
        }
    }
}

struct CoreFitnessWidgets: Widget {
    let kind: String = "CoreFitnessWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(watchOS 10.0, *) {
                CoreFitnessWidgetsEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                CoreFitnessWidgetsEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("CoreFitness")
        .description("Quick access to CoreFitness.")
    }
}

#Preview("Water Small", as: .systemSmall) {
    WaterIntakeWidget()
} timeline: {
    WaterIntakeEntry(date: .now, currentOz: 40, goalOz: 64)
}

#Preview("Water Medium", as: .systemMedium) {
    WaterIntakeWidget()
} timeline: {
    WaterIntakeEntry(date: .now, currentOz: 40, goalOz: 64)
}

#Preview("Workout Small", as: .systemSmall) {
    TodayWorkoutWidget()
} timeline: {
    WorkoutEntry(date: .now, workoutName: "Full Body Workout", duration: 45, exerciseCount: 8)
}

#Preview("Health Medium", as: .systemMedium) {
    HealthStatsWidget()
} timeline: {
    HealthStatsEntry(date: .now, steps: 8500, activeCalories: 450, sleepHours: 7.5, recoveryScore: 82)
}
