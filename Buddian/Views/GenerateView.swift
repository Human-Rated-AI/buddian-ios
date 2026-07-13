import SwiftUI

struct GenerateView: View {
    @EnvironmentObject var modelCache: ModelCache
    @State private var isImage = true
    @State private var selectedModelID: String?
    @State private var prompt = ""
    @State private var isSubmitting = false
    @State private var isSetUp = false
    @State private var jobId: String?
    @State private var jobStatus: String?
    @State private var resultImageData: Data?
    @State private var errorMessage: String?
    @State private var isPolling = false
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
                        resetResult()
                    }
                }

                Section("Model") {
                    ForEach(modelsForCurrentTask(allModels)) { model in
                        Button { selectedModelID = model.id; resetResult() } label: {
                            modelLabel(model)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section("Prompt") {
                    TextEditor(text: $prompt)
                        .frame(minHeight: 80)
                        .onChange(of: prompt) { _ in
                            resetResult()
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

                if isPolling {
                    Section {
                        HStack {
                            ProgressView()
                            Text("Generating... (\(jobStatus ?? "queued"))")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if let error = errorMessage {
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

                if let imageData = resultImageData, let uiImage = UIImage(data: imageData) {
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
        !prompt.trimmingCharacters(in: .whitespaces).isEmpty
            && selectedModelID != nil
            && !isSubmitting
            && !isPolling
    }

    private func resetResult() {
        jobId = nil
        jobStatus = nil
        resultImageData = nil
        errorMessage = nil
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
        isSubmitting = true
        errorMessage = nil
        resultImageData = nil

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
                jobId = response.jobId
                NSLog("[Generate] Job submitted: \(response.jobId), status: \(response.status)")
                prompt = ""
                await pollJobStatus(jobId: response.jobId)
            } catch {
                errorMessage = error.localizedDescription
                NSLog("[Generate] Submit failed: \(error)")
            }
            isSubmitting = false
        }
    }

    private func pollJobStatus(jobId: String) async {
        isPolling = true
        defer { isPolling = false }

        let maxAttempts = 120
        for _ in 0..<maxAttempts {
            do {
                let gen = try await APIClient.shared.fetchGeneration(jobId: jobId)
                jobStatus = gen.status

                if gen.status == "completed" {
                    await downloadResult(jobId: jobId)
                    return
                } else if gen.status == "failed" {
                    errorMessage = gen.statusDetail ?? "Generation failed"
                    return
                }

                try await Task.sleep(nanoseconds: 5_000_000_000)
            } catch {
                errorMessage = error.localizedDescription
                return
            }
        }
        errorMessage = "Generation timed out"
    }

    private func downloadResult(jobId: String) async {
        do {
            let data = try await APIClient.shared.downloadResult(jobId: jobId)
            resultImageData = data
            NSLog("[Generate] Result downloaded: \(data.count) bytes")
        } catch {
            errorMessage = "Failed to download result: \(error.localizedDescription)"
            NSLog("[Generate] Download failed: \(error)")
        }
    }
}

#Preview {
    GenerateView().environmentObject(ModelCache.shared)
}
