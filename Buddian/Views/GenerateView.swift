import SwiftUI

struct GenerateView: View {
    @EnvironmentObject var modelCache: ModelCache
    @State private var isImage = true
    @State private var selectedModelID: String?
    @State private var prompt = ""
    @State private var isSubmitting = false
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
                    PrimaryButton(title: "Generate", action: {}, isDisabled: !isReady())
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
                    .foregroundStyle(.accentColor)
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
            selectedModelID = id
            if all.first(where: { $0.id == id })?.outputModalities.contains("video") == true {
                isImage = false
            }
        }
        if selectedModelID == nil {
            selectedModelID = modelsForCurrentTask(all).first?.id
        }
    }
}

#Preview {
    GenerateView().environmentObject(ModelCache.shared)
}
