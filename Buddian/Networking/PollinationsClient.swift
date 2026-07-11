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
    private let cacheKey = "working_pollinations_models"

    static let workingModels: [PollinationsModel] = [
        PollinationsModel(
            name: "flux",
            category: "image",
            title: "FLUX",
            description: "Fast, high-quality image generation",
            inputModalities: ["text"],
            outputModalities: ["image"]
        ),
        PollinationsModel(
            name: "zimage",
            category: "image",
            title: "ZImage",
            description: "Versatile image generation model",
            inputModalities: ["text"],
            outputModalities: ["image"]
        ),
    ]

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        self.session = URLSession(configuration: config)
    }

    func fetchModels() async throws -> [PollinationsModel] {
        guard let url = URL(string: "\(baseURL)/models") else {
            return Self.workingModels
        }

        do {
            let (data, _) = try await session.data(from: url)
            let allModels = try JSONDecoder().decode([PollinationsModel].self, from: data)

            let imageModels = allModels.filter { $0.category == "image" }
            let workingModels = imageModels.filter { model in
                Self.workingModels.contains { $0.name == model.name }
            }

            if !workingModels.isEmpty {
                cacheModels(workingModels)
                return workingModels
            }

            return Self.workingModels
        } catch {
            return loadCachedModels()
        }
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

    private func cacheModels(_ models: [PollinationsModel]) {
        if let data = try? JSONEncoder().encode(models) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }

    private func loadCachedModels() -> [PollinationsModel] {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let models = try? JSONDecoder().decode([PollinationsModel].self, from: data) else {
            return Self.workingModels
        }
        return models.isEmpty ? Self.workingModels : models
    }
}
