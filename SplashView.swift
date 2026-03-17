import SwiftUI

// MARK: - SplashView
struct SplashView: View {
    @State private var scale: CGFloat = 0.7
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.brtrBackground.ignoresSafeArea()

            VStack(spacing: 16) {
                Text("BRTR")
                    .font(.system(size: 56, weight: .black))
                    .foregroundColor(.white)
                    .tracking(8)
                    .scaleEffect(scale)
                    .opacity(opacity)

                Text("Bartering Simplified")
                    .font(BRTRFont.subheadline())
                    .foregroundColor(.brtrTextSecondary)
                    .tracking(2)
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.2)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

// MARK: - OnboardingView
struct OnboardingView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showSignIn = false
    @State private var showSignUp = false

    var body: some View {
        ZStack {
            Color.brtrBackground.ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                VStack(spacing: 32) {
                    Image(systemName: "arrow.left.arrow.right.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.brtrPurple)

                    VStack(spacing: 16) {
                        Text("Trade Skills,\nNot Money")
                            .font(BRTRFont.largeTitle())
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text("Exchange your talents with people who have what you need.")
                            .font(BRTRFont.body())
                            .foregroundColor(.brtrTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }

                Spacer()

                VStack(spacing: 12) {
                    Button("Get Started") {
                        showSignUp = true
                    }
                    .buttonStyle(BRTRPrimaryButton())

                    Button("Sign In") {
                        showSignIn = true
                    }
                    .buttonStyle(BRTRSecondaryButton())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .sheet(isPresented: $showSignUp) {
            SignUpView()
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showSignIn) {
            SignInView()
                .environmentObject(authManager)
        }
    }
}

// MARK: - SignInView
struct SignInView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brtrBackground.ignoresSafeArea()

                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        inputField(placeholder: "Email", text: $email, isSecure: false)
                        inputField(placeholder: "Password", text: $password, isSecure: true)
                    }

                    if let error = authManager.errorMessage {
                        Text(error)
                            .font(BRTRFont.caption())
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        Task { await authManager.signIn(email: email, password: password) }
                    } label: {
                        if authManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity).padding()
                        } else {
                            Text("Sign In").frame(maxWidth: .infinity).padding()
                        }
                    }
                    .buttonStyle(BRTRPrimaryButton())
                    .disabled(email.isEmpty || password.isEmpty || authManager.isLoading)

                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Welcome back")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.brtrTextSecondary)
                }
            }
        }
    }

    private func inputField(placeholder: String, text: Binding<String>, isSecure: Bool) -> some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: text)
            } else {
                TextField(placeholder, text: text)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
        }
        .foregroundColor(.white)
        .padding(14)
        .background(Color.brtrCard)
        .cornerRadius(12)
    }
}

// MARK: - SignUpView
struct SignUpView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    @State private var username = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brtrBackground.ignoresSafeArea()

                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        inputField(placeholder: "Full name", text: $fullName, isSecure: false)
                        inputField(placeholder: "Username", text: $username, isSecure: false)
                        inputField(placeholder: "Email", text: $email, isSecure: false)
                        inputField(placeholder: "Password", text: $password, isSecure: true)
                    }

                    if let error = authManager.errorMessage {
                        Text(error)
                            .font(BRTRFont.caption())
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        Task {
                            await authManager.signUp(
                                email: email,
                                password: password,
                                username: username,
                                fullName: fullName
                            )
                        }
                    } label: {
                        if authManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity).padding()
                        } else {
                            Text("Create Account").frame(maxWidth: .infinity).padding()
                        }
                    }
                    .buttonStyle(BRTRPrimaryButton())
                    .disabled(email.isEmpty || password.isEmpty || fullName.isEmpty || username.isEmpty || authManager.isLoading)

                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Create account")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.brtrTextSecondary)
                }
            }
        }
    }

    private func inputField(placeholder: String, text: Binding<String>, isSecure: Bool) -> some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: text)
            } else {
                TextField(placeholder, text: text)
                    .autocapitalization(.none)
            }
        }
        .foregroundColor(.white)
        .padding(14)
        .background(Color.brtrCard)
        .cornerRadius(12)
    }
}
