import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            AskView()
                .tabItem {
                    Label("Ask", systemImage: "bubble.left.and.bubble.right")
                }

            ModelsView()
                .tabItem {
                    Label("Models", systemImage: "cpu")
                }

            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "photo.on.rectangle")
                }

            WalletView()
                .tabItem {
                    Label("Wallet", systemImage: "creditcard")
                }
        }
    }
}

#Preview {
    ContentView()
}
