import SwiftUI

struct LibraryView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Library")
                    .font(.largeTitle)
                Text("Your generated content")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Library")
        }
    }
}

#Preview {
    LibraryView()
}
