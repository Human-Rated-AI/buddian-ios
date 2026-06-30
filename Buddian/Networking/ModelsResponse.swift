import Foundation

struct ModelsResponse: Codable {
    let data: [RemoteModel]
}

struct RemoteModel: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let type: String?
    let status: String?
    let availabilityReason: String?
    let standardTee: Bool
    let inputModalities: [String]
    let outputModalities: [String]
    let contextLength: Int?
    let maxOutputLength: Int?
    let supportedParameters: [String]?
    let providers: [String]?
    let userPricing: UserPricing?
    let defaultWidth: Int?
    let defaultHeight: Int?
    let defaultSteps: Int?
    let defaultCfgScale: Double?

    enum CodingKeys: String, CodingKey {
        case id, name, description, type, status, providers
        case availabilityReason = "availability_reason"
        case standardTee = "standard_tee"
        case inputModalities = "input_modalities"
        case outputModalities = "output_modalities"
        case contextLength = "context_length"
        case maxOutputLength = "max_output_length"
        case supportedParameters = "supported_parameters"
        case userPricing = "user_pricing"
        case defaultWidth = "default_width"
        case defaultHeight = "default_height"
        case defaultSteps = "default_steps"
        case defaultCfgScale = "default_cfg_scale"
    }

    var isFree: Bool { status == "free" }
    var isAvailable: Bool { status == "available" || status == "free" }
}

struct UserPricing: Codable {
    let currency: String
    let promptPer1mTokens: String?
    let completionPer1mTokens: String?
    let perImage: String?
    let perSecond: String?

    enum CodingKeys: String, CodingKey {
        case currency
        case promptPer1mTokens = "prompt_per_1m_tokens"
        case completionPer1mTokens = "completion_per_1m_tokens"
        case perImage = "per_image"
        case perSecond = "per_second"
    }

    var displayPrice: String? {
        if let perImage {
            return "$\(formatPrice(perImage))/image"
        } else if let perSecond {
            return "$\(formatPrice(perSecond, decimals: 3))/s"
        } else if let input = promptPer1mTokens, let output = completionPer1mTokens {
            return "In: $\(formatPrice(input)) · Out: $\(formatPrice(output))/1M"
        }
        return nil
    }

    private func formatPrice(_ s: String, decimals: Int = 2) -> String {
        guard let v = Double(s) else { return s }
        return String(format: "%.\(decimals)f", v)
    }
}
