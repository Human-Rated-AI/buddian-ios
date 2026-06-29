import SwiftUI

struct LoginView: View {
    @StateObject private var authService = AuthService.shared
    @EnvironmentObject var sessionManager: SessionManager

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)

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
                    Button {
                        authService.signInWithApple()
                    } label: {
                        HStack {
                            Image(systemName: "apple.logo")
                            Text("Sign in with Apple")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.primary)
                        .foregroundStyle(.background)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

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
    }
}

#Preview {
    LoginView()
        .environmentObject(SessionManager.shared)
}
