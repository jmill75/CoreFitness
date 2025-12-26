import SwiftUI

// MARK: - Section Card
/// A reusable card component for displaying sections with optional title and subtitle
struct SectionCard<Content: View>: View {
    @EnvironmentObject var themeManager: ThemeManager

    let title: String?
    let subtitle: String?
    let icon: String?
    let iconColor: Color
    let showChevron: Bool
    let action: (() -> Void)?
    @ViewBuilder let content: () -> Content

    init(
        title: String? = nil,
        subtitle: String? = nil,
        icon: String? = nil,
        iconColor: Color = .accentColor,
        showChevron: Bool = false,
        action: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self.showChevron = showChevron
        self.action = action
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            if title != nil || subtitle != nil {
                cardHeader
            }

            // Content
            content()
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture {
            if let action = action {
                themeManager.lightImpact()
                action()
            }
        }
    }

    @ViewBuilder
    private var cardHeader: some View {
        HStack(spacing: 12) {
            // Icon
            if let icon = icon {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(iconColor)
                    .frame(width: 28)
            }

            // Title & Subtitle
            VStack(alignment: .leading, spacing: 2) {
                if let title = title {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Chevron
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Section Card with Header Only (no content)
struct SectionCardHeader: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    let subtitle: String?
    let icon: String?
    let iconColor: Color
    let trailing: AnyView?
    let action: (() -> Void)?

    init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        iconColor: Color = .accentColor,
        trailing: AnyView? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self.trailing = trailing
        self.action = action
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            if let icon = icon {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(iconColor)
                    .frame(width: 28)
            }

            // Title & Subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Trailing content
            if let trailing = trailing {
                trailing
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture {
            if let action = action {
                themeManager.lightImpact()
                action()
            }
        }
    }
}

// MARK: - Simple Card (just content, no header)
struct SimpleCard<Content: View>: View {

    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Card Row (for list-like items inside cards)
struct CardRow: View {

    let title: String
    let value: String?
    let icon: String?
    let iconColor: Color
    let showDivider: Bool

    init(
        title: String,
        value: String? = nil,
        icon: String? = nil,
        iconColor: Color = .secondary,
        showDivider: Bool = true
    ) {
        self.title = title
        self.value = value
        self.icon = icon
        self.iconColor = iconColor
        self.showDivider = showDivider
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundStyle(iconColor)
                        .frame(width: 24)
                }

                Text(title)
                    .font(.subheadline)

                Spacer()

                if let value = value {
                    Text(value)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)

            if showDivider {
                Divider()
            }
        }
    }
}

// MARK: - Stat Card (for displaying a single stat)
struct StatCard: View {

    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let trend: TrendDirection?

    enum TrendDirection {
        case up, down, neutral

        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "minus"
            }
        }

        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .neutral: return .secondary
            }
        }
    }

    init(
        title: String,
        value: String,
        unit: String = "",
        icon: String,
        color: Color = .accentColor,
        trend: TrendDirection? = nil
    ) {
        self.title = title
        self.value = value
        self.unit = unit
        self.icon = icon
        self.color = color
        self.trend = trend
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
                if let trend = trend {
                    Image(systemName: trend.icon)
                        .font(.caption)
                        .foregroundStyle(trend.color)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            // Icon
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            // Text
            VStack(spacing: 6) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Action Button
            if let actionTitle = actionTitle, let action = action {
                Button {
                    themeManager.mediumImpact()
                    action()
                } label: {
                    Text(actionTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.brandPrimary)
                        .clipShape(Capsule())
                }
                .padding(.top, 8)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Inline Empty State (for cards/sections)
struct InlineEmptyState: View {
    let icon: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        icon: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let actionTitle = actionTitle, let action = action {
                Button {
                    action()
                } label: {
                    Text(actionTitle)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.brandPrimary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

// MARK: - Skeleton Loading View
struct SkeletonView: View {
    let width: CGFloat?
    let height: CGFloat

    @State private var isAnimating = false

    init(width: CGFloat? = nil, height: CGFloat = 20) {
        self.width = width
        self.height = height
    }

    var body: some View {
        RoundedRectangle(cornerRadius: height / 3)
            .fill(Color(.systemGray5))
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: height / 3)
                    .fill(
                        LinearGradient(
                            colors: [.clear, Color(.systemGray4), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? 200 : -200)
            )
            .clipShape(RoundedRectangle(cornerRadius: height / 3))
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Loading Card Skeleton
struct LoadingCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SkeletonView(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 6) {
                    SkeletonView(width: 120, height: 16)
                    SkeletonView(width: 80, height: 12)
                }
                Spacer()
            }

            SkeletonView(height: 14)
            SkeletonView(width: 200, height: 14)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Loading Stats Skeleton
struct LoadingStatsSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { _ in
                VStack(spacing: 8) {
                    SkeletonView(width: 32, height: 32)
                    SkeletonView(width: 40, height: 24)
                    SkeletonView(width: 50, height: 12)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}

// MARK: - Previews
#Preview("Section Card") {
    VStack(spacing: 16) {
        SectionCard(
            title: "Today's Workout",
            subtitle: "Upper Body Strength",
            icon: "figure.strengthtraining.traditional",
            iconColor: .blue
        ) {
            Text("45 min • 8 exercises")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }

        SectionCard(title: "Quick Stats") {
            HStack {
                Text("Sleep: 7h 32m")
                Spacer()
                Text("HRV: 45ms")
            }
            .font(.subheadline)
        }

        StatCard(
            title: "Heart Rate",
            value: "72",
            unit: "bpm",
            icon: "heart.fill",
            color: .red,
            trend: .down
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Empty States") {
    VStack(spacing: 20) {
        EmptyStateView(
            icon: "figure.run",
            title: "No Workouts Yet",
            message: "Start your first workout to see your progress here.",
            actionTitle: "Start Workout"
        ) {
            print("Start workout tapped")
        }

        InlineEmptyState(
            icon: "trophy",
            message: "Complete workouts to earn badges",
            actionTitle: "View All Badges"
        ) {
            print("View badges tapped")
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Loading Skeletons") {
    VStack(spacing: 16) {
        LoadingStatsSkeleton()
        LoadingCardSkeleton()
        LoadingCardSkeleton()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

// MARK: - View Header Components

/// Unified header component for main views
/// Provides consistent styling across Home, Programs, Health, Progress, and Settings views
struct ViewHeader<MenuContent: View>: View {
    let title: String
    let isLoading: Bool
    @ViewBuilder let menuContent: () -> MenuContent

    init(
        _ title: String,
        isLoading: Bool = false,
        @ViewBuilder menuContent: @escaping () -> MenuContent
    ) {
        self.title = title
        self.isLoading = isLoading
        self.menuContent = menuContent
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)

            Spacer()

            // Loading indicator
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .padding(.trailing, 8)
            }

            // Quick Add Menu Button
            Menu {
                menuContent()
            } label: {
                Image(systemName: "plus")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(Color.accentBlue)
                    .clipShape(Circle())
                    .shadow(color: Color.accentBlue.opacity(0.4), radius: 10, y: 5)
            }
            .accessibilityLabel("Quick actions menu")
            .accessibilityHint("Double tap to open menu options")
        }
    }
}

/// ViewHeader without menu button - just title and optional loading
struct ViewHeaderSimple: View {
    let title: String
    let isLoading: Bool

    init(_ title: String, isLoading: Bool = false) {
        self.title = title
        self.isLoading = isLoading
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)

            Spacer()

            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
    }
}

/// ViewHeader with custom trailing content
struct ViewHeaderCustom<TrailingContent: View>: View {
    let title: String
    @ViewBuilder let trailingContent: () -> TrailingContent

    init(
        _ title: String,
        @ViewBuilder trailingContent: @escaping () -> TrailingContent
    ) {
        self.title = title
        self.trailingContent = trailingContent
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)

            Spacer()

            trailingContent()
        }
    }
}
