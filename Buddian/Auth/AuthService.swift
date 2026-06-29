import Foundation
import FirebaseAuth
import AuthenticationServices
import CryptoKit

@MainActor
final class AuthService: NSObject, ObservableObject {
    static let shared = AuthService()

    @Published var isLoading = false
    @Published var errorMessage: String?

    private var currentNonce: String?
    private var authController: ASAuthorizationController?
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
        authController = controller

        NSLog("[Auth] Calling performRequests")
        controller.performRequests()
        NSLog("[Auth] performRequests returned")
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            NSLog("[Auth] signOut error: \(error)")
        }
        sessionManager.clearSession()
        APIClient.shared.sessionToken = nil
    }

    // MARK: - Token Exchange

    private func exchangeToken(firebaseUser: User) async {
        isLoading = true
        errorMessage = nil

        do {
            NSLog("[Auth] Getting Firebase ID token")
            let idToken = try await firebaseUser.getIDToken()
            NSLog("[Auth] Got token, calling /web/auth/firebase")

            let response: AuthResponse = try await APIClient.shared.post(
                path: "/web/auth/firebase",
                body: [
                    "firebase_token": idToken,
                    "platform": "ios",
                ]
            )

            NSLog("[Auth] Session obtained for uid: \(response.account.uid)")
            sessionManager.saveSession(
                token: response.sessionToken,
                uid: response.account.uid,
                email: response.account.email
            )
            APIClient.shared.sessionToken = response.sessionToken
        } catch {
            NSLog("[Auth] Exchange failed: \(error)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
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
        SHA256.hash(data: Data(input.utf8)).compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthService: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        NSLog("[Auth] Apple credential received")

        guard let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            NSLog("[Auth] ERROR: not AppleID credential")
            return
        }
        guard let identityToken = appleCredential.identityToken,
              let tokenStr = String(data: identityToken, encoding: .utf8) else {
            NSLog("[Auth] ERROR: no identity token")
            return
        }
        guard let nonce = currentNonce else {
            NSLog("[Auth] ERROR: no nonce")
            return
        }

        NSLog("[Auth] Building Firebase OAuth credential")
        let credential = OAuthProvider.credential(
            providerID: AuthProviderID.apple,
            idToken: tokenStr,
            rawNonce: nonce,
            accessToken: nil
        )

        Task { @MainActor in
            isLoading = true
            do {
                NSLog("[Auth] Firebase signIn")
                let result = try await Auth.auth().signIn(with: credential)
                NSLog("[Auth] Firebase OK: \(result.user.uid)")
                await exchangeToken(firebaseUser: result.user)
            } catch {
                NSLog("[Auth] Firebase error: \(error)")
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        let code = (error as NSError).code
        NSLog("[Auth] Apple error code \(code): \(error)")
        if code != ASAuthorizationError.canceled.rawValue {
            Task { @MainActor in errorMessage = error.localizedDescription }
        }
    }
}

// MARK: - Presentation Context

extension AuthService: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        NSLog("[Auth] presentationAnchor requested")
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            fatalError("No window for Apple Sign In")
        }
        return window
    }
}

// MARK: - Models

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
