import SwiftUI

struct LibraryView: View {
    @State private var generations: [LocalGeneration] = []
    @State private var selectedGeneration: LocalGeneration?

    var body: some View {
        NavigationStack {
            Group {
                if generations.isEmpty {
                    EmptyStateView(
                        icon: "photo.on.rectangle",
                        title: "No Generations Yet",
                        message: "Your generated images will appear here."
                    )
                } else {
                    List(generations) { gen in
                        Button {
                            selectedGeneration = gen
                        } label: {
                            GenerationRow(generation: gen)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Library")
            .onAppear {
                loadGenerations()
            }
            .sheet(item: $selectedGeneration) { gen in
                GenerationDetailView(generation: gen)
            }
        }
    }

    private func loadGenerations() {
        generations = LocalStorage.loadGenerations()
    }
}

struct LocalGeneration: Identifiable, Codable {
    let id: String
    let prompt: String
    let modelName: String
    let imageData: Data?
    let createdAt: Date

    init(id: String = UUID().uuidString, prompt: String, modelName: String, imageData: Data?, createdAt: Date = Date()) {
        self.id = id
        self.prompt = prompt
        self.modelName = modelName
        self.imageData = imageData
        self.createdAt = createdAt
    }
}

enum LocalStorage {
    private static let key = "generations"

    static func saveGeneration(_ gen: LocalGeneration) {
        var generations = loadGenerations()
        generations.insert(gen, at: 0)
        if let data = try? JSONEncoder().encode(generations) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func loadGenerations() -> [LocalGeneration] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let generations = try? JSONDecoder().decode([LocalGeneration].self, from: data) else {
            return []
        }
        return generations
    }
}

struct GenerationDetailView: View {
    let generation: LocalGeneration

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let data = generation.imageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(12)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.quaternary)
                            .frame(height: 300)
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                            }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Prompt")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(generation.prompt)
                            .font(.body)
                    }

                    Divider()

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Model")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(generation.modelName)
                                .font(.subheadline)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Created")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(generation.createdAt, style: .date)
                                .font(.subheadline)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Generation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if let data = generation.imageData {
                        Button {
                            shareImage(data: data)
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
    }

    private func shareImage(data: Data) {
        guard let uiImage = UIImage(data: data) else { return }
        let activityVC = UIActivityViewController(activityItems: [uiImage], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(activityVC, animated: true)
        }
    }
}

struct GenerationRow: View {
    let generation: LocalGeneration

    var body: some View {
        HStack {
            thumbnail

            VStack(alignment: .leading, spacing: 4) {
                Text(generation.prompt)
                    .font(.headline)
                    .lineLimit(2)
                HStack {
                    Text(generation.modelName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text(generation.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let data = generation.imageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(.quaternary)
                .frame(width: 60, height: 60)
                .overlay {
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                }
        }
    }
}

#Preview {
    LibraryView()
}
