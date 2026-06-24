import Foundation

enum ModelType: String, CaseIterable, Codable {
    case image = "Image"
    case video = "Video"
}

enum InferenceTier: String, CaseIterable, Codable {
    case standard = "Standard"
    case confidential = "Confidential"
}

struct AIModel: Identifiable, Codable {
    let id: String
    let name: String
    let type: ModelType
    let tier: InferenceTier
    let pricePerUnit: Double
    let unitLabel: String
    let description: String
}

extension AIModel {
    static let sampleModels: [AIModel] = [
        AIModel(
            id: "stable-diffusion-xl",
            name: "Stable Diffusion XL",
            type: .image,
            tier: .standard,
            pricePerUnit: 0.025,
            unitLabel: "per image",
            description: "High-quality image generation"
        ),
        AIModel(
            id: "dall-e-3",
            name: "DALL·E 3",
            type: .image,
            tier: .standard,
            pricePerUnit: 0.04,
            unitLabel: "per image",
            description: "OpenAI's latest image model"
        ),
        AIModel(
            id: "flux-pro",
            name: "Flux Pro",
            type: .image,
            tier: .standard,
            pricePerUnit: 0.03,
            unitLabel: "per image",
            description: "Fast, high-quality image generation"
        ),
        AIModel(
            id: "stable-video-diffusion",
            name: "Stable Video Diffusion",
            type: .video,
            tier: .standard,
            pricePerUnit: 0.15,
            unitLabel: "per second",
            description: "Image-to-video generation"
        ),
        AIModel(
            id: "sdxl-confidential",
            name: "SDXL (Confidential)",
            type: .image,
            tier: .confidential,
            pricePerUnit: 0.05,
            unitLabel: "per image",
            description: "Encrypted inference via TEE"
        ),
        AIModel(
            id: "svd-confidential",
            name: "SVD (Confidential)",
            type: .video,
            tier: .confidential,
            pricePerUnit: 0.30,
            unitLabel: "per second",
            description: "Encrypted video generation via TEE"
        ),
    ]
}
