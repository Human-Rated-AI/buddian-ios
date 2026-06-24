import SwiftUI

struct ShieldView: View {
    @State private var endpointURL = "https://api.buddian.com"

    var body: some View {
        NavigationStack {
            List {
                Section("Source Verification") {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                        VStack(alignment: .leading) {
                            Text("Build Verification")
                                .font(.headline)
                            Text("Source matches signed release")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }

                Section("Settings") {
                    HStack {
                        Text("Endpoint")
                        Spacer()
                        Text(endpointURL)
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Shield")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(.green)
                }
            }
        }
    }
}

#Preview {
    ShieldView()
}
