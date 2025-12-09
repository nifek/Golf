import SwiftUI
import UIKit

struct AuthFlowView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showLogin: Bool = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 24)
            LogoView()
                .padding(.top, 8)
            Text(showLogin ? "Welcome Back!" : "Welcome!")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.accent)
                .padding(.bottom, 8)

            if showLogin {
                LoginForm { user in
                    appState.setCurrentUser(user)
                }
            } else {
                RegisterForm { user in
                    appState.setCurrentUser(user)
                }
            }

            HStack(spacing: 6) {
                Text(showLogin ? "Don't have an account?" : "Already have an account?")
                    .foregroundColor(.white.opacity(0.85))
                Button(action: { withAnimation { showLogin.toggle() } }) {
                    Text(showLogin ? "Sign Up" : "Log In")
                        .fontWeight(.semibold)
                }
            }
            .font(.subheadline)
            .foregroundColor(Theme.accent)

            Spacer()
        }
    }
}

private struct RegisterForm: View {
    var onSuccess: (UserResponse) -> Void
    @State private var email: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var isLoading: Bool = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 14) {
            LabeledField(
                systemName: "envelope.fill",
                placeholder: "Email",
                text: $email,
                keyboardType: .emailAddress,
                textContentType: .emailAddress
            )
            LabeledField(
                systemName: "person.fill",
                placeholder: "Username",
                text: $username,
                textContentType: .username
            )
            PasswordField(placeholder: "Create a password", text: $password, isVisible: $isPasswordVisible)

            Button(action: submit) {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text("Register")
                }
            }
            .buttonStyle(FilledButtonStyle())

            if let error = error {
                Text(error)
                    .foregroundColor(.red.opacity(0.9))
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .cardBackground()
    }

    private func submit() {
        error = nil
        isLoading = true
        Task {
            do {
                let user = try await AuthService.shared.register(
                    email: email,
                    password: password,
                    username: username
                )
                await MainActor.run {
                    onSuccess(user)
                }
            } catch {
                await MainActor.run {
                    self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                }
            }
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

private struct LoginForm: View {
    var onSuccess: (UserResponse) -> Void
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var isLoading: Bool = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 14) {
            LabeledField(
                systemName: "envelope.fill",
                placeholder: "Email",
                text: $email,
                keyboardType: .emailAddress,
                textContentType: .emailAddress
            )
            PasswordField(placeholder: "Enter your password", text: $password, isVisible: $isPasswordVisible)

            Button(action: submit) {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text("Login")
                }
            }
            .buttonStyle(FilledButtonStyle())

            if let error = error {
                Text(error)
                    .foregroundColor(.red.opacity(0.9))
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .cardBackground()
    }

    private func submit() {
        error = nil
        isLoading = true
        Task {
            do {
                let user = try await AuthService.shared.login(email: email, password: password)
                await MainActor.run {
                    onSuccess(user)
                }
            } catch {
                await MainActor.run {
                    self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                }
            }
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

struct LogoView: View {
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().fill(Theme.card).frame(width: 72, height: 72)
                Image(systemName: "flag.and.flag.filled.crossed")
                    .foregroundColor(.white)
                    .imageScale(.large)
            }
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text("Go")
                    .font(.system(size: 72, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.accent)
                Circle()
                    .fill(Theme.accent)
                    .frame(width: 24, height: 24)
                Text("lf")
                    .font(.system(size: 72, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.accent)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Golf")
    }
}

private struct LabeledField: View {
    let systemName: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: TextInputAutocapitalization = .never

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemName)
                .foregroundColor(.white.opacity(0.9))
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(autocapitalization)
                .textContentType(textContentType)
                .keyboardType(keyboardType)
                .autocorrectionDisabled()
                .foregroundColor(.white)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.surface)
        )
    }
}

private struct PasswordField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var isVisible: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .foregroundColor(.white.opacity(0.9))
            Group {
                if isVisible {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .textContentType(.password)
            .foregroundColor(.white)

            Button(action: { isVisible.toggle() }) {
                Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.surface)
        )
    }
}


