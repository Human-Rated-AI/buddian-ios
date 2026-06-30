import SwiftUI

struct GenerateView: View {
    @EnvironmentObject var modelCache: ModelCache
    @State private var selectedTask = "Image"
    @State private var selectedModelID: String?
    @State private var prompt = ""
    @State private var isSubmitting = false

    private let preselectedModelID: String?

    init(preselectedModelID: String? = nil) {
        self.preselectedModelID = preselectedModelID
        if let id = preselectedModelID {
            _selectedModelID = State(initialValue: id)
        }
    }

    private var availableModels: [RemoteModel] {
        let modality = selectedTask == "Image" ? "image" : "video"
        return modelCache.models.filter { $0.outputModalities.contains(modality) }
    }

    private var selectedModel: RemoteModel? {
        availableModels.first { $0.id == selectedModelID }
    }

    private var costLabel: String {
        guard let m = selectedModel else { return "$0.00" }
        if let p = m.userPricing?.perImage { return "$\(p)/image" }
        if let p = m.userPricing?.perSecond { return "$\(p)/s" }
        return "N/A"
    }

    private var canSubmit: Bool {
        !prompt.trimmingCharacters(in: .whitespaces).isEmpty && selectedModelID != nil && !isSubmitting
    }

    var body: some View {
        NavigationStack {
            Form {
                taskSection
                modelSection
                promptSection
                costSection
                submitSection
            }
            .navigationTitle("Generate")
            .onAppear(perform: selectDefault)
            .onChange(of: selectedTask) { _ in selectDefault() }
        }
    }

    private var taskSection: some View {
        Section("What do you want to create?") {
            Picker("Task", selection: $selectedTask) {
                Text("Image").tag("Image")
                Text("Video").tag("Video")
            }
            .pickerStyle(.segmented)
        }
    }

    private var modelSection: some View {
        Section("Model") {
            if availableModels.isEmpty {
                Text("No models available").foregroundStyle(.secondary)
            } else {
                ForEach(availableModels) { model in
                    Button { selectedModelID = model.id } label: {
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
                                    .foregroundStyle(.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var promptSection: some View {
        Section("Prompt") {
            TextEditor(text: $prompt).frame(minHeight: 80)
        }
    }

    private var costSection: some View {
        Section {
            HStack {
                Text("Estimated Cost")
                Spacer()
                Text(costLabel).fontWeight(.medium)
            }
        }
    }

    private var submitSection: some View {
        Section {
            PrimaryButton(title: "Generate", action: submitGeneration, isDisabled: !canSubmit)
        }
    }

    private func selectDefault() {
        if let id = preselectedModelID,
           let model = modelCache.models.first(where: { $0.id == id }),
           model.outputModalities.contains("video") {
            selectedTask = "Video"
        }
        if selectedModelID == nil || !availableModels.contains(where: { $0.id == selectedModelID }) {
            selectedModelID = availableModels.first?.id
        }
    }

    private func submitGeneration() {
        guard let modelID = selectedModelID else { return }
        isSubmitting = true
        NSLog("[Generate] model=\(modelID), prompt=\(prompt.prefix(50))...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { isSubmitting = false }
    }
}

#Preview {
    GenerateView().environmentObject(ModelCache.shared)
}
