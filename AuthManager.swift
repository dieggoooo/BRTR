import Foundation
import Supabase
import AuthenticationServices

@MainActor
class AuthManager: ObservableObject {
    @Published var currentUser: UserProfile?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    static let shared = AuthManager()
    private init() {}

    // MARK: - Session
    func restoreSession() async {
        do {
            let session = try await supabase.auth.session
            isAuthenticated = true
            await fetchCurrentUser(id: session.user.id)
        } catch {
            isAuthenticated = false
        }
    }

    // MARK: - Sign Up
    func signUp(email: String, password: String, username: String, fullName: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await supabase.auth.signUp(
                email: email,
                password: password
            )
            // Create user profile in DB
            let profile = [
                "id": response.user.id.uuidString,
                "username": username,
                "full_name": fullName,
                "rating": "0.0",
                "review_count": "0"
            ]
            try await supabase
                .from("users")
                .insert(profile)
                .execute()

            isAuthenticated = true
            await fetchCurrentUser(id: response.user.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Sign In
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            isAuthenticated = true
            await fetchCurrentUser(id: session.user.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Sign In with Apple
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async {
        isLoading = true
        errorMessage = nil
        guard let tokenData = credential.identityToken,
              let token = String(data: tokenData, encoding: .utf8) else {
            errorMessage = "Failed to get Apple identity token"
            isLoading = false
            return
        }
        do {
            let session = try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: token
                )
            )
            isAuthenticated = true
            await fetchCurrentUser(id: session.user.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Sign Out
    func signOut() async {
        do {
            try await supabase.auth.signOut()
            isAuthenticated = false
            currentUser = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Fetch Current User
    private func fetchCurrentUser(id: UUID) async {
        do {
            let profile: UserProfile = try await supabase
                .from("users")
                .select()
                .eq("id", value: id.uuidString)
                .single()
                .execute()
                .value
            currentUser = profile
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Update Profile
    func updateProfile(username: String, fullName: String, bio: String) async {
        guard let userId = currentUser?.id else { return }
        isLoading = true
        do {
            let updates = [
                "username": username,
                "full_name": fullName,
                "bio": bio
            ]
            try await supabase
                .from("users")
                .update(updates)
                .eq("id", value: userId.uuidString)
                .execute()
            currentUser?.username = username
            currentUser?.fullName = fullName
            currentUser?.bio = bio
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
