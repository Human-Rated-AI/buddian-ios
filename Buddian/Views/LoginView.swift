import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @StateObject private var authService = AuthService.shared
    @EnvironmentObject var sessionManager: SessionManager

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
                if authService.isLoading {
                    ProgressView("Signing in...")
                } else {
                    SignInWithAppleButton { request in
                        NSLog("[Login] onRequest")
                        let nonce = AuthService.shared.testNonce()
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = nonce
                    } onCompletion: { result in
                        NSLog("[Login] onCompletion: \(result)")
                        switch result {
                        case .success(let authorization):
                            NSLog("[Login] Apple credential OK, exchanging...")
                            Task {
                                await authService.handleAppleAuthorization(authorization)
                            }
                        case .failure(let error):
                            NSLog("[Login] Apple error: \(error)")
                            authService.errorMessage = error.localizedDescription
                        }
                    }
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Text("Your Apple ID is used to create your account securely.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                if let error = authService.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding(.horizontal, 32)

            Spacer()
                .frame(height: 40)
        }
        .background(Color(.systemBackground))
        .onAppear {
            NSLog("[Login] appeared")
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(SessionManager.shared)
}
