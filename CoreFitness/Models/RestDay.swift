import SwiftUI
import SwiftData

// MARK: - Rest Day Reason
enum RestDayReason: String, CaseIterable, Codable {
    case recovery = "Recovery"
    case sick = "Sick"
    case travel = "Travel"
    case busy = "Busy"
    case injury = "Injury"
    case other = "Other"

    var icon: String {
        switch self {
        case .recovery: return "bed.double.fill"
        case .sick: return "facemask.fill"
        case .travel: return "airplane"
        case .busy: return "briefcase.fill"
        case .injury: return "bandage.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .recovery: return .accentBlue
        case .sick: return .accentRed
        case .travel: return .accentOrange
        case .busy: return .purple
        case .injury: return .accentRed
        case .other: return .secondary
        }
    }
}

// MARK: - Rest Day Model
@Model
final class RestDay {
    var id: UUID = UUID()
    var date: Date = Date()
    var reasonRaw: String = RestDayReason.recovery.rawValue
    var notes: String?
    var createdAt: Date = Date()

    // MARK: - Computed Properties

    var reason: RestDayReason {
        get { RestDayReason(rawValue: reasonRaw) ?? .other }
        set { reasonRaw = newValue.rawValue }
    }

    /// Normalized date (start of day) for comparison
    var normalizedDate: Date {
        Calendar.current.startOfDay(for: date)
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        reason: RestDayReason = .recovery,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.reasonRaw = reason.rawValue
        self.notes = notes
        self.createdAt = createdAt
    }

    // MARK: - Helper Methods

    /// Check if this rest day is for a specific date
    func isForDate(_ checkDate: Date) -> Bool {
        Calendar.current.isDate(normalizedDate, inSameDayAs: checkDate)
    }

    /// Format date for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    /// Relative time description
    var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
