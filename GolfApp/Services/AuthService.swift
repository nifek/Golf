import Foundation
import FirebaseAuth

enum AuthServiceError: LocalizedError {
    case invalidEmail
    case invalidPassword
    case invalidUsername
    case missingProfile

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Enter a valid email address."
        case .invalidPassword:
            return "Password must be at least 6 characters."
        case .invalidUsername:
            return "Username must be between 3 and 100 characters."
        case .missingProfile:
            return "We could not find your profile. Please complete registration."
        }
    }
}

actor AuthService {
    static let shared = AuthService()
    private let apiClient = APIClient.shared

    /// Registers a new Firebase user and creates a backend profile.
    func register(email: String, password: String, username: String) async throws -> UserResponse {
        try validate(email: email, password: password, username: username)

        // Create Firebase account (also signs the user in)
        _ = try await Auth.auth().createUser(withEmail: email, password: password)

        // Sync username with backend
        let request = SyncUserRequest(username: username)
        return try await apiClient.request(
            endpoint: "/auth/sync",
            method: .post,
            body: request
        )
    }

    /// Signs in an existing Firebase user and fetches their backend profile.
    func login(email: String, password: String) async throws -> UserResponse {
        try validate(email: email, password: password, username: nil)

        _ = try await Auth.auth().signIn(withEmail: email, password: password)

        // Confirm backend profile exists
        let check: CheckUserResponse = try await apiClient.request(endpoint: "/auth/check")
        guard check.exists else { throw AuthServiceError.missingProfile }

        return try await apiClient.request(endpoint: "/auth/me")
    }

    /// Retrieves the current user's backend profile using the active Firebase session.
    func fetchCurrentUser() async throws -> UserResponse {
        try await apiClient.request(endpoint: "/auth/me")
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    // MARK: - Validation

    private func validate(email: String, password: String, username: String?) throws {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedEmail.contains("@"), trimmedEmail.contains(".") else {
            throw AuthServiceError.invalidEmail
        }

        guard password.count >= 6 else {
            throw AuthServiceError.invalidPassword
        }

        if let name = username {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard (3...100).contains(trimmedName.count) else {
                throw AuthServiceError.invalidUsername
            }
        }
    }
}
