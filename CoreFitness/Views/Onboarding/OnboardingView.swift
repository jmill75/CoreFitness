import SwiftUI
import AuthenticationServices

struct OnboardingView: View {

    // MARK: - Environment
    @EnvironmentObject var authManager: AuthManager

    // MARK: - State
    @State private var currentPage = 0
    @State private var showSignIn = false
    @State private var currentNonce: String?

    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                colors: [.blue.opacity(0.3), .purple.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Page Content
                TabView(selection: $currentPage) {
                    WelcomePage()
                        .tag(0)

                    FeaturesPage()
                        .tag(1)

                    GetStartedPage(showSignIn: $showSignIn)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page Indicator
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.primary : Color.secondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(currentPage == index ? 1.2 : 1)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showSignIn) {
            SignInSheet(currentNonce: $currentNonce)
                .environmentObject(authManager)
        }
    }
}

// MARK: - Welcome Page
struct WelcomePage: View {

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // App Icon Placeholder
            RoundedRectangle(cornerRadius: 30)
                .fill(.ultraThinMaterial)
                .frame(width: 120, height: 120)
                .overlay {
                    Image(systemName: "figure.run")
                        .font(.system(size: 50))
                        .foregroundStyle(.blue)
                }

            VStack(spacing: 12) {
                Text("Welcome to")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                Text("CoreFitness")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }

            Text("Your complete fitness companion.\nTrack workouts, monitor health, achieve goals.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
        .padding()
    }
}

// MARK: - Features Page
struct FeaturesPage: View {

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("Everything You Need")
                .font(.title)
                .fontWeight(.bold)

            VStack(spacing: 20) {
                FeatureRow(
                    icon: "sparkles",
                    title: "AI-Powered Workouts",
                    description: "Personalized programs created just for you"
                )

                FeatureRow(
                    icon: "heart.fill",
                    title: "Health Tracking",
                    description: "Monitor HRV, sleep, recovery & more"
                )

                FeatureRow(
                    icon: "applewatch",
                    title: "Apple Watch",
                    description: "Track workouts right from your wrist"
                )

                FeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Overall Score",
                    description: "Daily readiness score based on your data"
                )
            }
            .padding(.horizontal, 24)

            Spacer()
            Spacer()
        }
        .padding()
    }
}

private struct FeatureRow: View {

    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Get Started Page
struct GetStartedPage: View {

    @Binding var showSignIn: Bool

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)

                Text("Ready to Start?")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Sign in to begin your fitness journey and unlock all features.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()

            VStack(spacing: 16) {
                Button {
                    showSignIn = true
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                } label: {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Get Started")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Text("Free to start. Upgrade anytime.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .padding()
    }
}

// MARK: - Sign In Sheet
struct SignInSheet: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    @Binding var currentNonce: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)

                    Text("Sign In")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Choose how you'd like to sign in")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 16) {
                    // Sign in with Apple
                    SignInWithAppleButton(.signIn) { request in
                        let nonce = AuthManager.randomNonceString()
                        currentNonce = nonce
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = AuthManager.sha256(nonce)
                    } onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                               let nonce = currentNonce {
                                Task {
                                    await authManager.signInWithApple(credential: appleIDCredential, nonce: nonce)
                                    if authManager.isAuthenticated {
                                        dismiss()
                                    }
                                }
                            }
                        case .failure(let error):
                            print("Sign in with Apple failed: \(error.localizedDescription)")
                        }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)

                    // Sign in with Google
                    Button {
                        Task {
                            await authManager.signInWithGoogle()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "g.circle.fill")
                            Text("Sign in with Google")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.regularMaterial)
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                // Terms
                VStack(spacing: 8) {
                    Text("By signing in, you agree to our")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 4) {
                        Button("Terms of Service") { }
                            .font(.caption)
                        Text("and")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button("Privacy Policy") { }
                            .font(.caption)
                    }
                }
                .padding(.bottom, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    DismissButton { dismiss() }
                }
            }
            .overlay {
                if authManager.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.ultraThinMaterial)
                }
            }
            .alert("Error", isPresented: .constant(authManager.errorMessage != nil)) {
                Button("OK") {
                    authManager.errorMessage = nil
                }
            } message: {
                Text(authManager.errorMessage ?? "")
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AuthManager())
}
