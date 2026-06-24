import SwiftUI

struct ModelsView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Models")
                    .font(.largeTitle)
                Text("Browse available AI models")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Models")
        }
    }
}

#Preview {
    ModelsView()
}
