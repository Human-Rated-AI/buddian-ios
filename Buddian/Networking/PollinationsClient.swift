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

class PollinationsClient {
    static let shared = PollinationsClient()

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        self.session = URLSession(configuration: config)
    }

    func generateImage(
        prompt: String,
        model: String = "flux",
        width: Int = 1024,
        height: Int = 1024,
        seed: Int? = nil
    ) async throws -> Data {
        let encoded = prompt.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? prompt
        var urlString = "https://gen.pollinations.ai/image/\(encoded)?model=\(model)&width=\(width)&height=\(height)&nologo=true"
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
}
