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

    private var modality: String { taskIndex == 0 ? "image" : "video" }

    private var models: [RemoteModel] {
        modelCache.models.filter { $0.outputModalities.contains(modality) }
    }

    private var costLabel: String {
        guard let m = models.first(where: { $0.id == selectedModelID }),
              let p = m.userPricing else { return "N/A" }
        if let img = p.perImage { return "$\(img)/image" }
        if let sec = p.perSecond { return "$\(sec)/s" }
        return "N/A"
    }

    private var canSubmit: Bool {
        !prompt.trimmingCharacters(in: .whitespaces).isEmpty && selectedModelID != nil && !isSubmitting
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("What do you want to create?") {
                    Picker("Task", selection: $taskIndex) {
                        Text("Image").tag(0)
                        Text("Video").tag(1)
                    }
                    .pickerStyle(.segmented)
                }

                modelList

                Section("Prompt") {
                    TextEditor(text: $prompt).frame(minHeight: 80)
                }

                Section {
                    HStack {
                        Text("Estimated Cost")
                        Spacer()
                        Text(costLabel).fontWeight(.medium)
                    }
                }

                Section {
                    PrimaryButton(title: "Generate", action: doSubmit, isDisabled: !canSubmit)
                }
            }
            .navigationTitle("Generate")
            .onChange(of: taskIndex) { _ in
                selectedModelID = models.first?.id
            }
            .onAppear {
                if let id = preselectedModelID,
                   let m = modelCache.models.first(where: { $0.id == id }),
                   m.outputModalities.contains("video") {
                    taskIndex = 1
                }
                if selectedModelID == nil {
                    selectedModelID = models.first?.id
                }
            }
        }
    }

    @ViewBuilder
    private var modelList: some View {
        Section("Model") {
            ForEach(models) { model in
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

    private func doSubmit() {
        guard let id = selectedModelID else { return }
        isSubmitting = true
        NSLog("[Generate] model=\(id)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { isSubmitting = false }
    }
}

#Preview {
    GenerateView().environmentObject(ModelCache.shared)
}
