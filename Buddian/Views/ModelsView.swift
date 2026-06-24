import SwiftUI

struct ModelsView: View {
    @State private var remoteModels: [RemoteModel] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

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
                    List(remoteModels) { model in
                        RemoteModelRow(model: model)
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
        VStack(alignment: .leading, spacing: 4) {
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
                Text("Input: $\(pricing.promptPer1mTokens)/1M tokens · Output: $\(pricing.completionPer1mTokens)/1M tokens")
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
