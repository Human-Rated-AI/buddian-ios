import SwiftUI

struct LibraryView: View {
    @State private var generations: [Generation] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedGeneration: Generation?

    var body: some View {
        NavigationStack {
            Group {
                if generations.isEmpty && isLoading {
                    ProgressView("Loading generations...")
                } else if generations.isEmpty, let error = errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.orange)
                        Text("Failed to load")
                            .font(.headline)
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("Retry") { Task { await loadGenerations() } }
                    }
                } else if generations.isEmpty {
                    EmptyStateView(
                        icon: "photo.on.rectangle",
                        title: "No Generations Yet",
                        message: "Your generated images and videos will appear here."
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
            .refreshable { await loadGenerations() }
            .task { await loadGenerations() }
            .sheet(item: $selectedGeneration) { gen in
                GenerationDetailView(generation: gen)
            }
        }
    }

    private func loadGenerations() async {
        isLoading = generations.isEmpty
        errorMessage = nil
        do {
            generations = try await APIClient.shared.fetchGenerations()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct GenerationDetailView: View {
    let generation: Generation
    @State private var imageData: Data?
    @State private var isLoadingImage = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let data = imageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(12)
                    } else if generation.status == "completed" {
                        ProgressView("Loading image...")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.quaternary)
                            .frame(height: 300)
                            .overlay {
                                VStack(spacing: 8) {
                                    Image(systemName: generation.status == "processing" || generation.status == "queued" ? "hourglass" : "photo")
                                        .font(.largeTitle)
                                        .foregroundStyle(.secondary)
                                    Text(generation.status.capitalized)
                                        .font(.headline)
                                }
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
                            Text(generation.modelId.split(separator: "/").last.map(String.init) ?? generation.modelId)
                                .font(.subheadline)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Cost")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(String(format: "$%.4f", generation.costActual))
                                .font(.subheadline)
                        }
                    }

                    if let params = generation.parameters {
                        Divider()
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Parameters")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack {
                                if let w = params.width, let h = params.height {
                                    Text("\(w)×\(h)")
                                }
                                if let steps = params.steps {
                                    Text("· \(steps) steps")
                                }
                                if let cfg = params.cfgScale {
                                    Text("· CFG \(cfg)")
                                }
                            }
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
                    if let data = imageData {
                        Button {
                            shareImage(data: data)
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .task {
                await loadImage()
            }
        }
    }

    private func loadImage() async {
        guard generation.status == "completed", let url = generation.resultDownloadURL else { return }
        isLoadingImage = true
        do {
            imageData = try await APIClient.shared.downloadResult(jobId: generation.jobId)
        } catch {
            NSLog("[Library] Failed to load image: \(error)")
        }
        isLoadingImage = false
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
    let generation: Generation

    var body: some View {
        HStack {
            thumbnail

            VStack(alignment: .leading, spacing: 4) {
                Text(generation.prompt)
                    .font(.headline)
                    .lineLimit(2)
                HStack {
                    Text(generation.modelId.split(separator: "/").last.map(String.init) ?? generation.modelId)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if generation.costActual > 0 {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text(String(format: "$%.4f", generation.costActual))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    Text(generation.status)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if generation.status == "completed", let url = generation.resultDownloadURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    placeholderIcon(systemName: "photo.badge.exclamationmark")
                case .empty:
                    ProgressView()
                        .frame(width: 60, height: 60)
                @unknown default:
                    placeholderIcon(systemName: "photo")
                }
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            placeholderIcon(
                systemName: generation.status == "processing" || generation.status == "queued"
                    ? "hourglass" : "photo"
            )
        }
    }

    private func placeholderIcon(systemName: String) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(.quaternary)
            .frame(width: 60, height: 60)
            .overlay {
                if generation.status == "processing" || generation.status == "queued" {
                    ProgressView()
                } else {
                    Image(systemName: systemName)
                        .foregroundStyle(.secondary)
                }
            }
    }

    private var statusColor: Color {
        switch generation.status {
        case "completed": return .green
        case "processing", "queued": return .orange
        case "failed": return .red
        default: return .gray
        }
    }
}

#Preview {
    LibraryView()
}
