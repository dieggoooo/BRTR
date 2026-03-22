import SwiftUI
import AuthenticationServices

// MARK: - Splash colors (matched to screenshot)
private extension Color {
    static let splashBg           = Color(red: 0.051, green: 0.051, blue: 0.102)
    static let splashCard         = Color(red: 0.082, green: 0.082, blue: 0.157)
    static let splashField        = Color(red: 0.102, green: 0.102, blue: 0.180)
    static let splashPurple       = Color(red: 0.420, green: 0.275, blue: 0.961)
    static let splashToggleActive = Color(red: 0.482, green: 0.318, blue: 0.965)
    static let splashMuted        = Color(red: 0.45,  green: 0.45,  blue: 0.55)
    static let splashFbBlue       = Color(red: 0.231, green: 0.349, blue: 0.596)
    static let splashGoogleRed    = Color(red: 0.502, green: 0.102, blue: 0.102)
    static let splashAppleGray    = Color(red: 0.18,  green: 0.18,  blue: 0.22)
}

// MARK: - SplashView

struct SplashView: View {
    @State private var scale: CGFloat = 0.7
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.splashBg.ignoresSafeArea()
            VStack(spacing: 14) {
                Text("BRTR")
                    .font(.system(size: 60, weight: .black))
                    .foregroundColor(.white)
                    .tracking(10)
                    .scaleEffect(scale)
                    .opacity(opacity)
                Text("BARTERING SIMPLIFIED")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.splashMuted)
                    .tracking(5)
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.2)) {
                scale = 1.0; opacity = 1.0
            }
        }
    }
}

// MARK: - OnboardingView

