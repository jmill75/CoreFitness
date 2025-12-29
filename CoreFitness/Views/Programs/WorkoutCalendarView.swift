import SwiftUI
import SwiftData

// MARK: - Calendar View Mode
enum CalendarViewMode: String, CaseIterable {
    case month = "Month"
    case week = "Week"
}

// MARK: - Day Status
enum DayStatus {
    case completed      // Full workout completed
    case partial        // Paused/cancelled with progress
    case restDay        // User marked rest day
    case empty          // No activity
    case future         // Future date
}

// MARK: - Workout Calendar View
struct WorkoutCalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager

    @Query(sort: \WorkoutSession.startedAt, order: .reverse)
    private var allSessions: [WorkoutSession]

    @Query(sort: \RestDay.date, order: .reverse)
    private var restDays: [RestDay]

    @State private var viewMode: CalendarViewMode = .month
    @State private var currentDate = Date()
    @State private var selectedDate: Date?
    @State private var showDayDetail = false

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 0) {
            // Header with mode toggle and navigation
            calendarHeader
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

            Divider()
                .padding(.horizontal, 16)

            // Calendar grid
            Group {
                if viewMode == .month {
                    monthGridContent
                } else {
                    weekGridContent
                }
            }
            .padding(16)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showDayDetail) {
            if let date = selectedDate {
                DayDetailSheet(date: date, sessions: sessionsForDate(date), restDay: restDayForDate(date))
            }
        }
    }

    // MARK: - Header
    private var calendarHeader: some View {
        HStack {
            // View mode toggle
            Picker("View", selection: $viewMode) {
                ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 140)

            Spacer()

            // Month/Week navigation
            HStack(spacing: 16) {
                Button {
                    navigatePrevious()
                    themeManager.lightImpact()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }

                Text(headerTitle)
                    .font(.headline)
                    .frame(minWidth: 100)

                Button {
                    navigateNext()
                    themeManager.lightImpact()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
            }
        }
    }

    private var headerTitle: String {
        let formatter = DateFormatter()
        if viewMode == .month {
            formatter.dateFormat = "MMMM yyyy"
        } else {
            formatter.dateFormat = "MMM d"
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? currentDate
            let endFormatter = DateFormatter()
            endFormatter.dateFormat = "d, yyyy"
            return "\(formatter.string(from: startOfWeek)) - \(endFormatter.string(from: endOfWeek))"
        }
        return formatter.string(from: currentDate)
    }

    // MARK: - Month Grid Content
    private var monthGridContent: some View {
        VStack(spacing: 8) {
            // Day headers
            HStack(spacing: 0) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            let days = daysInMonth()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
                ForEach(Array(days.enumerated()), id: \.offset) { index, date in
                    if let date = date {
                        DayCell(
                            date: date,
                            status: statusForDate(date),
                            isToday: calendar.isDateInToday(date),
                            isSelected: selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
                        )
                        .onTapGesture {
                            selectedDate = date
                            showDayDetail = true
                            themeManager.lightImpact()
                        }
                    } else {
                        Color.clear
                            .frame(height: 44)
                    }
                }
            }
        }
    }

    // MARK: - Week Grid Content
    private var weekGridContent: some View {
        HStack(spacing: 4) {
            ForEach(daysInWeek(), id: \.self) { date in
                VStack(spacing: 6) {
                    Text(dayAbbreviation(for: date))
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    DayCell(
                        date: date,
                        status: statusForDate(date),
                        isToday: calendar.isDateInToday(date),
                        isSelected: selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false,
                        size: .regular
                    )
                    .onTapGesture {
                        selectedDate = date
                        showDayDetail = true
                        themeManager.lightImpact()
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Helper Methods

    private var startOfWeek: Date {
        calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate)) ?? currentDate
    }

    private func daysInMonth() -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: currentDate),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }

        // Pad to complete the last week
        while days.count % 7 != 0 {
            days.append(nil)
        }

        return days
    }

    private func daysInWeek() -> [Date] {
        (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startOfWeek)
        }
    }

    private func dayAbbreviation(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private func navigatePrevious() {
        if viewMode == .month {
            currentDate = calendar.date(byAdding: .month, value: -1, to: currentDate) ?? currentDate
        } else {
            currentDate = calendar.date(byAdding: .weekOfYear, value: -1, to: currentDate) ?? currentDate
        }
    }

    private func navigateNext() {
        if viewMode == .month {
            currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
        } else {
            currentDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate) ?? currentDate
        }
    }

    private func statusForDate(_ date: Date) -> DayStatus {
        // Future dates
        if date > Date() {
            return .future
        }

        // Check for rest day
        if restDays.contains(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
            return .restDay
        }

        // Check for workout sessions
        let sessionsForDay = allSessions.filter { session in
            calendar.isDate(session.startedAt, inSameDayAs: date)
        }

        if sessionsForDay.contains(where: { $0.status == .completed }) {
            return .completed
        }

        if sessionsForDay.contains(where: { $0.status == .paused || $0.status == .cancelled }) {
            return .partial
        }

        return .empty
    }

    private func sessionsForDate(_ date: Date) -> [WorkoutSession] {
        allSessions.filter { session in
            calendar.isDate(session.startedAt, inSameDayAs: date)
        }
    }

    private func restDayForDate(_ date: Date) -> RestDay? {
        restDays.first { calendar.isDate($0.date, inSameDayAs: date) }
    }
}

