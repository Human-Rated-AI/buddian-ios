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

    private func get<T: Decodable>(path: String) async throws -> T {
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
