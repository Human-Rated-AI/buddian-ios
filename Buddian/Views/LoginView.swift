import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @StateObject private var authService = AuthService.shared
    @EnvironmentObject var sessionManager: SessionManager
    @State private var showAppleAuth = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 12) {
                Image("AppLogo")
                    .resizable()
                    .frame(width: 80, height: 80)

                Text("Buddian")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Your private AI companion")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 16) {
                // Direct ASAuthorizationAppleIDProvider — no AuthService involved
                SignInWithAppleButton { request in
                    NSLog("[Login] SignInWithAppleButton.onRequest")
                    let nonce = AuthService.shared.testNonce()
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = nonce
                } onCompletion: { result in
                    NSLog("[Login] SignInWithAppleButton.onCompletion: \(result)")
                    switch result {
                    case .success(let authorization):
                        NSLog("[Login] Got Apple credential")
                    case .failure(let error):
                        NSLog("[Login] Apple error: \(error)")
                    }
                }
                .frame(height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Text("Your Apple ID is used to create your account securely.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer()
                .frame(height: 40)
        }
        .background(Color(.systemBackground))
        .onAppear {
            NSLog("[Login] LoginView appeared")
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(SessionManager.shared)
}
