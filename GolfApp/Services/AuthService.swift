import Foundation

enum AuthError: LocalizedError {
    case usernameTaken
    case invalidCredentials
    case emptyFields

    var errorDescription: String? {
        switch self {
        case .usernameTaken:
            return "This username is already taken."
        case .invalidCredentials:
            return "Invalid username or password."
        case .emptyFields:
            return "Please fill in all fields."
        }
    }
}

actor AuthService {
    static let shared = AuthService()

    private var users: [String: String] = [
        "morz": "password"
    ]

    func register(username: String, password: String) async throws -> User {
        guard !username.trimmingCharacters(in: .whitespaces).isEmpty,
              !password.isEmpty else { throw AuthError.emptyFields }

        try await Task.sleep(nanoseconds: 300_000_000)
        if users[username.lowercased()] != nil {
            throw AuthError.usernameTaken
        }

        users[username.lowercased()] = password
        return User(id: UUID().uuidString, username: username)
    }

    func login(username: String, password: String) async throws -> User {
        guard !username.trimmingCharacters(in: .whitespaces).isEmpty,
              !password.isEmpty else { throw AuthError.emptyFields }

        try await Task.sleep(nanoseconds: 250_000_000)
        guard let stored = users[username.lowercased()], stored == password else {
            throw AuthError.invalidCredentials
        }

        return User(id: UUID().uuidString, username: username)
    }
}


