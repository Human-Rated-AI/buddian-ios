import Foundation
import UserNotifications
import UIKit

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isRegistered = false

    private init() {}

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            return granted
        } catch {
            NSLog("[Notifications] Permission error: \(error)")
            return false
        }
    }

    func registerDeviceToken(_ token: Data) {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        NSLog("[Notifications] Device token: \(tokenString)")
        Task {
            await sendTokenToBackend(tokenString)
        }
    }

    func handleRegistrationError(_ error: Error) {
        NSLog("[Notifications] Registration error: \(error)")
    }

    private func sendTokenToBackend(_ token: String) async {
        do {
            let _: EmptyResponse = try await APIClient.shared.post(
                path: "/notifications/register",
                body: ["device_token": token, "platform": "ios"]
            )
            isRegistered = true
            NSLog("[Notifications] Token sent to backend")
        } catch {
            NSLog("[Notifications] Failed to send token: \(error)")
        }
    }
}

struct EmptyResponse: Codable {}
