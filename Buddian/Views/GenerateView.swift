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
        NavigationStack {
            Form {
                Section("What do you want to create?") {
                    Picker("Task", selection: $isImage) {
                        Text("Image").tag(true)
                        Text("Video").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: isImage) { _ in selectFirstModel() }
                }

                Section("Model") {
                    modelRows
                }

                Section("Prompt") {
                    TextEditor(text: $prompt).frame(minHeight: 80)
                }

                Section {
                    HStack {
                        Text("Estimated Cost")
                        Spacer()
                        Text(costString()).fontWeight(.medium)
                    }
                }

                Section {
                    PrimaryButton(title: "Generate", action: {}, isDisabled: !ready())
                }
            }
            .navigationTitle("Generate")
            .onAppear(perform: setupDefaults)
        }
    }

    private var modelRows: some View {
        ForEach(filteredModels()) { model in
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

    private func filteredModels() -> [RemoteModel] {
        let mod = isImage ? "image" : "video"
        return modelCache.models.filter { $0.outputModalities.contains(mod) }
    }

    private func selectFirstModel() {
        selectedModelID = filteredModels().first?.id
    }

    private func setupDefaults() {
        if let id = preselectedModelID {
            selectedModelID = id
            if modelCache.models.first(where: { $0.id == id })?.outputModalities.contains("video") == true {
                isImage = false
            }
        }
        if selectedModelID == nil {
            selectFirstModel()
        }
    }

    private func ready() -> Bool {
        !prompt.trimmingCharacters(in: .whitespaces).isEmpty && selectedModelID != nil && !isSubmitting
    }

    private func costString() -> String {
        guard let m = filteredModels().first(where: { $0.id == selectedModelID }),
              let p = m.userPricing else { return "N/A" }
        if let img = p.perImage { return "$\(img)/image" }
        if let sec = p.perSecond { return "$\(sec)/s" }
        return "N/A"
    }
}

#Preview {
    GenerateView().environmentObject(ModelCache.shared)
}
