import Foundation

struct ModelsResponse: Codable {
    let data: [RemoteModel]
}

struct RemoteModel: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let standardTee: Bool
    let inputModalities: [String]
    let outputModalities: [String]
    let contextLength: Int
    let maxOutputLength: Int
    let supportedParameters: [String]
    let providers: [String]
    let userPricing: UserPricing?

    enum CodingKeys: String, CodingKey {
        case id, name, description
        case standardTee = "standard_tee"
        case inputModalities = "input_modalities"
        case outputModalities = "output_modalities"
        case contextLength = "context_length"
        case maxOutputLength = "max_output_length"
        case supportedParameters = "supported_parameters"
        case providers
        case userPricing = "user_pricing"
    }
}

struct UserPricing: Codable {
    let currency: String
    let promptPer1mTokens: String
    let completionPer1mTokens: String

    enum CodingKeys: String, CodingKey {
        case currency
        case promptPer1mTokens = "prompt_per_1m_tokens"
        case completionPer1mTokens = "completion_per_1m_tokens"
    }
}
