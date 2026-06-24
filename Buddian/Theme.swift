import SwiftUI

enum AppTheme {
    static let brandBlue = Color(red: 0.1, green: 0.21, blue: 0.36)

    static func badgeBackground(for type: ModelType) -> Color {
        switch type {
        case .image: return .blue
        case .video: return .purple
        }
    }

    static func badgeForeground(for type: ModelType) -> Color {
        .white
    }

    static let priceForeground = Color.green
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
