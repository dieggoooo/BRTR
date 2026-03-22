import SwiftUI

@main
struct BRTRApp: App {
    @StateObject private var authManager = AuthManager.shared

    init() {
        // Set dark tab bar globally at launch — before any view renders
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(red: 30/255, green: 26/255, blue: 58/255, alpha: 1) // brtrCard #1E1A3A
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        // Dark nav bar globally
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
    }

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
