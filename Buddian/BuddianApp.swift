import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        NSLog("[Buddian] AppDelegate launching, configuring Firebase")
        FirebaseApp.configure()
        NSLog("[Buddian] Firebase configured: \(FirebaseApp.app() != nil)")
        return true
    }
}

@main
struct BuddianApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var modelCache = ModelCache.shared
    @StateObject private var sessionManager = SessionManager.shared

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
