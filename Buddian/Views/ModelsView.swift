import SwiftUI

struct ModelsView: View {
    let models = AIModel.allModels

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
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.badgeBackground(for: model.type))
                    .foregroundStyle(AppTheme.badgeForeground(for: model.type))
                    .clipShape(Capsule())
            }
            Text(model.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(String(format: "$%.3f %@", model.pricePerUnit, model.unitLabel))
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ModelsView()
}
