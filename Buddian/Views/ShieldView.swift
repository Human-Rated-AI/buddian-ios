import SwiftUI

struct ShieldView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Shield")
                    .font(.largeTitle)
                Text("Privacy and attestation")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Shield")
        }
    }
}

#Preview {
    ShieldView()
}
