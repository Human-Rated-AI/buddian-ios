import Foundation

struct Generation: Codable, Identifiable {
    var id: String { jobId }
    let jobId: String
    let modelId: String
    let prompt: String
    let negativePrompt: String?
    let parameters: GenerationParameters?
    let status: String
    let statusDetail: String?
    let costEstimate: Double
    let costActual: Double
    let resultUrl: String?
    let resultMetadata: [String: AnyCodable]?
    let gpuSeconds: Double?
    let createdAt: String?
    let updatedAt: String?
    let completedAt: String?

    enum CodingKeys: String, CodingKey {
        case jobId = "job_id"
        case modelId = "model_id"
        case prompt
        case negativePrompt = "negative_prompt"
        case parameters
        case status
        case statusDetail = "status_detail"
        case costEstimate = "cost_estimate"
        case costActual = "cost_actual"
        case resultUrl = "result_url"
        case resultMetadata = "result_metadata"
        case gpuSeconds = "gpu_seconds"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case completedAt = "completed_at"
    }

    var resultDownloadURL: URL? {
        guard let jobID = Int(jobId) else { return nil }
        return URL(string: "https://api.buddian.com/generations/\(jobID)/result")
    }

    var statusColor: String {
        switch status {
        case "completed": return "green"
        case "processing", "queued": return "orange"
        case "failed": return "red"
        default: return "gray"
        }
    }
}

struct GenerationParameters: Codable {
    let width: Int?
    let height: Int?
    let steps: Int?
    let cfgScale: Double?
    let numImages: Int?
}

struct AnyCodable: Codable {
    let value: Any

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let string = value as? String {
            try container.encode(string)
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else {
            try container.encodeNil()
        }
    }
}
