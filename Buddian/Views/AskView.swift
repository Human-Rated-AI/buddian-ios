import SwiftUI

struct AskView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Ask")
                    .font(.largeTitle)
                Text("Run inference with your chosen model")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Ask")
        }
    }
}

#Preview {
    AskView()
}
