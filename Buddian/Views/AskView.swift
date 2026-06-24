import SwiftUI

struct AskView: View {
    @State private var prompt = ""
    @State private var selectedModel: AIModel? = AIModel.sampleModels.first
    @State private var selectedTier: InferenceTier = .standard

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
                Section("Tier") {
                    Picker("Inference Tier", selection: $selectedTier) {
                        ForEach(InferenceTier.allCases, id: \.self) { tier in
                            Text(tier.rawValue).tag(tier)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Model") {
                    ForEach(availableModels) { model in
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
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }

                Section("Prompt") {
                    TextEditor(text: $prompt)
                        .frame(minHeight: 100)
                }

                Section {
                    HStack {
                        Text("Estimated Cost")
                        Spacer()
                        Text(String(format: "$%.3f", estimatedCost))
                            .foregroundStyle(.green)
                    }
                }

                Section {
                    PrimaryButton(title: "Generate", action: {}, isDisabled: isGenerateDisabled)
                }
            }
            .navigationTitle("Ask")
        }
    }

    private var availableModels: [AIModel] {
        AIModel.sampleModels.filter { $0.tier == selectedTier }
    }
}

#Preview {
    AskView()
}
