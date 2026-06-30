import SwiftUI

struct ModelsView: View {
    @EnvironmentObject var modelCache: ModelCache
    @State private var selectedFilter: ModelFilter = .all
    @State private var selectedModel: RemoteModel?
    @State private var showGenerate = false

    enum ModelFilter: String, CaseIterable {
        case all = "All"
        case text = "Text"
        case image = "Image"
        case video = "Video"
    }

    private var filteredModels: [RemoteModel] {
        switch selectedFilter {
        case .all: return modelCache.models
        case .text: return modelCache.models.filter { $0.outputModalities.contains("text") }
        case .image: return modelCache.models.filter { $0.outputModalities.contains("image") }
        case .video: return modelCache.models.filter { $0.outputModalities.contains("video") }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar
                Divider()

                if modelCache.models.isEmpty && modelCache.isLoading {
                    Spacer()
                    ProgressView("Loading models...")
                    Spacer()
                } else if modelCache.models.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.orange)
                        Text("Failed to load models")
                            .font(.headline)
                        Button("Retry") {
                            Task { await modelCache.refresh() }
                        }
                    }
                    Spacer()
                } else {
                    List(filteredModels) { model in
                        Button {
                            selectedModel = model
                            showGenerate = true
                        } label: {
                            ModelRow(model: model)
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Models")
            .background(
                NavigationLink("", isActive: $showGenerate) {
                    GenerateView(preselectedModelID: selectedModel?.id)
                }.hidden()
            )
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
}

struct ModelRow: View {
    let model: RemoteModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(model.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
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
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
        .environmentObject(ModelCache.shared)
}
