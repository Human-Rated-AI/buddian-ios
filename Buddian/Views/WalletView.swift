import SwiftUI

struct WalletView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Balance")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("$12.50")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    .padding(.vertical, 8)
                }

                Section("Batch Credits") {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("GPU Time")
                                .font(.headline)
                            Text("40 minutes remaining")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("40m")
                            .font(.title3)
                            .foregroundStyle(.blue)
                    }
                }

                Section("Add Funds") {
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.green)
                            Text("Add Funds via Apple Pay")
                        }
                    }
                }

                Section("Recent Transactions") {
                    ForEach(sampleTransactions) { tx in
                        TransactionRow(transaction: tx)
                    }
                }
            }
            .navigationTitle("Wallet")
            .refreshable {
                // TODO: Fetch balance from API
            }
        }
    }

    private var sampleTransactions: [Transaction] {
        [
            Transaction(id: "1", title: "Starter Pack", amount: -4.99, date: Date().addingTimeInterval(-86400)),
            Transaction(id: "2", title: "Image Generation", amount: -0.025, date: Date().addingTimeInterval(-172800)),
            Transaction(id: "3", title: "Pro Pack", amount: -9.99, date: Date().addingTimeInterval(-259200)),
        ]
    }
}

struct Transaction: Identifiable {
    let id: String
    let title: String
    let amount: Double
    let date: Date
}

private struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(transaction.title)
                    .font(.headline)
                Text(transaction.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(String(format: "$%.2f", abs(transaction.amount)))
                .foregroundStyle(transaction.amount < 0 ? .red : .green)
        }
    }
}

#Preview {
    WalletView()
}
