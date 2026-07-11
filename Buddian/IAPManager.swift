import Foundation
import StoreKit

@MainActor
class IAPManager: ObservableObject {
    static let shared = IAPManager()

    @Published var products: [Product] = []
    @Published var isLoading = false

    private let productIDs: Set<String> = [
        "com.buddian.starter",
        "com.buddian.pro",
        "com.buddian.studio",
        "com.buddian.1hour",
        "com.buddian.3hour",
        "com.buddian.6hour",
        "com.buddian.24hour"
    ]

    private init() {}

    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: productIDs)
                .sorted { $0.price < $1.price }
        } catch {
            NSLog("[IAP] Failed to load products: \(error)")
        }
        isLoading = false
    }

    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateWalletAfterPurchase(transaction)
            await transaction.finish()
            return transaction
        case .userCancelled:
            return nil
        case .pending:
            return nil
        @unknown default:
            return nil
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw IAPError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }

    private func updateWalletAfterPurchase(_ transaction: Transaction) async {
        NSLog("[IAP] Purchase completed: \(transaction.productID), amount: \(transaction.price)")
    }

    func restorePurchases() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                NSLog("[IAP] Restored: \(transaction.productID)")
            }
        }
    }
}

enum IAPError: LocalizedError {
    case verificationFailed

    var errorDescription: String? {
        switch self {
        case .verificationFailed:
            return "Purchase verification failed"
        }
    }
}
