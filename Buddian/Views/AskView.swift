import SwiftUI

struct AskView: View {
    @State private var prompt = ""
    @State private var selectedModel: AIModel?

    private var estimatedCost: Double {
        guard let model = selectedModel else { return 0 }
        return model.pricePerUnit
    }

    private var isGenerateDisabled: Bool {
        prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedModel == nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(AIModel.allModels) { model in
                        Button {
                            selectedModel = model
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(model.name)
                                        .foregroundStyle(.primary)
                                    Text(model.type.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if selectedModel?.id == model.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Model")
                }

                Section {
                    TextEditor(text: $prompt)
                        .frame(minHeight: 100)
                } header: {
                    Text("Prompt")
                }

                Section {
                    HStack {
                        Text("Estimated Cost")
                        Spacer()
                        Text(String(format: "$%.3f", estimatedCost))
                            .fontWeight(.medium)
                    }
                }

                Section {
                    PrimaryButton(title: "Generate", action: {}, isDisabled: isGenerateDisabled)
                }
            }
            .navigationTitle("Ask")
            .dismissKeyboardOnTap()
        }
    }
}

#Preview {
    AskView()
}
