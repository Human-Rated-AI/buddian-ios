import SwiftUI

struct WalletView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Wallet")
                    .font(.largeTitle)
                Text("Balance and credits")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Wallet")
        }
    }
}

#Preview {
    WalletView()
}
