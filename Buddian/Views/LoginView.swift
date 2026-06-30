import SwiftUI
import AuthenticationServices
import GoogleSignIn

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

            VStack(spacing: 12) {
                if authService.isLoading {
                    ProgressView("Signing in...")
                } else {
                    SignInWithAppleButton { request in
                        NSLog("[Login] Apple onRequest")
                        let nonce = AuthService.shared.testNonce()
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = nonce
                    } onCompletion: { result in
                        NSLog("[Login] Apple onCompletion: \(result)")
                        switch result {
                        case .success(let authorization):
                            Task { await authService.handleAppleAuthorization(authorization) }
                        case .failure(let error):
                            authService.errorMessage = error.localizedDescription
                        }
                    }
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button {
                        signInWithGoogle()
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "g.circle.fill")
                                .font(.title2)
                            Text("Sign in with Google")
                                .font(.headline)
                            Spacer()
                        }
                        .frame(height: 50)
                        .background(.white)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.gray.opacity(0.3), lineWidth: 1)
                        )
                    }

                    Text("Your Apple ID or Google account is used to create your account securely.")
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

    private func signInWithGoogle() {
        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first?.rootViewController else { return }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { result, error in
            if let error {
                NSLog("[Login] Google error: \(error)")
                authService.errorMessage = error.localizedDescription
                return
            }
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                NSLog("[Login] Google: no idToken")
                return
            }
            NSLog("[Login] Google credential OK, exchanging...")
            Task {
                await authService.handleGoogleAuthorization(idToken: idToken)
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(SessionManager.shared)
}
