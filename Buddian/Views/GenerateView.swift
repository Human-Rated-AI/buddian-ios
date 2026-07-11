import SwiftUI

struct GenerateView: View {
    @State private var models: [PollinationsModel] = PollinationsClient.workingModels
    @State private var selectedModel: PollinationsModel? = PollinationsClient.workingModels.first
    @State private var prompt = ""
    @State private var isGenerating = false
    @State private var generatedImageData: Data?
    @State private var generationError: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Model") {
                    ForEach(models) { model in
                        Button {
                            selectedModel = model
                            generatedImageData = nil
                        } label: {
                            modelLabel(model)
                        }
                        .buttonStyle(.plain)
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
                await refreshModels()
            }
        }
    }

    private func modelLabel(_ model: PollinationsModel) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(model.title)
                    .foregroundStyle(.primary)
                Text("Free")
                    .font(.caption)
                    .foregroundStyle(.green)
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

    private func refreshModels() async {
        do {
            let fetched = try await PollinationsClient.shared.fetchModels()
            if !fetched.isEmpty {
                models = fetched
                if selectedModel == nil {
                    selectedModel = fetched.first
                }
            }
        } catch {
            NSLog("[Generate] Using cached models: \(error)")
        }
    }

    private func submitGeneration() {
        guard let model = selectedModel else { return }
        isGenerating = true
        generationError = nil
        generatedImageData = nil

        Task {
            do {
                let data = try await PollinationsClient.shared.generateImage(
                    prompt: prompt,
                    model: model.name,
                    width: 1024,
                    height: 1024
                )
                generatedImageData = data
                HapticManager.notification(.success)

                let gen = LocalGeneration(
                    prompt: prompt,
                    modelName: model.title,
                    imageData: data
                )
                LocalStorage.saveGeneration(gen)

                NSLog("[Generate] Image received: \(data.count) bytes")
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
