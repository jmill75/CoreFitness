import WidgetKit
import SwiftUI

// MARK: - Complication Entry
struct WorkoutComplicationEntry: TimelineEntry {
    let date: Date
}

// MARK: - Complication Provider
struct WorkoutComplicationProvider: TimelineProvider {

    func placeholder(in context: Context) -> WorkoutComplicationEntry {
        WorkoutComplicationEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (WorkoutComplicationEntry) -> Void) {
        completion(WorkoutComplicationEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WorkoutComplicationEntry>) -> Void) {
        let entry = WorkoutComplicationEntry(date: Date())
        // Refresh every hour
        let refreshDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
}

// MARK: - Complication Views

struct WorkoutComplicationView: View {
    let entry: WorkoutComplicationEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularComplicationView()
        case .accessoryRectangular:
            RectangularComplicationView()
        case .accessoryCorner:
            CornerComplicationView()
        case .accessoryInline:
            InlineComplicationView()
        default:
            CircularComplicationView()
        }
    }
}

// MARK: - Circular Complication
struct CircularComplicationView: View {
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Image(systemName: "dumbbell.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)
                Text("TRAIN")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .widgetURL(URL(string: "corefitness://workout"))
    }
}

// MARK: - Rectangular Complication
struct RectangularComplicationView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "dumbbell.fill")
                        .foregroundStyle(.orange)
                    Text("CoreFitness")
                        .fontWeight(.semibold)
                }
                .font(.caption)

                Text("Tap to open workout tracker")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .widgetURL(URL(string: "corefitness://workout"))
    }
}

// MARK: - Corner Complication
struct CornerComplicationView: View {
    var body: some View {
        Image(systemName: "dumbbell.fill")
            .foregroundStyle(.orange)
            .widgetLabel {
                Text("CoreFitness")
            }
    }
}

// MARK: - Inline Complication
struct InlineComplicationView: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "dumbbell.fill")
            Text("CoreFitness")
        }
    }
}

// MARK: - Widget Definition
struct WorkoutComplication: Widget {
    let kind: String = "WorkoutComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WorkoutComplicationProvider()) { entry in
            WorkoutComplicationView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("CoreFitness")
        .description("Quick launch workout tracker")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryCorner,
            .accessoryInline
        ])
    }
}

#Preview(as: .accessoryCircular) {
    WorkoutComplication()
} timeline: {
    WorkoutComplicationEntry(date: Date())
}
