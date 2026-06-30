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
    nonisolated(unsafe) private var authController: ASAuthorizationController?
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

    // MARK: - Handle Apple Authorization (called from SignInWithAppleButton)

    func handleAppleAuthorization(_ authorization: ASAuthorization) async {
        guard let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            NSLog("[Auth] Not AppleID credential")
            return
        }
        guard let identityToken = appleCredential.identityToken,
              let tokenStr = String(data: identityToken, encoding: .utf8) else {
            errorMessage = "Failed to get Apple identity token"
            return
        }
        guard let nonce = currentNonce else {
            errorMessage = "Missing authentication nonce"
            return
        }

        isLoading = true
        NSLog("[Auth] Creating Firebase credential from Apple token")

        let credential = OAuthProvider.credential(
            providerID: AuthProviderID.apple,
            idToken: tokenStr,
            rawNonce: nonce,
            accessToken: nil
        )

        do {
            NSLog("[Auth] Signing in to Firebase")
            let result = try await Auth.auth().signIn(with: credential)
            NSLog("[Auth] Firebase OK: \(result.user.uid)")
            await exchangeToken(firebaseUser: result.user)
        } catch {
            NSLog("[Auth] Firebase error: \(error)")
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Token Exchange

    private func exchangeToken(firebaseUser: User) async {
        isLoading = true
        errorMessage = nil

        do {
            NSLog("[Auth] Getting Firebase ID token")
            let idToken = try await firebaseUser.getIDToken()
            NSLog("[Auth] Got token, calling /web/auth/firebase")

            // Log raw response for debugging
            let url = URL(string: "https://api.buddian.com/web/auth/firebase")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.httpBody = try JSONEncoder().encode([
                "id_token": idToken,
                "platform": "ios",
            ])
            let (data, response) = try await URLSession.shared.data(for: request)
            let body = String(data: data, encoding: .utf8) ?? "nil"
            NSLog("[Auth] Raw response (\((response as? HTTPURLResponse)?.statusCode ?? 0)): \(body)")

            let decoder = JSONDecoder()
            let sessionToken = try decoder.decode(String.self, from: data, keyPath: "session_token")
            NSLog("[Auth] Session token: \(sessionToken.prefix(10))...")

            // Try to extract uid from various possible locations
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let uid: String
            if let account = json?["account"] as? [String: Any], let id = account["uid"] as? String {
                uid = id
            } else if let id = json?["uid"] as? String {
                uid = id
            } else if let user = json?["user"] as? [String: Any], let id = user["uid"] as? String {
                uid = id
            } else {
                uid = "unknown"
            }

            let email = (json?["account"] as? [String: Any])?["email"] as? String
                ?? json?["email"] as? String

            NSLog("[Auth] Session obtained for uid: \(uid)")
            sessionManager.saveSession(token: sessionToken, uid: uid, email: email)
            APIClient.shared.sessionToken = sessionToken
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

    /// Generate a raw nonce (hashed version for Apple) — used by SignInWithAppleButton
    func testNonce() -> String {
        let raw = randomNonceString()
        currentNonce = raw
        return sha256(raw)
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
        var anchor: ASPresentationAnchor!
        DispatchQueue.main.sync {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = scene.windows.first {
                anchor = window
            }
        }
        return anchor
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

// MARK: - JSONDecoder keyPath helper

extension JSONDecoder {
    func decode<T>(_ type: T.Type, from data: Data, keyPath: String) throws -> T where T: Decodable {
        let topLevel = try JSONSerialization.jsonObject(with: data)
        var current: Any = topLevel
        for component in keyPath.split(separator: ".") {
            guard let dict = current as? [String: Any],
                  let next = dict[String(component)] else {
                throw DecodingError.keyNotFound(
                    CodingKeys(rawValue: String(component)),
                    .init(codingPath: [], debugDescription: "Key path '\(keyPath)' not found")
                )
            }
            current = next
        }
        let nestedData = try JSONSerialization.data(withJSONObject: current)
        return try decode(type, from: nestedData)
    }
}
