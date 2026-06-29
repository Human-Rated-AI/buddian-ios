import SwiftUI
import FirebaseCore

@main
struct BuddianApp: App {
    @StateObject private var modelCache = ModelCache.shared
    @StateObject private var sessionManager = SessionManager.shared

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if sessionManager.isAuthenticated {
                    ContentView()
                } else {
                    LoginView()
                }
            }
            .environmentObject(modelCache)
            .environmentObject(sessionManager)
            .task {
                if sessionManager.isAuthenticated {
                    APIClient.shared.sessionToken = sessionManager.sessionToken
                    await modelCache.refresh()
                }
            }
        }
    }
}