struct OnboardingView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var mode: AuthMode = .signIn

    @State private var signInEmail    = ""
    @State private var signInPassword = ""

    @State private var signUpFullName = ""
    @State private var signUpUsername = ""
    @State private var signUpEmail    = ""
    @State private var signUpPassword = ""

    enum AuthMode { case signIn, signUp }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // Background
                Color.splashBg.ignoresSafeArea()

                // Purple glow
                RadialGradient(
                    gradient: Gradient(colors: [Color.splashPurple.opacity(0.22), Color.clear]),
                    center: UnitPoint(x: 0.5, y: 0.38),
                    startRadius: 0,
                    endRadius: 300
                )
                .ignoresSafeArea()

                // Logo pinned in upper portion
                VStack {
                    Spacer().frame(height: geo.size.height * 0.12)
                    VStack(spacing: 12) {
                        Text("BRTR")
                            .font(.system(size: 60, weight: .black))
                            .foregroundColor(.white)
                            .tracking(10)
                        Text("BARTERING SIMPLIFIED")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.splashMuted)
                            .tracking(5)
                    }
                    Spacer()
                }

                // Auth card — scrollable so nothing clips
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Spacer that keeps card near bottom
                        Spacer().frame(height: geo.size.height * 0.44)

                        // Card content
                        VStack(spacing: 0) {
                            // Toggle
                            HStack(spacing: 0) {
                                toggleBtn(label: "Sign In", active: mode == .signIn) {
                                    withAnimation(.spring(response: 0.28)) { mode = .signIn }
                                }
                                toggleBtn(label: "Sign Up", active: mode == .signUp) {
                                    withAnimation(.spring(response: 0.28)) { mode = .signUp }
                                }
                            }
                            .padding(5)
                            .background(Color.splashField)
                            .cornerRadius(14)
                            .padding(.horizontal, 20)
                            .padding(.top, 24)
                            .padding(.bottom, 14)

                            // Fields
                            VStack(spacing: 10) {
                                if mode == .signUp {
                                    inputRow(sfIcon: "person",   placeholder: "Full name", text: $signUpFullName)
                                    inputRow(sfIcon: "at",       placeholder: "Username",  text: $signUpUsername)
                                    inputRow(sfIcon: "envelope", placeholder: "Email",     text: $signUpEmail, isEmail: true)
                                    inputRow(sfIcon: "lock",     placeholder: "Password",  text: $signUpPassword, isSecure: true)
                                } else {
                                    inputRow(sfIcon: "envelope", placeholder: "Email",     text: $signInEmail, isEmail: true)
                                    inputRow(sfIcon: "lock",     placeholder: "Password",  text: $signInPassword, isSecure: true)
                                }
                            }
                            .padding(.horizontal, 20)

                            // Error
                            if let err = authManager.errorMessage {
                                Text(err)
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 8)
                            }

                            // Primary button
                            Button {
                                Task {
                                    if mode == .signIn {
                                        await authManager.signIn(email: signInEmail, password: signInPassword)
                                    } else {
                                        await authManager.signUp(
                                            email: signUpEmail, password: signUpPassword,
                                            username: signUpUsername, fullName: signUpFullName
                                        )
                                    }
                                }
                            } label: {
                                ZStack {
                                    if authManager.isLoading {
                                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text(mode == .signIn ? "Sign In" : "Create Account")
                                            .font(.system(size: 17, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.splashPurple)
                                .cornerRadius(14)
                            }
                            .disabled(authManager.isLoading || !formValid)
                            .padding(.horizontal, 20)
                            .padding(.top, 14)

                            // Forgot password
                            if mode == .signIn {
                                HStack {
                                    Spacer()
                                    Button("Forgot password?") {}
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(red: 0.49, green: 0.56, blue: 0.98))
                                        .underline()
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 10)
                            }

                            // Divider
                            HStack(spacing: 10) {
                                Rectangle().fill(Color.splashMuted.opacity(0.35)).frame(height: 1)
                                Text("or continue with")
                                    .font(.system(size: 12))
                                    .foregroundColor(.splashMuted)
                                    .fixedSize()
                                Rectangle().fill(Color.splashMuted.opacity(0.35)).frame(height: 1)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 18)
                            .padding(.bottom, 16)

                            // Social buttons
                            HStack(spacing: 28) {
                                socialBtn(label: "Facebook") {
                                    ZStack {
                                        Circle().fill(Color.splashFbBlue).frame(width: 58, height: 58)
                                        Text("f")
                                            .font(.system(size: 26, weight: .bold, design: .serif))
                                            .foregroundColor(.white)
                                            .offset(x: 1)
                                    }
                                }
                                socialBtn(label: "Google") {
                                    ZStack {
                                        Circle().fill(Color.splashGoogleRed).frame(width: 58, height: 58)
                                        Image(systemName: "globe")
                                            .font(.system(size: 22, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                }
                                socialBtn(label: "Apple") {
                                    ZStack {
                                        Circle().fill(Color.splashAppleGray).frame(width: 58, height: 58)
                                        Image(systemName: "apple.logo")
                                            .font(.system(size: 22, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .padding(.bottom, 44)
                        }
                        .background(
                            Color.splashCard
                                .clipShape(RoundedCornerShape(radius: 30, corners: [.topLeft, .topRight]))
                        )
                    }
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Helpers

    private var formValid: Bool {
        mode == .signIn
            ? !signInEmail.isEmpty && !signInPassword.isEmpty
            : !signUpFullName.isEmpty && !signUpUsername.isEmpty && !signUpEmail.isEmpty && !signUpPassword.isEmpty
    }

    private func toggleBtn(label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(active ? .white : .splashMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(active ? Color.splashToggleActive : Color.clear)
                .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func inputRow(
        sfIcon: String, placeholder: String,
        text: Binding<String>, isEmail: Bool = false, isSecure: Bool = false
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: sfIcon)
                .font(.system(size: 15))
                .foregroundColor(.splashMuted)
                .frame(width: 20)
            if isSecure {
                SecureField(placeholder, text: text)
                    .foregroundColor(.white).font(.system(size: 15)).tint(.splashPurple)
            } else {
                TextField(placeholder, text: text)
                    .foregroundColor(.white).font(.system(size: 15))
                    .autocapitalization(.none)
                    .keyboardType(isEmail ? .emailAddress : .default)
                    .tint(.splashPurple)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 16)
        .background(Color.splashField)
        .cornerRadius(12)
    }

    @ViewBuilder
    private func socialBtn<Content: View>(label: String, @ViewBuilder icon: () -> Content) -> some View {
        Button {} label: {
            VStack(spacing: 8) {
                icon()
                Text(label).font(.system(size: 11)).foregroundColor(.splashMuted)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Rounded corner helper

private struct RoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
