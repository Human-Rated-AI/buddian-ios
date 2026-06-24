import SwiftUI

struct LibraryView: View {
    @State private var generations: [Generation] = []

    var body: some View {
        NavigationStack {
            Group {
                if generations.isEmpty {
                    EmptyStateView(
                        icon: "photo.on.rectangle",
                        title: "No Generations Yet",
                        message: "Your generated images and videos will appear here."
                    )
                } else {
                    List {
                        ForEach(generations) { gen in
                            GenerationRow(generation: gen)
                        }
                    }
                }
            }
            .navigationTitle("Library")
            .refreshable {
                // TODO: Fetch generations from API
            }
        }
    }
}

struct Generation: Identifiable {
    let id: String
    let prompt: String
    let modelName: String
    let date: Date
    let status: GenerationStatus
}

enum GenerationStatus: String {
    case completed = "Completed"
    case processing = "Processing"
    case failed = "Failed"

    var color: Color {
        switch self {
        case .completed: return .green
        case .processing: return .orange
        case .failed: return .red
        }
    }
}

private struct GenerationRow: View {
    let generation: Generation

    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.quaternary)
                .frame(width: 60, height: 60)
                .overlay {
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                }

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
                    Text(generation.date, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(generation.status.rawValue)
                    .font(.caption)
                    .foregroundStyle(generation.status.color)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    LibraryView()
}
