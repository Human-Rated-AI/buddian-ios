import SwiftUI

struct WalletView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.largeTitle)
                            .foregroundStyle(.blue)
                        Text("Free Generation")
                            .font(.headline)
                        Text("All generations are free via Pollinations.ai. No credits needed.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }

                Section("Available Models") {
                    HStack {
                        Image(systemName: "photo")
                            .foregroundStyle(.blue)
                        Text("26 Image Models")
                        Spacer()
                        Text("Free")
                            .foregroundStyle(.green)
                    }
                    HStack {
                        Image(systemName: "video")
                            .foregroundStyle(.purple)
                        Text("12 Video Models")
                        Spacer()
                        Text("Free")
                            .foregroundStyle(.green)
                    }
                }

                Section("Powered By") {
                    HStack {
                        Text("Pollinations.ai")
                            .font(.headline)
                        Spacer()
                        Link("Visit", destination: URL(string: "https://pollinations.ai")!)
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle("Wallet")
        }
    }
}

#Preview {
    WalletView()
}
