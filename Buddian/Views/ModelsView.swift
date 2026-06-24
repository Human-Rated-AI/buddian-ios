import SwiftUI

struct ModelsView: View {
    @State private var models: [RemoteModel] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedFilter: ModelFilter = .all

    enum ModelFilter: String, CaseIterable {
        case all = "All"
        case text = "Text"
        case image = "Image"
        case video = "Video"
    }

    private var filteredModels: [RemoteModel] {
        switch selectedFilter {
        case .all:
            return models
        case .text:
            return models.filter { $0.outputModalities.contains("text") }
        case .image:
            return models.filter { $0.outputModalities.contains("image") }
        case .video:
            return models.filter { $0.outputModalities.contains("video") }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar

                Divider()

                if models.isEmpty && isLoading {
                    Spacer()
                    ProgressView("Loading models...")
                    Spacer()
                } else if models.isEmpty, let error = errorMessage {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.orange)
                        Text("Failed to load models")
                            .font(.headline)
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task { await loadModels() }
                        }
                    }
                    .padding()
                    Spacer()
                } else if models.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "cpu",
                        title: "No Models Available",
                        message: "Check back later for available models."
                    )
                    Spacer()
                } else {
                    List(filteredModels) { model in
                        RemoteModelRow(model: model)
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

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ModelFilter.allCases, id: \.self) { filter in
                    Button {
                        selectedFilter = filter
                    } label: {
                        Text(filter.rawValue)
                            .font(.subheadline)
                            .fontWeight(selectedFilter == filter ? .semibold : .regular)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedFilter == filter ? Color.accentColor : Color(.systemGray5))
                            .foregroundStyle(selectedFilter == filter ? .white : .primary)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }

    private func loadModels() async {
        isLoading = models.isEmpty
        errorMessage = nil
        do {
            models = try await APIClient.shared.fetchModels()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

private struct RemoteModelRow: View {
    let model: RemoteModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(model.name)
                    .font(.headline)
                Spacer()
                if model.standardTee {
                    Text("TEE")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.orange)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
            Text(model.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            if let price = model.userPricing?.displayPrice {
                Text(price)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
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
