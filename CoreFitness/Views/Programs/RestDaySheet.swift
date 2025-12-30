import SwiftUI
import SwiftData

// MARK: - Rest Day Sheet
struct RestDaySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager

    @State private var selectedDate = Date()
    @State private var selectedReason: RestDayReason = .recovery
    @State private var notes: String = ""
    @State private var showDatePicker = false

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header illustration
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.accentBlue.opacity(0.15))
                                .frame(width: 80, height: 80)

                            Image(systemName: "bed.double.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(Color.accentBlue)
                        }

                        Text("Mark Rest Day")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Rest is essential for muscle recovery and growth")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)

                    // Date Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date")
                            .font(.headline)
                            .padding(.horizontal)

                        Button {
                            showDatePicker.toggle()
                            themeManager.lightImpact()
                        } label: {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundStyle(Color.accentBlue)

                                Text(formattedDate)
                                    .foregroundStyle(.primary)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)

                        if showDatePicker {
                            DatePicker(
                                "Select Date",
                                selection: $selectedDate,
                                in: ...Date(),
                                displayedComponents: .date
                            )
                            .datePickerStyle(.graphical)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }

                    // Reason Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Reason")
                            .font(.headline)
                            .padding(.horizontal)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(RestDayReason.allCases, id: \.self) { reason in
                                ReasonButton(
                                    reason: reason,
                                    isSelected: selectedReason == reason,
                                    action: {
                                        selectedReason = reason
                                        themeManager.lightImpact()
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Notes (Optional)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes (Optional)")
                            .font(.headline)
                            .padding(.horizontal)

                        TextField("How are you feeling?", text: $notes, axis: .vertical)
                            .lineLimit(3...5)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                    }

                    Spacer(minLength: 40)

                    // Save Button
                    Button {
                        saveRestDay()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Mark as Rest Day")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Rest Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .animation(.spring(response: 0.3), value: showDatePicker)
        }
    }

    // MARK: - Helper Methods

    private var formattedDate: String {
        if calendar.isDateInToday(selectedDate) {
            return "Today"
        } else if calendar.isDateInYesterday(selectedDate) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            return formatter.string(from: selectedDate)
        }
    }

    private func saveRestDay() {
        let restDay = RestDay(
            date: selectedDate,
            reason: selectedReason,
            notes: notes.isEmpty ? nil : notes
        )

        modelContext.insert(restDay)

        do {
            try modelContext.save()
            themeManager.mediumImpact()
            dismiss()
        } catch {
            print("Failed to save rest day: \(error)")
        }
    }
}

// MARK: - Reason Button
struct ReasonButton: View {
    let reason: RestDayReason
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? reason.color.opacity(0.2) : Color(.tertiarySystemGroupedBackground))
                        .frame(width: 48, height: 48)

                    Image(systemName: reason.icon)
                        .font(.title3)
                        .foregroundStyle(isSelected ? reason.color : .secondary)
                }

                Text(reason.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? reason.color : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Quick Rest Day Button
/// A compact button for marking today as a rest day from other views
struct QuickRestDayButton: View {
    @State private var showRestDaySheet = false

    var body: some View {
        Button {
            showRestDaySheet = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "bed.double.fill")
                    .font(.caption)
                Text("Rest Day")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(Color.accentBlue)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.accentBlue.opacity(0.15))
            .clipShape(Capsule())
        }
        .sheet(isPresented: $showRestDaySheet) {
            RestDaySheet()
        }
    }
}

#Preview {
    RestDaySheet()
        .environmentObject(ThemeManager())
}
