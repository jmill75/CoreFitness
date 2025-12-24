import SwiftUI

struct CountdownView: View {
    let count: Int

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    private var displayText: String {
        count > 0 ? "\(count)" : "GO!"
    }

    private var displayColor: Color {
        switch count {
        case 3: return .accentRed
        case 2: return .accentOrange
        case 1: return .accentYellow
        default: return .accentGreen
        }
    }

    var body: some View {
        ZStack {
            // Pulsing background circle
            Circle()
                .fill(displayColor.opacity(0.2))
                .frame(width: 300, height: 300)
                .scaleEffect(scale * 1.2)
                .blur(radius: 40)

            // Main number
            Text(displayText)
                .font(.system(size: 180, weight: .bold, design: .rounded))
                .foregroundStyle(displayColor)
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .onChange(of: count) { _, _ in
            // Reset and animate
            scale = 0.5
            opacity = 0
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

#Preview {
    CountdownView(count: 3)
}
