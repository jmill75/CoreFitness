import SwiftUI
import AuthenticationServices
import CryptoKit
import CloudKit

// MARK: - User Model
struct AppUser {
    let id: String
    let email: String?
    let displayName: String?
    let photoURL: URL?
    let subscriptionTier: SubscriptionTier
    let aiGenerationsRemaining: Int
    let aiGenerationResetDate: Date?
    let iCloudRecordID: String?

    init(
        id: String,
        email: String? = nil,
        displayName: String? = nil,
        photoURL: URL? = nil,
        subscriptionTier: SubscriptionTier = .free,
        aiGenerationsRemaining: Int = 1,
        aiGenerationResetDate: Date? = nil,
        iCloudRecordID: String? = nil
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.subscriptionTier = subscriptionTier
        self.aiGenerationsRemaining = aiGenerationsRemaining
        self.aiGenerationResetDate = aiGenerationResetDate
        self.iCloudRecordID = iCloudRecordID
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

// MARK: - Auth Manager (iCloud-based)
@MainActor
class AuthManager: ObservableObject {

    // MARK: - Published Properties
    @Published var currentUser: AppUser?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var iCloudAvailable = false

    // MARK: - Private Properties
    private let container = CKContainer.default()

    // MARK: - Init
    init() {
        // Immediately set up local user for simulator/fallback
        // This ensures the app is usable even if iCloud check hangs
        #if targetEnvironment(simulator)
        setupLocalUser()
        #else
        Task {
            await checkiCloudStatus()
        }
        #endif
    }

    // MARK: - iCloud Status Check
    private func checkiCloudStatus() async {
        do {
            let status = try await container.accountStatus()
            switch status {
            case .available:
                iCloudAvailable = true
                await fetchOrCreateiCloudUser()
            case .noAccount:
                iCloudAvailable = false
                setupLocalUser()
            case .restricted, .couldNotDetermine, .temporarilyUnavailable:
                iCloudAvailable = false
                setupLocalUser()
            @unknown default:
                iCloudAvailable = false
                setupLocalUser()
            }
        } catch {
            iCloudAvailable = false
            setupLocalUser()
        }
    }

    // MARK: - Fetch or Create iCloud User
    private func fetchOrCreateiCloudUser() async {
        isLoading = true

        do {
            let userRecordID = try await container.userRecordID()
            let userId = userRecordID.recordName

            currentUser = AppUser(
                id: userId,
                email: nil,
                displayName: "You",
                photoURL: nil,
                subscriptionTier: .premium,
                aiGenerationsRemaining: 10,
                aiGenerationResetDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
                iCloudRecordID: userId
            )
            isAuthenticated = true
        } catch {
            print("Failed to get iCloud user: \(error)")
            setupLocalUser()
        }

        isLoading = false
    }

    // MARK: - Local User Setup (fallback)
    private func setupLocalUser() {
        // Use device ID as fallback when iCloud is not available
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString

        currentUser = AppUser(
            id: deviceId,
            email: nil,
            displayName: "You",
            photoURL: nil,
            subscriptionTier: .premium,
            aiGenerationsRemaining: 10,
            aiGenerationResetDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())
        )
        isAuthenticated = true
    }

    // MARK: - Sign In with Apple (stores to iCloud)
    func signInWithApple(credential: ASAuthorizationAppleIDCredential, nonce: String) async {
        isLoading = true

        // Get user info from Apple credential
        let userId = credential.user
        let email = credential.email
        let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")

        currentUser = AppUser(
            id: userId,
            email: email,
            displayName: fullName.isEmpty ? "You" : fullName,
            photoURL: nil,
            subscriptionTier: .premium,
            aiGenerationsRemaining: 10,
            aiGenerationResetDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
            iCloudRecordID: userId
        )
        isAuthenticated = true

        // Sync user to iCloud
        await syncUserToiCloud()

        isLoading = false
    }

    // MARK: - Sync User to iCloud
    private func syncUserToiCloud() async {
        guard iCloudAvailable, let user = currentUser else { return }

        let record = CKRecord(recordType: "UserProfile")
        record["userId"] = user.id
        record["displayName"] = user.displayName
        record["email"] = user.email
        record["subscriptionTier"] = user.subscriptionTier.rawValue

        do {
            try await container.privateCloudDatabase.save(record)
        } catch {
            print("Failed to sync user to iCloud: \(error)")
        }
    }

    // MARK: - Sign In with Google (not yet implemented - uses iCloud instead)
    func signInWithGoogle() async {
        // Google Sign-In not needed - app uses iCloud for sync
        // This method exists for compatibility with legacy UI
        await checkiCloudStatus()
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
        // Decrement AI generation count (stored in iCloud)
        guard var user = currentUser, user.aiGenerationsRemaining > 0 else { return }

        let newRemaining = user.aiGenerationsRemaining - 1
        currentUser = AppUser(
            id: user.id,
            email: user.email,
            displayName: user.displayName,
            photoURL: user.photoURL,
            subscriptionTier: user.subscriptionTier,
            aiGenerationsRemaining: newRemaining,
            aiGenerationResetDate: user.aiGenerationResetDate,
            iCloudRecordID: user.iCloudRecordID
        )

        await syncUserToiCloud()
    }

    // MARK: - Refresh iCloud Status
    func refreshiCloudStatus() async {
        await checkiCloudStatus()
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