// MARK: - Day Cell
struct DayCell: View {
    let date: Date
    let status: DayStatus
    let isToday: Bool
    let isSelected: Bool
    var size: Size = .regular

    enum Size {
        case regular, large

        var dimension: CGFloat {
            switch self {
            case .regular: return 36
            case .large: return 48
            }
        }

        var font: Font {
            switch self {
            case .regular: return .subheadline
            case .large: return .headline
            }
        }
    }

    private let calendar = Calendar.current

    var body: some View {
        ZStack {
            // Background
            Circle()
                .fill(backgroundColor)
                .frame(width: size.dimension, height: size.dimension)

            // Status indicator or date
            Group {
                switch status {
                case .completed:
                    Image(systemName: "checkmark")
                        .font(.system(size: size == .large ? 16 : 12, weight: .bold))
                        .foregroundStyle(.white)
                case .partial:
                    Circle()
                        .trim(from: 0, to: 0.5)
                        .stroke(Color.accentOrange, lineWidth: 3)
                        .frame(width: size.dimension - 8, height: size.dimension - 8)
                        .rotationEffect(.degrees(-90))
                        .overlay {
                            Text("\(calendar.component(.day, from: date))")
                                .font(size.font)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                        }
                case .restDay:
                    Text("R")
                        .font(size.font)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.accentBlue)
                default:
                    Text("\(calendar.component(.day, from: date))")
                        .font(size.font)
                        .fontWeight(isToday ? .bold : .medium)
                        .foregroundStyle(textColor)
                }
            }

            // Today indicator ring
            if isToday && status != .completed {
                Circle()
                    .stroke(Color.brandPrimary, lineWidth: 2)
                    .frame(width: size.dimension + 4, height: size.dimension + 4)
            }
        }
        .frame(width: size.dimension + 8, height: size.dimension + 8)
    }

    private var backgroundColor: Color {
        switch status {
        case .completed:
            return .accentGreen
        case .restDay:
            return .accentBlue.opacity(0.15)
        case .future:
            return Color(.tertiarySystemGroupedBackground)
        default:
            return isSelected ? Color.brandPrimary.opacity(0.2) : Color(.tertiarySystemGroupedBackground)
        }
    }

    private var textColor: Color {
        switch status {
        case .future:
            return .secondary.opacity(0.5)
        case .empty:
            return isToday ? .brandPrimary : .primary
        default:
            return .primary
        }
    }
}

// MARK: - Day Detail Sheet
struct DayDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let date: Date
    let sessions: [WorkoutSession]
    let restDay: RestDay?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Date header
                    VStack(spacing: 4) {
                        Text(formattedDate)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(dayOfWeek)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top)

                    // Rest day info
                    if let restDay = restDay {
                        HStack {
                            Image(systemName: restDay.reason.icon)
                                .font(.title2)
                                .foregroundStyle(restDay.reason.color)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Rest Day")
                                    .font(.headline)
                                Text(restDay.reason.rawValue)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }

                    // Workout sessions
                    if !sessions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Workouts")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(sessions, id: \.id) { session in
                                SessionCard(session: session)
                            }
                        }
                    } else if restDay == nil {
                        // Empty state
                        VStack(spacing: 12) {
                            Image(systemName: "figure.walk")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)

                            Text("No workouts on this day")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 40)
                    }

                    Spacer(minLength: 40)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Day Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}

// MARK: - Session Card
struct SessionCard: View {
    let session: WorkoutSession

    var body: some View {
        HStack {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(session.workout?.name ?? "Workout")
                    .font(.headline)

                HStack(spacing: 12) {
                    if let duration = session.totalDuration, duration > 0 {
                        Label("\(duration / 60) min", systemImage: "clock")
                    }

                    if let sets = session.completedSets?.count, sets > 0 {
                        Label("\(sets) sets", systemImage: "checkmark.circle")
                    }

                    Text(statusText)
                        .foregroundStyle(statusColor)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: statusIcon)
                .font(.title3)
                .foregroundStyle(statusColor)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private var statusColor: Color {
        switch session.status {
        case .completed: return .accentGreen
        case .paused: return .accentOrange
        case .cancelled: return .secondary
        case .inProgress: return .accentBlue
        }
    }

    private var statusText: String {
        switch session.status {
        case .completed: return "Completed"
        case .paused: return "Paused"
        case .cancelled: return "Saved"
        case .inProgress: return "In Progress"
        }
    }

    private var statusIcon: String {
        switch session.status {
        case .completed: return "checkmark.circle.fill"
        case .paused: return "pause.circle.fill"
        case .cancelled: return "arrow.uturn.backward.circle"
        case .inProgress: return "play.circle.fill"
        }
    }
}

#Preview {
    WorkoutCalendarView()
        .environmentObject(ThemeManager())
        .padding()
}
