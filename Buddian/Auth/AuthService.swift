import Foundation
import FirebaseAuth
import AuthenticationServices
import CryptoKit

final class AuthService: NSObject, ObservableObject {
    static let shared = AuthService()

    @Published var isLoading = false
    @Published var errorMessage: String?

    private var currentNonce: String?
    private var authorizationController: ASAuthorizationController?
    private let sessionManager = SessionManager.shared

    var isAuthenticated: Bool {
        sessionManager.isAuthenticated
    }

    private override init() {
        super.init()
    }

    // MARK: - Sign in with Apple

    func signInWithApple() {
        NSLog("[Auth] signInWithApple called")

        let nonce = randomNonceString()
        currentNonce = nonce

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        authorizationController = controller

        NSLog("[Auth] Calling performRequests")
        controller.performRequests()
        NSLog("[Auth] performRequests returned")
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            NSLog("[Auth] Firebase sign out error: \(error)")
        }
        sessionManager.clearSession()
        APIClient.shared.sessionToken = nil
    }

    // MARK: - Firebase Token Exchange

    private func exchangeToken(firebaseUser: User) async {
        await MainActor.run { isLoading = true; errorMessage = nil }

        do {
            NSLog("[Auth] Getting Firebase ID token")
            let idToken = try await firebaseUser.getIDToken()
            NSLog("[Auth] Got token, exchanging for session")

            let account = APIClient.shared
            let response: AuthResponse = try await account.post(
                path: "/web/auth/firebase",
                body: [
                    "firebase_token": idToken,
                    "platform": "ios",
                ]
            )

            NSLog("[Auth] Got session, uid: \(response.account.uid)")
            await MainActor.run {
                sessionManager.saveSession(
                    token: response.sessionToken,
                    uid: response.account.uid,
                    email: response.account.email
                )
                APIClient.shared.sessionToken = response.sessionToken
            }
        } catch {
            NSLog("[Auth] Exchange error: \(error)")
            await MainActor.run { errorMessage = error.localizedDescription }
        }

        await MainActor.run { isLoading = false }
    }

    // MARK: - Helpers

    private func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var random: UInt8 = 0
            let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            guard status == errSecSuccess else { fatalError("Unable to generate nonce") }
            if random < charset.count {
                result.append(charset[Int(random)])
                remaining -= 1
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthService: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        NSLog("[Auth] Apple authorization received")

        guard let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            NSLog("[Auth] ERROR: Not AppleID credential")
            return
        }

        guard let identityToken = appleCredential.identityToken,
              let tokenStr = String(data: identityToken, encoding: .utf8) else {
            NSLog("[Auth] ERROR: No identity token")
            return
        }

        guard let nonce = currentNonce else {
            NSLog("[Auth] ERROR: No nonce")
            return
        }

        NSLog("[Auth] Creating Firebase credential")
        let credential = OAuthProvider.credential(
            providerID: AuthProviderID.apple,
            idToken: tokenStr,
            rawNonce: nonce,
            accessToken: nil
        )

        Task {
            NSLog("[Auth] Signing in to Firebase")
            do {
                let result = try await Auth.auth().signIn(with: credential)
                NSLog("[Auth] Firebase OK, uid: \(result.user.uid)")
                await exchangeToken(firebaseUser: result.user)
            } catch {
                NSLog("[Auth] Firebase error: \(error)")
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        let code = (error as NSError).code
        NSLog("[Auth] Apple error: \(error) code: \(code)")
        if code != ASAuthorizationError.canceled.rawValue {
            Task { @MainActor in
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Presentation Context

extension AuthService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        NSLog("[Auth] presentationAnchor called")
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            return window
        }
        fatalError("No window for Apple Sign In")
    }
}

// MARK: - Response Models

struct AuthResponse: Codable {
    let sessionToken: String
    let account: AuthAccount

    enum CodingKeys: String, CodingKey {
        case sessionToken = "session_token"
        case account
    }
}

struct AuthAccount: Codable {
    let uid: String
    let email: String?
}
