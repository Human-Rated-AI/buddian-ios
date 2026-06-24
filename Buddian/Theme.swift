import SwiftUI

enum AppTheme {
    static let accentBlue = Color("AccentBlue", bundle: nil)
    static let successGreen = Color("SuccessGreen", bundle: nil)

    static let imageBadgeBackground = Color.blue
    static let imageBadgeForeground = Color.white

    static let videoBadgeBackground = Color.purple
    static let videoBadgeForeground = Color.white

    static let priceForeground = Color.green

    static func badgeBackground(for type: ModelType) -> Color {
        switch type {
        case .image: return imageBadgeBackground
        case .video: return videoBadgeBackground
        }
    }

    static func badgeForeground(for type: ModelType) -> Color {
        switch type {
        case .image: return imageBadgeForeground
        case .video: return videoBadgeForeground
        }
    }
}
