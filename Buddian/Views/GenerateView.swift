import SwiftUI

struct GenerateView: View {
    @State private var models: [PollinationsModel] = []
    @State private var selectedModel: PollinationsModel?
    @State private var prompt = ""
    @State private var isGenerating = false
    @State private var generatedImageData: Data?
    @State private var generationError: String?
    @State private var isLoadingModels = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Model") {
                    if isLoadingModels {
                        ProgressView("Loading models...")
                    } else {
                        ForEach(availableModels) { model in
                            Button {
                                selectedModel = model
                                generatedImageData = nil
                            } label: {
                                modelLabel(model)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("Prompt") {
                    TextEditor(text: $prompt)
                        .frame(minHeight: 80)
                        .onChange(of: prompt) { _ in
                            generatedImageData = nil
                        }
                }

                Section {
                    PrimaryButton(title: "Generate", action: submitGeneration, isDisabled: !isReady())
                }

                if isGenerating {
                    Section {
                        HStack {
                            ProgressView()
                            Text("Generating...")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if let error = generationError {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                            Text(error)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if let imageData = generatedImageData, let uiImage = UIImage(data: imageData) {
                    Section("Result") {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(12)
                    }
                }
            }
            .navigationTitle("Generate")
            .task {
                await loadModels()
            }
        }
    }

    private var availableModels: [PollinationsModel] {
        models.filter { $0.category == "image" || $0.category == "video" }
    }

    private func modelLabel(_ model: PollinationsModel) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(model.title)
                    .foregroundStyle(.primary)
                Text(model.category.capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if selectedModel?.id == model.id {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.accentColor)
            }
        }
        .contentShape(Rectangle())
    }

    private func isReady() -> Bool {
        !prompt.trimmingCharacters(in: .whitespaces).isEmpty && selectedModel != nil && !isGenerating
    }

    private func loadModels() async {
        isLoadingModels = true
        do {
            models = try await PollinationsClient.shared.fetchModels()
            if selectedModel == nil {
                selectedModel = availableModels.first
            }
        } catch {
            NSLog("[Generate] Failed to load models: \(error)")
        }
        isLoadingModels = false
    }

    private func submitGeneration() {
        guard let model = selectedModel else { return }
        isGenerating = true
        generationError = nil
        generatedImageData = nil

        Task {
            do {
                if model.category == "video" {
                    let data = try await PollinationsClient.shared.generateVideo(
                        prompt: prompt,
                        model: model.name
                    )
                    generatedImageData = data
                } else {
                    let data = try await PollinationsClient.shared.generateImage(
                        prompt: prompt,
                        model: model.name,
                        width: 1024,
                        height: 1024
                    )
                    generatedImageData = data
                }
                HapticManager.notification(.success)

                if let data = generatedImageData {
                    let gen = LocalGeneration(
                        prompt: prompt,
                        modelName: model.title,
                        imageData: data
                    )
                    LocalStorage.saveGeneration(gen)
                }

                NSLog("[Generate] Image received: \(generatedImageData?.count ?? 0) bytes")
            } catch {
                generationError = error.localizedDescription
                HapticManager.notification(.error)
                NSLog("[Generate] Failed: \(error)")
            }
            isGenerating = false
        }
    }
}

#Preview {
    GenerateView()
}
