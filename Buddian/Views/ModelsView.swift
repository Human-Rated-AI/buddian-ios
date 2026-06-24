import SwiftUI

struct ModelsView: View {
    @State private var remoteModels: [RemoteModel] = []
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
            return remoteModels
        case .text:
            return remoteModels.filter { $0.outputModalities.contains("text") }
        case .image:
            return remoteModels.filter { $0.outputModalities.contains("image") }
        case .video:
            return remoteModels.filter { $0.outputModalities.contains("video") }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading models...")
                } else if let error = errorMessage {
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
                } else if remoteModels.isEmpty {
                    EmptyStateView(
                        icon: "cpu",
                        title: "No Models Available",
                        message: "Check back later for available models."
                    )
                } else {
                    VStack(spacing: 0) {
                        filterBar
                        modelList
                    }
                }
            }
            .navigationTitle("Models")
            .refreshable {
                await loadModels()
            }
            .task {
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
    }

    private var modelList: some View {
        List(filteredModels) { model in
            RemoteModelRow(model: model)
        }
    }

    private func loadModels() async {
        isLoading = remoteModels.isEmpty
        errorMessage = nil
        do {
            remoteModels = try await APIClient.shared.fetchModels()
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
            if let pricing = model.userPricing {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Input: $\(formatPrice(pricing.promptPer1mTokens))/1M tokens")
                    Text("Output: $\(formatPrice(pricing.completionPer1mTokens))/1M tokens")
                }
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

    private func formatPrice(_ priceString: String) -> String {
        guard let price = Double(priceString) else { return priceString }
        return String(format: "%.2f", price)
    }
}

#Preview {
    ModelsView()
}
