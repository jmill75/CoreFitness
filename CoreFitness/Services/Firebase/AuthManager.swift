import SwiftUI
import AuthenticationServices
import CryptoKit

// MARK: - User Model
struct AppUser {
    let id: String
    let email: String?
    let displayName: String?
    let photoURL: URL?
    let subscriptionTier: SubscriptionTier
    let aiGenerationsRemaining: Int
    let aiGenerationResetDate: Date?

    init(
        id: String,
        email: String? = nil,
        displayName: String? = nil,
        photoURL: URL? = nil,
        subscriptionTier: SubscriptionTier = .free,
        aiGenerationsRemaining: Int = 1,
        aiGenerationResetDate: Date? = nil
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.subscriptionTier = subscriptionTier
        self.aiGenerationsRemaining = aiGenerationsRemaining
        self.aiGenerationResetDate = aiGenerationResetDate
    }
}

// MARK: - Subscription Tier
enum SubscriptionTier: String, Codable {
    case free = "free"
    case basic = "basic"
    case premium = "premium"

    var aiGenerationsPerWeek: Int {
        switch self {
        case .free: return 1
        case .basic: return 3
        case .premium: return 21 // 3 per day
        }
    }

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .basic: return "Basic"
        case .premium: return "Premium"
        }
    }
}

// MARK: - Auth Manager
@MainActor
class AuthManager: ObservableObject {

    // ============================================
    // MOCK MODE - Set to false when Firebase is configured
    // ============================================
    static let mockMode = true

    // MARK: - Published Properties
    @Published var currentUser: AppUser?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Init
    init() {
        if AuthManager.mockMode {
            // Automatically sign in with mock user
            setupMockUser()
        }
    }

    // MARK: - Mock User Setup
    private func setupMockUser() {
        currentUser = AppUser(
            id: "mock-user-123",
            email: "demo@corefitness.app",
            displayName: "Demo User",
            photoURL: nil,
            subscriptionTier: .premium,
            aiGenerationsRemaining: 10,
            aiGenerationResetDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())
        )
        isAuthenticated = true
    }

    // MARK: - Sign In with Apple
    func signInWithApple(credential: ASAuthorizationAppleIDCredential, nonce: String) async {
        if AuthManager.mockMode {
            setupMockUser()
            return
        }

        // Real Firebase auth would go here
        isLoading = true
        errorMessage = "Firebase not configured. Enable mock mode or add Firebase."
        isLoading = false
    }

    // MARK: - Sign In with Google
    func signInWithGoogle() async {
        if AuthManager.mockMode {
            setupMockUser()
            return
        }

        // Real Firebase auth would go here
        isLoading = true
        errorMessage = "Google Sign-In coming soon"
        isLoading = false
    }

    // MARK: - Sign Out
    func signOut() {
        currentUser = nil
        isAuthenticated = false
    }

    // MARK: - Check AI Generation Limit
    func canGenerateAIWorkout() -> Bool {
        guard let user = currentUser else { return false }
        return user.aiGenerationsRemaining > 0
    }

    // MARK: - Use AI Generation
    func useAIGeneration() async {
        // TODO: Decrement AI generation count in Firestore
    }
}

// MARK: - Nonce Generation
extension AuthManager {

    static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }

        return String(nonce)
    }

    static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap { String(format: "%02x", $0) }.joined()
        return hashString
    }
}
