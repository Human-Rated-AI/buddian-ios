import Foundation
import FirebaseAuth
import AuthenticationServices
import CryptoKit

@MainActor
final class AuthService: NSObject, ObservableObject {
    static let shared = AuthService()

    @Published var isLoading = false
    @Published var errorMessage: String?

    nonisolated(unsafe) private var currentNonce: String?
    nonisolated(unsafe) private var authorizationController: ASAuthorizationController?
    private let sessionManager = SessionManager.shared

    var isAuthenticated: Bool {
        sessionManager.isAuthenticated
    }

    private override init() {
        super.init()
    }

    // MARK: - Sign in with Apple

    func signInWithApple() {
        print("[Auth] signInWithApple tapped")
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
        print("[Auth] Presenting Apple Sign In controller")
        controller.performRequests()
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("[Auth] Firebase sign out error: \(error)")
        }
        sessionManager.clearSession()
        APIClient.shared.sessionToken = nil
    }

    // MARK: - Firebase Token Exchange

    private func exchangeToken(firebaseUser: User) async {
        isLoading = true
        errorMessage = nil

        do {
            print("[Auth] Getting Firebase ID token")
            let idToken = try await firebaseUser.getIDToken()
            print("[Auth] Got Firebase ID token, exchanging for session")

            let account = APIClient.shared
            let response: AuthResponse = try await account.post(
                path: "/web/auth/firebase",
                body: [
                    "firebase_token": idToken,
                    "platform": "ios",
                ]
            )

            print("[Auth] Got session token: \(response.sessionToken.prefix(10))...")
            sessionManager.saveSession(
                token: response.sessionToken,
                uid: response.account.uid,
                email: response.account.email
            )
            APIClient.shared.sessionToken = response.sessionToken
            print("[Auth] Session saved, user authenticated")
        } catch {
            print("[Auth] Exchange error: \(error)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Nonce Helpers

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
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        print("[Auth] Apple authorization received")

        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            print("[Auth] ERROR: Not an AppleID credential")
            return
        }

        guard let identityToken = appleIDCredential.identityToken,
              let idTokenString = String(data: identityToken, encoding: .utf8) else {
            print("[Auth] ERROR: No identity token")
            return
        }

        guard let nonce = currentNonce else {
            print("[Auth] ERROR: No nonce stored")
            return
        }

        print("[Auth] Creating Firebase credential")
        let credential = OAuthProvider.credential(
            providerID: AuthProviderID.apple,
            idToken: idTokenString,
            rawNonce: nonce,
            accessToken: nil
        )

        Task { @MainActor in
            isLoading = true
            do {
                print("[Auth] Signing in to Firebase")
                let result = try await Auth.auth().signIn(with: credential)
                print("[Auth] Firebase sign-in succeeded, user: \(result.user.uid)")
                await exchangeToken(firebaseUser: result.user)
            } catch {
                print("[Auth] Firebase sign-in error: \(error)")
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        let nsError = error as NSError
        print("[Auth] Apple authorization error: \(error) (code: \(nsError.code))")
        Task { @MainActor in
            if nsError.code != ASAuthorizationError.canceled.rawValue {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthService: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        print("[Auth] presentationAnchor requested")
        return MainActor.assumeIsolated {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                fatalError("No window available for Apple Sign In")
            }
            return window
        }
    }
}

// MARK: - Auth Response

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
