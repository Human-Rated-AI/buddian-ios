import Foundation

@MainActor
class ModelCache: ObservableObject {
    static let shared = ModelCache()

    @Published var models: [RemoteModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let cacheKey = "cached_models"
    private let cacheTimestampKey = "cached_models_timestamp"
    private let refreshInterval: TimeInterval = 3600

    private init() {
        loadFromCache()
    }

    func refresh() async {
        guard !isLoading else { return }
        isLoading = models.isEmpty
        errorMessage = nil

        do {
            let fetched = try await APIClient.shared.fetchModels()
            if !fetched.isEmpty {
                models = fetched
                saveToCache(fetched)
                NSLog("[ModelCache] Fetched \(fetched.count) models from API")
            } else {
                NSLog("[ModelCache] API returned empty, using fallback")
                useFallbackModels()
            }
        } catch {
            NSLog("[ModelCache] Fetch failed: \(error), using fallback")
            useFallbackModels()
        }

        isLoading = false
    }

    private func useFallbackModels() {
        if models.isEmpty {
            models = [
                RemoteModel(
                    id: "pollinations/flux",
                    name: "Flux",
                    description: "Fast image generation via Pollinations",
                    type: "image_generation",
                    status: "free",
                    availabilityReason: nil,
                    standardTee: false,
                    inputModalities: ["text"],
                    outputModalities: ["image"],
                    contextLength: nil,
                    maxOutputLength: nil,
                    supportedParameters: nil,
                    providers: ["pollinations"],
                    userPricing: UserPricing(currency: "USD", promptPer1mTokens: nil, completionPer1mTokens: nil, perImage: "0", perSecond: nil),
                    defaultWidth: 1024,
                    defaultHeight: 1024,
                    defaultSteps: nil,
                    defaultCfgScale: nil
                ),
                RemoteModel(
                    id: "pollinations/gptimage",
                    name: "GPT Image",
                    description: "GPT-Image model via Pollinations",
                    type: "image_generation",
                    status: "free",
                    availabilityReason: nil,
                    standardTee: false,
                    inputModalities: ["text"],
                    outputModalities: ["image"],
                    contextLength: nil,
                    maxOutputLength: nil,
                    supportedParameters: nil,
                    providers: ["pollinations"],
                    userPricing: UserPricing(currency: "USD", promptPer1mTokens: nil, completionPer1mTokens: nil, perImage: "0", perSecond: nil),
                    defaultWidth: 1024,
                    defaultHeight: 1024,
                    defaultSteps: nil,
                    defaultCfgScale: nil
                ),
                RemoteModel(
                    id: "pollinations/seedream",
                    name: "Seedream",
                    description: "Seedream model via Pollinations",
                    type: "image_generation",
                    status: "free",
                    availabilityReason: nil,
                    standardTee: false,
                    inputModalities: ["text"],
                    outputModalities: ["image"],
                    contextLength: nil,
                    maxOutputLength: nil,
                    supportedParameters: nil,
                    providers: ["pollinations"],
                    userPricing: UserPricing(currency: "USD", promptPer1mTokens: nil, completionPer1mTokens: nil, perImage: "0", perSecond: nil),
                    defaultWidth: 1024,
                    defaultHeight: 1024,
                    defaultSteps: nil,
                    defaultCfgScale: nil
                ),
            ]
            saveToCache(models)
            NSLog("[ModelCache] Using fallback models: \(models.count)")
        }
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
