import SwiftUI

struct GenerateView: View {
    @EnvironmentObject var modelCache: ModelCache
    @State private var selectedTask: TaskType = .image
    @State private var selectedModelID: String?
    @State private var prompt = ""
    @State private var isSubmitting = false
    private let preselectedModelID: String?

    init(preselectedModelID: String? = nil) {
        self.preselectedModelID = preselectedModelID
        if let modelID = preselectedModelID {
            _selectedModelID = State(initialValue: modelID)
        }
    }

    enum TaskType: String, CaseIterable {
        case image = "Image"
        case video = "Video"
    }

    private var availableModels: [RemoteModel] {
        modelCache.models.filter { model in
            switch selectedTask {
            case .image: return model.outputModalities.contains("image")
            case .video: return model.outputModalities.contains("video")
            }
        }
    }

    private var selectedModel: RemoteModel? {
        availableModels.first { $0.id == selectedModelID }
    }

    private var estimatedCost: String {
        guard let model = selectedModel else { return "$0.00" }
        if let perImage = model.userPricing?.perImage {
            return "$\(perImage)/image"
        } else if let perSecond = model.userPricing?.perSecond {
            return "$\(perSecond)/s"
        }
        return "Pricing unavailable"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("What do you want to create?") {
                    Picker("Task", selection: $selectedTask) {
                        ForEach(TaskType.allCases, id: \.self) { task in
                            Text(task.rawValue).tag(task)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedTask) { _ in
                        selectedModelID = availableModels.first?.id
                    }
                }

                Section("Model") {
                    if availableModels.isEmpty {
                        Text("No models available")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(availableModels) { model in
                            Button {
                                selectedModelID = model.id
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(model.name)
                                            .foregroundStyle(.primary)
                                        if let price = model.userPricing?.displayPrice {
                                            Text(price)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
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

                Section("Prompt") {
                    TextEditor(text: $prompt)
                        .frame(minHeight: 80)
                }

                Section {
                    HStack {
                        Text("Estimated Cost")
                        Spacer()
                        Text(estimatedCost)
                            .fontWeight(.medium)
                    }
                }

                Section {
                    PrimaryButton(title: "Generate", action: submitGeneration, isDisabled: prompt.trimmingCharacters(in: .whitespaces).isEmpty || selectedModelID == nil || isSubmitting)
                }
            }
            .navigationTitle("Generate")
            .onChange(of: selectedTask) { _ in
                if selectedModelID == nil || !availableModels.contains(where: { $0.id == selectedModelID }) {
                    selectedModelID = availableModels.first?.id
                }
            }
            .onAppear {
                if let modelID = preselectedModelID,
                   let model = modelCache.models.first(where: { $0.id == modelID }) {
                    if model.outputModalities.contains("video") {
                        selectedTask = .video
                    }
                    selectedModelID = modelID
                } else if selectedModelID == nil {
                    selectedModelID = availableModels.first?.id
                }
            }
        }
    }

    private func submitGeneration() {
        guard let modelID = selectedModelID else { return }
        isSubmitting = true
        NSLog("[Generate] Submitting: model=\(modelID), prompt=\(prompt.prefix(50))...")
        // TODO: POST /generations with model_id, prompt
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isSubmitting = false
        }
    }
}

#Preview {
    GenerateView()
        .environmentObject(ModelCache.shared)
}
