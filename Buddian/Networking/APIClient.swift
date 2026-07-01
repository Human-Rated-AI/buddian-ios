import Foundation

@MainActor
class APIClient {
    static let shared = APIClient()

    private let baseURL = URL(string: "https://api.buddian.com")!
    private let session: URLSession

    var sessionToken: String?

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)

        // Restore session from Keychain on init
        sessionToken = SessionManager.shared.sessionToken
    }

    func healthCheck() async throws -> HealthResponse {
        try await get(path: "/health")
    }

    func fetchModels() async throws -> [RemoteModel] {
        let response: ModelsResponse = try await get(path: "/models")
        return response.data
    }

    func fetchAccount() async throws -> AccountResponse {
        try await get(path: "/web/me")
    }

    func fetchGenerations() async throws -> [Generation] {
        let response: GenerationsResponse = try await get(path: "/generations")
        return response.data
    }

    struct GenerationSubmitRequest: Encodable {
        let modelId: String
        let prompt: String
        let negativePrompt: String?
        let width: Int?
        let height: Int?
        let steps: Int?
        let cfgScale: Double?
        let numImages: Int?

        enum CodingKeys: String, CodingKey {
            case modelId = "model_id"
            case prompt
            case negativePrompt = "negative_prompt"
            case width, height, steps
            case cfgScale = "cfg_scale"
            case numImages = "num_images"
        }
    }

    struct GenerationSubmitResponse: Codable {
        let jobId: String
        let status: String
        let estimatedSeconds: Int
        let costEstimate: Double

        enum CodingKeys: String, CodingKey {
            case jobId = "job_id"
            case status
            case estimatedSeconds = "estimated_seconds"
            case costEstimate = "cost_estimate"
        }
    }

    func submitGeneration(_ request: GenerationSubmitRequest) async throws -> GenerationSubmitResponse {
        try await post(path: "/generations", body: request)
    }

    func fetchGeneration(jobId: String) async throws -> Generation {
        try await get(path: "/generations/\(jobId)")
    }

    func downloadResult(jobId: String) async throws -> Data {
        guard let jobID = Int(jobId) else {
            throw APIError.invalidURL
        }
        let url = baseURL.appendingPathComponent("/generations/\(jobID)/result")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let token = sessionToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        return data
    }

    func post<Body: Encodable, T: Decodable>(path: String, body: Body) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(body)

        if let token = sessionToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await session.data(for: request)
            try validateResponse(response, data: data)
            return try JSONDecoder().decode(T.self, from: data)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    func get<T: Decodable>(path: String) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = sessionToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await session.data(for: request)
            try validateResponse(response, data: data)
            return try JSONDecoder().decode(T.self, from: data)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8)
            throw APIError.serverError(httpResponse.statusCode, body)
        }
    }
}
