import SwiftUI

@main
struct BRTRApp: App {
    @StateObject private var authManager = AuthManager.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isAuthenticated {
                    MainTabView()
                        .environmentObject(authManager)
                        .environmentObject(ServicesManager.shared)
                        .environmentObject(BarterManager.shared)
                        .environmentObject(MessagingManager.shared)
                } else {
                    OnboardingView()
                        .environmentObject(authManager)
                }
            }
            .task {
                await authManager.restoreSession()
            }
        }
    }
}
