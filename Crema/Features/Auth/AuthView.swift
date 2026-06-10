//
//  AuthView.swift
//  Crema
//
//  Created by James Watling on 25/05/2026.
//

import SwiftUI
import Supabase

// MARK: - Screen state

private enum AuthScreen {
    case login, signup, forgotPassword
}

// MARK: - Root auth view

struct AuthView: View {
    @State private var screen: AuthScreen = .login
    @State private var email           = ""
    @State private var password        = ""
    @State private var confirmPassword = ""
    @State private var name            = ""
    @State private var isLoading       = false
    @State private var errorMessage:   String?
    @State private var successMessage: String?

    var body: some View {
        ZStack {
            Color.cremaBgPrimary.ignoresSafeArea()

            Group {
                switch screen {
                case .login:
                    LoginScreen(
                        email: $email,
                        password: $password,
                        isLoading: $isLoading,
                        errorMessage: $errorMessage,
                        onSignIn: signIn,
                        onSignUp: { withAnimation { screen = .signup } },
                        onForgot: { withAnimation { screen = .forgotPassword } }
                    )
                case .signup:
                    SignupScreen(
                        name: $name,
                        email: $email,
                        password: $password,
                        confirmPassword: $confirmPassword,
                        isLoading: $isLoading,
                        errorMessage: $errorMessage,
                        onSignUp: signUp,
                        onBack: { withAnimation { screen = .login } }
                    )
                case .forgotPassword:
                    ForgotPasswordScreen(
                        email: $email,
                        isLoading: $isLoading,
                        errorMessage: $errorMessage,
                        successMessage: $successMessage,
                        onSend: resetPassword,
                        onBack: { withAnimation { screen = .login } }
                    )
                }
            }
            .transition(.opacity)
        }
    }

    // MARK: - Actions

    private func signIn() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter your email and password."
            return
        }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await supabase.auth.signIn(email: email, password: password)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func signUp() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters."
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords don't match."
            return
        }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                // Pass the display name as user metadata so the API can store it.
                let metadata: [String: AnyJSON]? = name.isEmpty ? nil : ["full_name": .string(name)]
                try await supabase.auth.signUp(email: email, password: password, data: metadata)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func resetPassword() {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email address."
            return
        }
        isLoading = true
        errorMessage = nil
        successMessage = nil
        Task {
            do {
                try await supabase.auth.resetPasswordForEmail(email)
                successMessage = "Check your inbox for a reset link."
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

// MARK: - Login screen

private struct LoginScreen: View {
    @Binding var email: String
    @Binding var password: String
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?

    let onSignIn: () -> Void
    let onSignUp: () -> Void
    let onForgot: () -> Void

    @FocusState private var focused: FormField?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hero wordmark — expands to fill top space
            Spacer()
            VStack(alignment: .leading, spacing: 6) {
                Text("Crema")
                    .font(.cremaDisplay(size: 52))
                    .foregroundStyle(Color.cremaCopper)
                    .kerning(-0.02 * 52)

                Text("espresso shot tracker")
                    .font(.cremaBody(size: 13))
                    .foregroundStyle(Color.cremaTextSecondary)
                    .kerning(0.01 * 13)
            }
            .padding(.bottom, 16)
            Spacer()

            // Fields
            VStack(spacing: 14) {
                CremaTextField(
                    label: "email",
                    placeholder: "you@example.com",
                    text: $email,
                    focused: $focused,
                    field: .email,
                    keyboard: .emailAddress
                )
                .submitLabel(.next)
                .onSubmit { focused = .password }

                VStack(spacing: 5) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("password")
                            .font(.cremaMono(size: 9))
                            .foregroundStyle(Color.cremaTextSecondary)
                            .textCase(.uppercase)
                            .tracking(0.08 * 9)
                        Spacer()
                        Button("forgot?", action: onForgot)
                            .font(.cremaBody(size: 11))
                            .foregroundStyle(Color.cremaCopper)
                            .disabled(isLoading)
                    }
                    SecureTextField(
                        placeholder: "••••••••",
                        text: $password,
                        focused: $focused,
                        field: .password
                    )
                    .submitLabel(.go)
                    .onSubmit(onSignIn)
                }
            }
            .padding(.bottom, 20)

            // Error
            if let msg = errorMessage {
                ErrorLabel(message: msg).padding(.bottom, 12)
            }

            // CTA
            CremaPrimaryButton(label: "sign in", isLoading: isLoading, action: onSignIn)

            // Sign-up link
            HStack(spacing: 4) {
                Text("New to Crema?")
                    .font(.cremaBody(size: 13))
                    .foregroundStyle(Color.cremaTextSecondary)
                Button("create account", action: onSignUp)
                    .font(.cremaBody(size: 13))
                    .foregroundStyle(Color.cremaCopper)
                    .disabled(isLoading)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 20)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 36)
    }
}

