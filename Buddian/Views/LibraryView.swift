import SwiftUI

struct LibraryView: View {
    @State private var generations: [Generation] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

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
                        GenerationRow(generation: gen)
                    }
                }
            }
            .navigationTitle("Library")
            .refreshable { await loadGenerations() }
            .task { await loadGenerations() }
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

struct GenerationRow: View {
    let generation: Generation

    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.quaternary)
                .frame(width: 60, height: 60)
                .overlay {
                    if generation.status == "completed" {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else if generation.status == "processing" || generation.status == "queued" {
                        ProgressView()
                    } else {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
                }

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
