import SwiftUI

struct GenerateView: View {
    @EnvironmentObject var modelCache: ModelCache
    @State private var isImage = true
    @State private var selectedModelID: String?
    @State private var prompt = ""
    @State private var isSubmitting = false
    @State private var isSetUp = false
    @State private var generatedImageData: Data?
    @State private var generationError: String?
    @State private var isGenerating = false
    private let preselectedModelID: String?

    init(preselectedModelID: String? = nil) {
        self.preselectedModelID = preselectedModelID
    }

    var body: some View {
        let allModels = modelCache.models
        NavigationStack {
            Form {
                Section("What do you want to create?") {
                    Picker("Task", selection: $isImage) {
                        Text("Image").tag(true)
                        Text("Video").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: isImage) { _ in
                        guard isSetUp else { return }
                        selectedModelID = modelsForCurrentTask(allModels).first?.id
                        generatedImageData = nil
                    }
                }

                Section("Model") {
                    ForEach(modelsForCurrentTask(allModels)) { model in
                        Button { selectedModelID = model.id; generatedImageData = nil } label: {
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
                    HStack {
                        Text("Estimated Cost")
                        Spacer()
                        Text(priceForSelection(allModels)).fontWeight(.medium)
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
            .onAppear {
                setupDefaults(allModels)
            }
        }
    }

    private func modelsForCurrentTask(_ all: [RemoteModel]) -> [RemoteModel] {
        let mod = isImage ? "image" : "video"
        return all.filter { $0.outputModalities.contains(mod) }
    }

    private func modelLabel(_ model: RemoteModel) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(model.name).foregroundStyle(.primary)
                if let price = model.userPricing?.displayPrice {
                    Text(price).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            if selectedModelID == model.id {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.accentColor)
            }
        }
        .contentShape(Rectangle())
    }

    private func priceForSelection(_ all: [RemoteModel]) -> String {
        guard let m = modelsForCurrentTask(all).first(where: { $0.id == selectedModelID }),
              let p = m.userPricing else { return "N/A" }
        if let img = p.perImage { return "$\(img)/image" }
        if let sec = p.perSecond { return "$\(sec)/s" }
        return "N/A"
    }

    private func isReady() -> Bool {
        !prompt.trimmingCharacters(in: .whitespaces).isEmpty && selectedModelID != nil && !isSubmitting && !isGenerating
    }

    private func setupDefaults(_ all: [RemoteModel]) {
        if let id = preselectedModelID {
            if let model = all.first(where: { $0.id == id }) {
                isImage = !model.outputModalities.contains("video")
                selectedModelID = id
            }
        }
        if selectedModelID == nil {
            selectedModelID = modelsForCurrentTask(all).first?.id
        }
        isSetUp = true
    }

    private func submitGeneration() {
        guard let modelID = selectedModelID else { return }
        let model = modelCache.models.first(where: { $0.id == modelID })

        if modelID.hasPrefix("pollinations/") {
            generateViaPollinations(modelID: modelID, model: model)
        } else {
            generateViaQueue(modelID: modelID, model: model)
        }
    }

    private func generateViaPollinations(modelID: String, model: RemoteModel?) {
        let pollinationsModel = modelID.replacingOccurrences(of: "pollinations/", with: "")
        isGenerating = true
        isSubmitting = true
        generationError = nil
        generatedImageData = nil

        Task {
            do {
                let data = try await PollinationsClient.shared.generateImage(
                    prompt: prompt,
                    model: pollinationsModel,
                    width: model?.defaultWidth ?? 1024,
                    height: model?.defaultHeight ?? 1024
                )
                generatedImageData = data
                NSLog("[Generate] Pollinations image received: \(data.count) bytes")
            } catch {
                generationError = error.localizedDescription
                NSLog("[Generate] Pollinations failed: \(error)")
            }
            isGenerating = false
            isSubmitting = false
        }
    }

    private func generateViaQueue(modelID: String, model: RemoteModel?) {
        isSubmitting = true
        generationError = nil
        Task {
            do {
                let request = APIClient.GenerationSubmitRequest(
                    modelId: modelID,
                    prompt: prompt,
                    negativePrompt: nil,
                    width: model?.defaultWidth,
                    height: model?.defaultHeight,
                    steps: model?.defaultSteps,
                    cfgScale: model?.defaultCfgScale,
                    numImages: 1
                )
                let response = try await APIClient.shared.submitGeneration(request)
                NSLog("[Generate] Job submitted: \(response.jobId), status: \(response.status)")
                generationError = "Job queued: \(response.jobId). Check Library for results."
                prompt = ""
            } catch {
                generationError = error.localizedDescription
                NSLog("[Generate] Submit failed: \(error)")
            }
            isSubmitting = false
        }
    }
}

#Preview {
    GenerateView().environmentObject(ModelCache.shared)
}
