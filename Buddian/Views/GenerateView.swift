import SwiftUI

struct GenerateView: View {
    @EnvironmentObject var modelCache: ModelCache
    @State private var isImage = true
    @State private var selectedModelID: String?
    @State private var prompt = ""
    @State private var isSubmitting = false
    @State private var isSetUp = false
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
                    }
                }

                Section("Model") {
                    ForEach(modelsForCurrentTask(allModels)) { model in
                        Button { selectedModelID = model.id } label: {
                            modelLabel(model)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section("Prompt") {
                    TextEditor(text: $prompt).frame(minHeight: 80)
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
        !prompt.trimmingCharacters(in: .whitespaces).isEmpty && selectedModelID != nil && !isSubmitting
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
        isSubmitting = true
        Task {
            do {
                let model = modelCache.models.first(where: { $0.id == modelID })
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
                prompt = ""
            } catch {
                NSLog("[Generate] Submit failed: \(error)")
            }
            isSubmitting = false
        }
    }
}

#Preview {
    GenerateView().environmentObject(ModelCache.shared)
}
