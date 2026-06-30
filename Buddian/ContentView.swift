import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            GenerateView()
                .tabItem {
                    Label("Generate", systemImage: "wand.and.stars")
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