// MARK: - Signup screen

private struct SignupScreen: View {
    @Binding var name: String
    @Binding var email: String
    @Binding var password: String
    @Binding var confirmPassword: String
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?

    let onSignUp: () -> Void
    let onBack: () -> Void

    @FocusState private var focused: FormField?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Logo (smaller in signup)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Crema")
                        .font(.cremaDisplay(size: 40))
                        .foregroundStyle(Color.cremaCopper)
                        .kerning(-0.02 * 40)

                    Text("create your account")
                        .font(.cremaBody(size: 12))
                        .foregroundStyle(Color.cremaTextSecondary)
                        .kerning(0.01 * 12)
                }
                .padding(.bottom, 32)

                // Fields
                VStack(spacing: 14) {
                    CremaTextField(
                        label: "name",
                        placeholder: "Your name",
                        text: $name,
                        focused: $focused,
                        field: .name
                    )
                    .submitLabel(.next)
                    .onSubmit { focused = .email }

                    CremaTextField(
                        label: "email",
                        placeholder: "you@example.com",
                        text: $email,
                        focused: $focused,
                        field: .email,
                        keyboard: .emailAddress
                    )
                    .submitLabel(.next)
                    .onSubmit { focused = .password }

                    VStack(spacing: 5) {
                        Text("password")
                            .font(.cremaMono(size: 9))
                            .foregroundStyle(Color.cremaTextSecondary)
                            .textCase(.uppercase)
                            .tracking(0.08 * 9)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        SecureTextField(
                            placeholder: "8+ characters",
                            text: $password,
                            focused: $focused,
                            field: .password
                        )
                        .submitLabel(.next)
                        .onSubmit { focused = .confirmPassword }
                    }

                    VStack(spacing: 5) {
                        Text("confirm password")
                            .font(.cremaMono(size: 9))
                            .foregroundStyle(Color.cremaTextSecondary)
                            .textCase(.uppercase)
                            .tracking(0.08 * 9)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        SecureTextField(
                            placeholder: "repeat password",
                            text: $confirmPassword,
                            focused: $focused,
                            field: .confirmPassword
                        )
                        .submitLabel(.go)
                        .onSubmit(onSignUp)
                    }
                }
                .padding(.bottom, 20)

                // Error
                if let msg = errorMessage {
                    ErrorLabel(message: msg).padding(.bottom, 12)
                }

                CremaPrimaryButton(label: "create account", isLoading: isLoading, action: onSignUp)

                HStack(spacing: 4) {
                    Text("Already have an account?")
                        .font(.cremaBody(size: 12))
                        .foregroundStyle(Color.cremaTextSecondary)
                    Button("sign in", action: onBack)
                        .font(.cremaBody(size: 12))
                        .foregroundStyle(Color.cremaCopper)
                        .disabled(isLoading)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 20)

                Text("By continuing you agree to our ")
                    .font(.cremaBody(size: 11))
                    .foregroundStyle(Color.cremaTextSecondary)
                + Text("Terms").font(.cremaBody(size: 11)).foregroundStyle(Color.cremaCopper)
                + Text(" and ").font(.cremaBody(size: 11)).foregroundStyle(Color.cremaTextSecondary)
                + Text("Privacy Policy").font(.cremaBody(size: 11)).foregroundStyle(Color.cremaCopper)
                + Text(".").font(.cremaBody(size: 11)).foregroundStyle(Color.cremaTextSecondary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

// MARK: - Forgot password screen

private struct ForgotPasswordScreen: View {
    @Binding var email: String
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?
    @Binding var successMessage: String?

    let onSend: () -> Void
    let onBack: () -> Void

    @FocusState private var focused: FormField?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Back button
            Button(action: onBack) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 13, weight: .light))
                    Text("back")
                        .font(.cremaBody(size: 13))
                }
                .foregroundStyle(Color.cremaTextSecondary)
            }
            .padding(.bottom, 40)

            // Heading
            VStack(alignment: .leading, spacing: 10) {
                Text("reset password")
                    .font(.cremaDisplay(size: 28))
                    .foregroundStyle(Color.cremaTextPrimary)

                Text("Enter your email and we'll send you a link to get back in.")
                    .font(.cremaBody(size: 13))
                    .foregroundStyle(Color.cremaTextSecondary)
                    .lineSpacing(4)
            }
            .padding(.bottom, 32)

            // Email field
            CremaTextField(
                label: "email",
                placeholder: "you@example.com",
                text: $email,
                focused: $focused,
                field: .email,
                keyboard: .emailAddress
            )
            .submitLabel(.go)
            .onSubmit(onSend)
            .padding(.bottom, 20)

            // Error or success feedback
            if let msg = errorMessage {
                ErrorLabel(message: msg).padding(.bottom, 12)
            } else if let msg = successMessage {
                SuccessLabel(message: msg).padding(.bottom, 12)
            }

            CremaPrimaryButton(label: "send reset link", isLoading: isLoading, action: onSend)

            Button("back to sign in", action: onBack)
                .font(.cremaBody(size: 13))
                .foregroundStyle(Color.cremaTextSecondary)
                .frame(maxWidth: .infinity)
                .padding(.top, 28)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 36)
    }
}

