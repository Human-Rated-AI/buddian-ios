import SwiftUI
import FirebaseCore
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        NSLog("[Buddian] AppDelegate launching, configuring Firebase")
        FirebaseApp.configure()
        NSLog("[Buddian] Firebase configured: \(FirebaseApp.app() != nil)")

        UNUserNotificationCenter.current().delegate = self

        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken token: Data
    ) {
        NotificationManager.shared.registerDeviceToken(token)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        NotificationManager.shared.handleRegistrationError(error)
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .badge, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        NSLog("[Notifications] Tapped notification: \(userInfo)")
        completionHandler()
    }
}

@main
struct BuddianApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var modelCache = ModelCache.shared
    @StateObject private var sessionManager = SessionManager.shared
    @StateObject private var notificationManager = NotificationManager.shared

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
            .environmentObject(notificationManager)
            .task {
                if sessionManager.isAuthenticated {
                    APIClient.shared.sessionToken = sessionManager.sessionToken
                    await modelCache.refresh()
                    await notificationManager.requestPermission()
                }
            }
        }
    }
}
