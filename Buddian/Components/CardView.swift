import SwiftUI

struct CardView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    CardView {
        VStack(alignment: .leading) {
            Text("Card Title")
                .font(.headline)
            Text("Card content goes here")
                .foregroundStyle(.secondary)
        }
    }
    .padding()
}
