import SwiftUI

struct ModelsView: View {
    let models = AIModel.sampleModels

    var body: some View {
        NavigationStack {
            List {
                ForEach(models) { model in
                    ModelRow(model: model)
                }
            }
            .navigationTitle("Models")
            .refreshable {
                // TODO: Fetch models from API
            }
        }
    }
}

private struct ModelRow: View {
    let model: AIModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(model.name)
                    .font(.headline)
                Spacer()
                Text(model.type.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.blue.opacity(0.1))
                    .clipShape(Capsule())
            }
            Text(model.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(String(format: "$%.3f %@", model.pricePerUnit, model.unitLabel))
                .font(.caption)
                .foregroundStyle(.green)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ModelsView()
}
