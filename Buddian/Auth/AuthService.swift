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
    private let sessionManager = SessionManager.shared

    var isAuthenticated: Bool {
        sessionManager.isAuthenticated
    }

    private override init() {
        super.init()
    }

    // MARK: - Sign in with Apple

    func signInWithApple() {
        let nonce = randomNonceString()
        currentNonce = nonce

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Firebase sign out error: \(error)")
        }
        sessionManager.clearSession()
        APIClient.shared.sessionToken = nil
    }

    // MARK: - Firebase Token Exchange

    private func exchangeToken(firebaseUser: User) async {
        isLoading = true
        errorMessage = nil

        do {
            let idToken = try await firebaseUser.getIDToken()

            let account = APIClient.shared
            let response: AuthResponse = try await account.post(
                path: "/web/auth/firebase",
                body: [
                    "firebase_token": idToken,
                    "platform": "ios",
                ]
            )

            sessionManager.saveSession(
                token: response.sessionToken,
                uid: response.account.uid,
                email: response.account.email
            )
            APIClient.shared.sessionToken = response.sessionToken
        } catch {
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
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            return
        }

        guard let identityToken = appleIDCredential.identityToken,
              let idTokenString = String(data: identityToken, encoding: .utf8) else {
            return
        }

        guard let nonce = currentNonce else {
            return
        }

        let credential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: idTokenString,
            rawNonce: nonce
        )

        Task { @MainActor in
            isLoading = true
            do {
                let result = try await Auth.auth().signIn(with: credential)
                await exchangeToken(firebaseUser: result.user)
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        Task { @MainActor in
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthService: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window available for Apple Sign In")
        }
        return window
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
