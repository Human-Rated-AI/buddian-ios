import SwiftUI

struct ShieldView: View {
    @State private var attestationStatus: AttestationStatus = .notStarted
    @State private var keyState: KeyState = .generated
    @State private var endpointURL = "https://api.buddian.com"

    var body: some View {
        NavigationStack {
            List {
                Section("Attestation") {
                    HStack {
                        Image(systemName: attestationStatus.icon)
                            .foregroundStyle(attestationStatus.color)
                        VStack(alignment: .leading) {
                            Text("TEE Attestation")
                                .font(.headline)
                            Text(attestationStatus.label)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }

                Section("Local Key") {
                    HStack {
                        Image(systemName: keyState.icon)
                            .foregroundStyle(keyState.color)
                        VStack(alignment: .leading) {
                            Text("Encryption Key")
                                .font(.headline)
                            Text(keyState.label)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }

                Section("Source Verification") {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                        VStack(alignment: .leading) {
                            Text("Build Verification")
                                .font(.headline)
                            Text("Source matches signed release")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }

                Section("Settings") {
                    HStack {
                        Text("Endpoint")
                        Spacer()
                        Text(endpointURL)
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Shield")
        }
    }
}

enum AttestationStatus {
    case notStarted
    case passed
    case warning
    case failed

    var icon: String {
        switch self {
        case .notStarted: return "questionmark.circle"
        case .passed: return "checkmark.shield.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .failed: return "xmark.shield.fill"
        }
    }

    var color: Color {
        switch self {
        case .notStarted: return .gray
        case .passed: return .green
        case .warning: return .yellow
        case .failed: return .red
        }
    }

    var label: String {
        switch self {
        case .notStarted: return "Not started"
        case .passed: return "Attestation passed"
        case .warning: return "Warning — check required"
        case .failed: return "Attestation failed"
        }
    }
}

enum KeyState {
    case notGenerated
    case generated

    var icon: String {
        switch self {
        case .notGenerated: return "key.slash"
        case .generated: return "key.fill"
        }
    }

    var color: Color {
        switch self {
        case .notGenerated: return .red
        case .generated: return .green
        }
    }

    var label: String {
        switch self {
        case .notGenerated: return "No key generated"
        case .generated: return "Key ready for encryption"
        }
    }
}

#Preview {
    ShieldView()
}
