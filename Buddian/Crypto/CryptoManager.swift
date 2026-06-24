import Foundation
import CryptoKit

@MainActor
class CryptoManager {
    static let shared = CryptoManager()

    private var privateKey: P256.KeyAgreement.PrivateKey?
    private(set) var publicKeyHex: String?

    private init() {
        generateKeyPair()
    }

    func generateKeyPair() {
        let privateKey = P256.KeyAgreement.PrivateKey()
        self.privateKey = privateKey
        self.publicKeyHex = privateKey.publicKey.x963Representation.hexString
    }

    func encrypt(plaintext: Data, with peerPublicKeyHex: String) throws -> Data {
        guard let privateKey = privateKey else {
            throw CryptoError.noPrivateKey
        }

        guard let peerPublicKeyData = Data(hexString: peerPublicKeyHex) else {
            throw CryptoError.invalidPublicKey
        }

        let peerPublicKey = try P256.KeyAgreement.PublicKey(x963Representation: peerPublicKeyData)

        let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: peerPublicKey)

        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: "buddian-e2ee-v1".data(using: .utf8)!,
            outputByteCount: 32
        )

        let sealedBox = try AES.GCM.seal(plaintext, using: symmetricKey)

        var result = Data()
        result.append(contentsOf: sealedBox.nonce)
        result.append(contentsOf: sealedBox.ciphertext)
        result.append(contentsOf: sealedBox.tag)

        return result
    }

    func decrypt(cipherData: Data, from peerPublicKeyHex: String) throws -> Data {
        guard let privateKey = privateKey else {
            throw CryptoError.noPrivateKey
        }

        guard let peerPublicKeyData = Data(hexString: peerPublicKeyHex) else {
            throw CryptoError.invalidPublicKey
        }

        let peerPublicKey = try P256.KeyAgreement.PublicKey(x963Representation: peerPublicKeyData)

        let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: peerPublicKey)

        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: "buddian-e2ee-v1".data(using: .utf8)!,
            outputByteCount: 32
        )

        let nonce = cipherData.prefix(12)
        let ciphertext = cipherData.dropFirst(12).dropLast(16)
        let tag = cipherData.suffix(16)

        let sealedBox = try AES.GCM.SealedBox(
            nonce: AES.GCM.Nonce(data: nonce),
            ciphertext: ciphertext,
            tag: tag
        )

        return try AES.GCM.open(sealedBox, using: symmetricKey)
    }
}

enum CryptoError: Error, LocalizedError {
    case noPrivateKey
    case invalidPublicKey
    case encryptionFailed
    case decryptionFailed

    var errorDescription: String? {
        switch self {
        case .noPrivateKey: return "No private key available"
        case .invalidPublicKey: return "Invalid public key"
        case .encryptionFailed: return "Encryption failed"
        case .decryptionFailed: return "Decryption failed"
        }
    }
}

extension Data {
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }

    init?(hexString: String) {
        let hex = hexString.filter { $0.isHexDigit }
        guard hex.count % 2 == 0 else { return nil }
        var data = Data(capacity: hex.count / 2)
        var index = hex.startIndex
        while index < hex.endIndex {
            let nextIndex = hex.index(index, offsetBy: 2)
            guard let byte = UInt8(hex[index..<nextIndex], radix: 16) else { return nil }
            data.append(byte)
            index = nextIndex
        }
        self = data
    }
}
