import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isDisabled: Bool = false

    var body: some View {
        Button(action: {
            HapticManager.impact(.medium)
            action()
        }) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isDisabled ? Color.gray.opacity(0.3) : Color.accentColor)
                .foregroundStyle(isDisabled ? Color.secondary : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isDisabled)
    }
}

#Preview {
    VStack {
        PrimaryButton(title: "Generate", action: {})
        PrimaryButton(title: "Disabled", action: {}, isDisabled: true)
    }
    .padding()
}
