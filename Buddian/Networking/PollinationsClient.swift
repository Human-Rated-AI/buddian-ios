import Foundation

enum PollinationsError: Error, LocalizedError {
    case serviceDown
    case invalidImage
    case timeout

    var errorDescription: String? {
        switch self {
        case .serviceDown: return "Pollinations.ai is temporarily unavailable"
        case .invalidImage: return "Received invalid image data"
        case .timeout: return "Image generation timed out"
        }
    }
}

struct PollinationsModel: Codable, Identifiable {
    let name: String
    let category: String
    let title: String
    let description: String
    let inputModalities: [String]
    let outputModalities: [String]

    var id: String { name }

    enum CodingKeys: String, CodingKey {
        case name, category, title, description
        case inputModalities = "input_modalities"
        case outputModalities = "output_modalities"
    }
}

class PollinationsClient {
    static let shared = PollinationsClient()

    private let session: URLSession
    private let baseURL = "https://gen.pollinations.ai"

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        self.session = URLSession(configuration: config)
    }

    func fetchModels() async throws -> [PollinationsModel] {
        guard let url = URL(string: "\(baseURL)/models") else {
            throw PollinationsError.serviceDown
        }
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode([PollinationsModel].self, from: data)
    }

    func generateImage(
        prompt: String,
        model: String = "flux",
        width: Int = 1024,
        height: Int = 1024,
        seed: Int? = nil
    ) async throws -> Data {
        let encoded = prompt.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? prompt
        var urlString = "\(baseURL)/image/\(encoded)?model=\(model)&width=\(width)&height=\(height)&nologo=true"
        if let seed {
            urlString += "&seed=\(seed)"
        }

        guard let url = URL(string: urlString) else {
            throw PollinationsError.serviceDown
        }

        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw PollinationsError.serviceDown
        }

        let ct = http.value(forHTTPHeaderField: "Content-Type") ?? ""
        guard ct.contains("image") || data.count > 1000 else {
            throw PollinationsError.invalidImage
        }

        return data
    }

    func generateVideo(
        prompt: String,
        model: String = "wan"
    ) async throws -> Data {
        let encoded = prompt.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? prompt
        let urlString = "\(baseURL)/video/\(encoded)?model=\(model)&nologo=true"

        guard let url = URL(string: urlString) else {
            throw PollinationsError.serviceDown
        }

        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw PollinationsError.serviceDown
        }

        return data
    }
}
