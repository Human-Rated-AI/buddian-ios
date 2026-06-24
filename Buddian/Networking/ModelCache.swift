import Foundation

@MainActor
class ModelCache: ObservableObject {
    static let shared = ModelCache()

    @Published var models: [RemoteModel] = []
    @Published var isLoading = false

    private let cacheKey = "cached_models"
    private let cacheTimestampKey = "cached_models_timestamp"
    private let refreshInterval: TimeInterval = 3600

    private init() {
        loadFromCache()
    }

    func refresh() async {
        guard !isLoading else { return }
        isLoading = models.isEmpty

        do {
            let fetched = try await APIClient.shared.fetchModels()
            models = fetched
            saveToCache(fetched)
        } catch {
            if models.isEmpty {
                isLoading = false
            }
        }

        isLoading = false
    }

    func refreshIfNeeded() async {
        let timestamp = UserDefaults.standard.double(forKey: cacheTimestampKey)
        let lastRefresh = Date(timeIntervalSince1970: timestamp)
        if Date().timeIntervalSince(lastRefresh) > refreshInterval {
            await refresh()
        }
    }

    private func loadFromCache() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let cached = try? JSONDecoder().decode([RemoteModel].self, from: data) else {
            return
        }
        models = cached
    }

    private func saveToCache(_ models: [RemoteModel]) {
        guard let data = try? JSONEncoder().encode(models) else { return }
        UserDefaults.standard.set(data, forKey: cacheKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: cacheTimestampKey)
    }
}
