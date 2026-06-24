import Foundation

struct AccountResponse: Codable {
    let uid: String
    let email: String?
    let displayName: String?
    let balance: Double
    let credits: AccountCredits?
}

struct AccountCredits: Codable {
    let gpuMinutes: Double?

    enum CodingKeys: String, CodingKey {
        case gpuMinutes = "gpu_minutes"
    }
}
