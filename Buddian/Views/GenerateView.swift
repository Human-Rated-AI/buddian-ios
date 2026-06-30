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
                }

                modelPicker

                Section("Prompt") {
                    TextEditor(text: $prompt).frame(minHeight: 80)
                }

                costRow

                Section {
                    PrimaryButton(title: "Generate", action: {}, isDisabled: !canSubmit())
                }
            }
            .navigationTitle("Generate")
            .onAppear(perform: setupDefaults)
        }
    }

    private func canSubmit() -> Bool {
        !prompt.trimmingCharacters(in: .whitespaces).isEmpty && selectedModelID != nil && !isSubmitting
    }

    private func setupDefaults() {
        if let id = preselectedModelID {
            selectedModelID = id
            if modelCache.models.first(where: { $0.id == id })?.outputModalities.contains("video") == true {
                isImage = false
            }
        }
        if selectedModelID == nil {
            pickFirst()
        }
    }

    private func pickFirst() {
        let mod = isImage ? "image" : "video"
        selectedModelID = modelCache.models
            .first { $0.outputModalities.contains(mod) }?.id
    }

    private var modelPicker: some View {
        Section("Model") {
            let mod = isImage ? "image" : "video"
            let filtered = modelCache.models.filter { $0.outputModalities.contains(mod) }
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
    }

    private var costRow: some View {
        Section {
            HStack {
                Text("Estimated Cost")
                Spacer()
                Text(costString()).fontWeight(.medium)
            }
        }
    }

    private func costString() -> String {
        let mod = isImage ? "image" : "video"
        let filtered = modelCache.models.filter { $0.outputModalities.contains(mod) }
        guard let m = filtered.first(where: { $0.id == selectedModelID }),
              let p = m.userPricing else { return "N/A" }
        if let img = p.perImage { return "$\(img)/image" }
        if let sec = p.perSecond { return "$\(sec)/s" }
        return "N/A"
    }
}

#Preview {
    GenerateView().environmentObject(ModelCache.shared)
}
