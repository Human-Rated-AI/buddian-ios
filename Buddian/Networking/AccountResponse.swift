import Foundation

struct AccountResponse: Codable {
    let user: AccountUser
    let transactions: [AccountTransaction]
    let serviceStatus: String?

    enum CodingKeys: String, CodingKey {
        case user, transactions
        case serviceStatus = "service_status"
    }

    var balance: Double {
        Double(user.balance.availableUsd) ?? 0
    }
}

struct AccountUser: Codable {
    let id: Int
    let email: String?
    let displayName: String?
    let balance: AccountBalance
}

struct AccountBalance: Codable {
    let currency: String
    let availableUsd: String

    enum CodingKeys: String, CodingKey {
        case currency
        case availableUsd = "available_usd"
    }
}

struct AccountTransaction: Codable, Identifiable {
    let id: Int
    let kind: String?
    let entryType: String?
    let description: String?
    let amountUsd: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, kind, description
        case entryType = "entry_type"
        case amountUsd = "amount_usd"
        case createdAt = "created_at"
    }
}
