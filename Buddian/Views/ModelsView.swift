import SwiftUI

struct ModelsView: View {
    @ObservedObject var modelCache = ModelCache.shared
    @State private var filter: ModalityFilter = .all

    enum ModalityFilter: String, CaseIterable {
        case all = "All"
        case image = "Image"
        case video = "Video"
    }

    var body: some View {
        NavigationStack {
            Group {
                if modelCache.models.isEmpty && modelCache.isLoading {
                    ProgressView("Loading models...")
                } else {
                    List {
                        Section {
                            Picker("Filter", selection: $filter) {
                                ForEach(ModalityFilter.allCases, id: \.self) { f in
                                    Text(f.rawValue).tag(f)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        Section {
                            ForEach(filteredModels) { model in
                                ModelRow(model: model)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Models")
            .task {
                await modelCache.refresh()
            }
            .refreshable {
                await modelCache.refresh()
            }
        }
    }

    private var filteredModels: [RemoteModel] {
        let all = modelCache.models.filter { $0.type == "image_generation" || $0.type == "video_generation" }
        switch filter {
        case .all: return all
        case .image: return all.filter { $0.outputModalities.contains("image") }
        case .video: return all.filter { $0.outputModalities.contains("video") }
        }
    }
}

private struct ModelRow: View {
    let model: RemoteModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(model.name)
                    .font(.headline)
                Spacer()
                if model.isFree {
                    Text("Free")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.green)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                } else if let price = model.userPricing?.displayPrice {
                    Text(price)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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
    ModelsView().environmentObject(ModelCache.shared)
}
