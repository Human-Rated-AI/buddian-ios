import SwiftUI

struct GenerateView: View {
    @EnvironmentObject var modelCache: ModelCache
    @State private var taskIndex = 0
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

    var body: some View {
        let allModels = modelCache.models
        let modality = taskIndex == 0 ? "image" : "video"
        let filtered = allModels.filter { $0.outputModalities.contains(modality) }
        let sel = filtered.first(where: { $0.id == selectedModelID })
        let cost: String = {
            guard let p = sel?.userPricing else { return "N/A" }
            if let img = p.perImage { return "$\(img)/image" }
            if let sec = p.perSecond { return "$\(sec)/s" }
            return "N/A"
        }()
        let ok = !prompt.trimmingCharacters(in: .whitespaces).isEmpty && selectedModelID != nil && !isSubmitting

        NavigationStack {
            Form {
                Section("What do you want to create?") {
                    Picker("Task", selection: $taskIndex) {
                        Text("Image").tag(0)
                        Text("Video").tag(1)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Model") {
                    ForEach(filtered) { model in
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

                Section("Prompt") {
                    TextEditor(text: $prompt).frame(minHeight: 80)
                }

                Section {
                    HStack {
                        Text("Estimated Cost")
                        Spacer()
                        Text(cost).fontWeight(.medium)
                    }
                }

                Section {
                    PrimaryButton(title: "Generate", action: {}, isDisabled: !ok)
                }
            }
            .navigationTitle("Generate")
            .onChange(of: taskIndex) { _ in
                let mod = taskIndex == 0 ? "image" : "video"
                selectedModelID = modelCache.models
                    .first { $0.outputModalities.contains(mod) }?.id
            }
            .onAppear {
                if let id = preselectedModelID {
                    selectedModelID = id
                    if modelCache.models.first(where: { $0.id == id })?.outputModalities.contains("video") == true {
                        taskIndex = 1
                    }
                } else if selectedModelID == nil {
                    let mod = taskIndex == 0 ? "image" : "video"
                    selectedModelID = modelCache.models
                        .first { $0.outputModalities.contains(mod) }?.id
                }
            }
        }
    }
}

#Preview {
    GenerateView().environmentObject(ModelCache.shared)
}
