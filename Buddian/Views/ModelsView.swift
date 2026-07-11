import SwiftUI

struct ModelsView: View {
    @State private var models: [PollinationsModel] = PollinationsClient.workingModels
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    Spacer()
                    ProgressView("Loading models...")
                    Spacer()
                } else {
                    List(models) { model in
                        ModelRow(model: model)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Models")
            .task {
                await loadModels()
            }
            .refreshable {
                await loadModels()
            }
        }
    }

    private func loadModels() async {
        isLoading = models.isEmpty
        do {
            let fetched = try await PollinationsClient.shared.fetchModels()
            if !fetched.isEmpty {
                models = fetched
            }
        } catch {
            NSLog("[Models] Using cached models: \(error)")
        }
        isLoading = false
    }
}

private struct ModelRow: View {
    let model: PollinationsModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(model.title)
                    .font(.headline)
                Spacer()
                Text("Free")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.green)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            Text(model.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            HStack {
                ForEach(model.outputModalities, id: \.self) { mod in
                    Text(mod)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.quaternary)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ModelsView()
}
