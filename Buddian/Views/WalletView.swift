import SwiftUI

struct WalletView: View {
    @State private var balance: Double = 0
    @State private var transactions: [AccountTransaction] = []
    @State private var isLoading = false
    @EnvironmentObject var sessionManager: SessionManager

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Balance")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(String(format: "$%.2f", balance))
                                .font(.largeTitle)
                                .fontWeight(.bold)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }

                Section("Recent Transactions") {
                    if transactions.isEmpty && !isLoading {
                        Text("No transactions yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(transactions) { tx in
                            TransactionRow(transaction: tx)
                        }
                    }
                }

                Section {
                    Button("Sign Out", role: .destructive) {
                        AuthService.shared.signOut()
                    }
                }
            }
            .navigationTitle("Wallet")
            .refreshable { await loadAccount() }
            .task { await loadAccount() }
        }
    }

    private func loadAccount() async {
        isLoading = true
        do {
            let account: AccountResponse = try await APIClient.shared.get(path: "/web/me")
            balance = account.balance
            transactions = account.transactions
        } catch {
            NSLog("[Wallet] Load error: \(error)")
        }
        isLoading = false
    }
}

private struct TransactionRow: View {
    let transaction: AccountTransaction

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(transaction.description ?? transaction.kind ?? "Transaction")
                    .font(.headline)
                if let dateStr = transaction.createdAt {
                    Text(dateStr)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let amount = transaction.amountUsd {
                priceText(amount)
            }
        }
    }

    private func priceText(_ amountStr: String) -> some View {
        let amount = Double(amountStr) ?? 0
        let main = String(format: "$%.2f", abs(amount))
        let raw = String(format: "%.6f", abs(amount))
        let tail = String(raw.suffix(4))
        return HStack(spacing: 0) {
            Text(main)
                .fontWeight(.medium)
            Text(tail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    WalletView()
        .environmentObject(SessionManager.shared)
}
