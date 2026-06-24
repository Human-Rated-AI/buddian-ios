import SwiftUI

enum AppTheme {
    static func badgeBackground(for type: ModelType) -> Color {
        switch type {
        case .image: return .blue
        case .video: return .teal
        }
    }

    static func badgeForeground(for type: ModelType) -> Color {
        .white
    }
}

struct KeyboardDismissal: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil,
                    from: nil,
                    for: nil
                )
            }
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(KeyboardDismissal())
    }
}
