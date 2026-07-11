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
    @State private var submittedJobId: String?
    @State private var jobStatus: String?
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

                if let jobId = submittedJobId, let status = jobStatus {
                    Section("Job Status") {
                        HStack {
                            Circle()
                                .fill(status == "completed" ? .green : status == "failed" ? .red : .orange)
                                .frame(width: 10, height: 10)
                            Text(status.capitalized)
                            Spacer()
                            if status == "processing" || status == "queued" {
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }
                        Text("Job: \(jobId)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
                HapticManager.notification(.success)
                NSLog("[Generate] Pollinations image received: \(data.count) bytes")
            } catch {
                generationError = error.localizedDescription
                HapticManager.notification(.error)
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
                submittedJobId = response.jobId
                jobStatus = response.status
                prompt = ""
                isSubmitting = false
                await pollJobStatus(jobId: response.jobId)
            } catch {
                generationError = error.localizedDescription
                NSLog("[Generate] Submit failed: \(error)")
                isSubmitting = false
            }
        }
    }

    private func pollJobStatus(jobId: String) async {
        var attempts = 0
        let maxAttempts = 120

        while attempts < maxAttempts {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            attempts += 1

            do {
                let job = try await APIClient.shared.fetchGeneration(jobId: jobId)
                jobStatus = job.status

                if job.status == "completed" {
                    NSLog("[Generate] Job \(jobId) completed")
                    HapticManager.notification(.success)
                    if let url = job.resultDownloadURL {
                        let data = try await APIClient.shared.downloadResult(jobId: jobId)
                        generatedImageData = data
                    }
                    return
                } else if job.status == "failed" {
                    NSLog("[Generate] Job \(jobId) failed")
                    HapticManager.notification(.error)
                    generationError = job.statusDetail ?? "Generation failed"
                    return
                }
            } catch {
                NSLog("[Generate] Poll error: \(error)")
            }
        }
        generationError = "Job timed out after \(maxAttempts * 5) seconds"
    }
}

#Preview {
    GenerateView().environmentObject(ModelCache.shared)
}