// MARK: - Shared components

private enum FormField {
    case name, email, password, confirmPassword
}

private struct CremaTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var focused: FocusState<FormField?>.Binding
    let field: FormField
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.cremaMono(size: 9))
                .foregroundStyle(Color.cremaTextSecondary)
                .textCase(.uppercase)
                .tracking(0.08 * 9)

            TextField(placeholder, text: $text)
                .font(.cremaBody(size: 14))
                .foregroundStyle(Color.cremaTextPrimary)
                .keyboardType(keyboard)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused(focused, equals: field)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.cremaInputBg)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            focused.wrappedValue == field ? Color.cremaCopper : Color.cremaBorder,
                            lineWidth: 0.5
                        )
                )
                .animation(.easeInOut(duration: 0.15), value: focused.wrappedValue == field)
                .tint(Color.cremaCopper)
        }
    }
}

private struct SecureTextField: View {
    let placeholder: String
    @Binding var text: String
    var focused: FocusState<FormField?>.Binding
    let field: FormField

    @State private var isVisible = false

    var body: some View {
        HStack(spacing: 0) {
            Group {
                if isVisible {
                    TextField(placeholder, text: $text)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .font(.cremaBody(size: 14))
            .foregroundStyle(Color.cremaTextPrimary)
            .focused(focused, equals: field)
            .tint(Color.cremaCopper)

            Button {
                isVisible.toggle()
            } label: {
                Image(systemName: isVisible ? "eye.slash" : "eye")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(Color.cremaTextSecondary)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .animation(.easeInOut(duration: 0.15), value: isVisible)
        }
        .padding(.leading, 14)
        .padding(.trailing, 4)
        .padding(.vertical, 4)
        .background(Color.cremaInputBg)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    focused.wrappedValue == field ? Color.cremaCopper : Color.cremaBorder,
                    lineWidth: 0.5
                )
        )
        .animation(.easeInOut(duration: 0.15), value: focused.wrappedValue == field)
    }
}


private struct ErrorLabel: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.cremaBody(size: 12))
            .foregroundStyle(Color.cremaError)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SuccessLabel: View {
    let message: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 12, weight: .light))
            Text(message)
                .font(.cremaBody(size: 12))
        }
        .foregroundStyle(Color.cremaCopper)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview {
    AuthView()
}
