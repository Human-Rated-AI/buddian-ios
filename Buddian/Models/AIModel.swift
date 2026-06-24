import Foundation

enum ModelType: String, CaseIterable, Codable {
    case image = "Image"
    case video = "Video"
}

struct AIModel: Identifiable, Codable, Sendable {
    let id: String
    let name: String
    let type: ModelType
    let pricePerUnit: Double
    let unitLabel: String
    let description: String

    var unitSuffix: String {
        switch type {
        case .image: return "image"
        case .video: return "s"
        }
    }
}

extension AIModel {
    static var allModels: [AIModel] {
        [
            AIModel(
                id: "stable-diffusion-xl",
                name: "Stable Diffusion XL",
                type: .image,
                pricePerUnit: 0.025,
                unitLabel: "per image",
                description: "High-quality image generation"
            ),
            AIModel(
                id: "dall-e-3",
                name: "DALL·E 3",
                type: .image,
                pricePerUnit: 0.04,
                unitLabel: "per image",
                description: "OpenAI's latest image model"
            ),
            AIModel(
                id: "flux-pro",
                name: "Flux Pro",
                type: .image,
                pricePerUnit: 0.03,
                unitLabel: "per image",
                description: "Fast, high-quality image generation"
            ),
            AIModel(
                id: "stable-video-diffusion",
                name: "Stable Video Diffusion",
                type: .video,
                pricePerUnit: 0.15,
                unitLabel: "per second of video",
                description: "Image-to-video generation (~5 sec clips)"
            ),
        ]
    }
}
