import Foundation
import CryptoKit
import Security

@MainActor
class PrivacyManager: ObservableObject {
    @Published var isDataEncrypted = false
    @Published var biometricAuthEnabled = false
    @Published var autoLockEnabled = false
    
    private let keychain = KeychainWrapper.standard
    private let userDefaults = UserDefaults.standard
    
    // Privacy settings keys
    private enum Keys {
        static let biometricAuth = "biometricAuthEnabled"
        static let autoLock = "autoLockEnabled"
        static let dataEncryption = "dataEncryptionEnabled"
        static let analyticsOptOut = "analyticsOptOut"
        static let dataRetentionDays = "dataRetentionDays"
    }
    
    init() {
        loadPrivacySettings()
    }
    
    // MARK: - Privacy Settings
    
    func loadPrivacySettings() {
        biometricAuthEnabled = userDefaults.bool(forKey: Keys.biometricAuth)
        autoLockEnabled = userDefaults.bool(forKey: Keys.autoLock)
        isDataEncrypted = userDefaults.bool(forKey: Keys.dataEncryption)
    }
    
    func updatePrivacySettings(biometric: Bool, autoLock: Bool, encryption: Bool) {
        biometricAuthEnabled = biometric
        autoLockEnabled = autoLock
        isDataEncrypted = encryption
        
        userDefaults.set(biometric, forKey: Keys.biometricAuth)
        userDefaults.set(autoLock, forKey: Keys.autoLock)
        userDefaults.set(encryption, forKey: Keys.dataEncryption)
    }
    
    // MARK: - Data Encryption
    
    func encryptText(_ text: String) -> String? {
        guard isDataEncrypted else { return text }
        
        do {
            let key = SymmetricKey(size: .bits256)
            let encryptedData = try AES.GCM.seal(text.data(using: .utf8)!, using: key)
            return encryptedData.combined?.base64EncodedString()
        } catch {
            print("Encryption failed: \(error)")
            return nil
        }
    }
    
    func decryptText(_ encryptedText: String) -> String? {
        guard isDataEncrypted else { return encryptedText }
        
        do {
            guard let data = Data(base64Encoded: encryptedText),
                  let sealedBox = try? AES.GCM.SealedBox(combined: data) else {
                return nil
            }
            
            let key = SymmetricKey(size: .bits256)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return String(data: decryptedData, encoding: .utf8)
        } catch {
            print("Decryption failed: \(error)")
            return nil
        }
    }
    
    // MARK: - Secure Storage
    
    func secureStore(_ data: Data, forKey key: String) -> Bool {
        guard isDataEncrypted else {
            return keychain.set(data, forKey: key)
        }
        
        // Store encrypted data
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func secureRetrieve(forKey key: String) -> Data? {
        guard isDataEncrypted else {
            return keychain.data(forKey: key)
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let _ = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard let data = result as? Data else {
            return nil
        }
        
        return data
    }
    
    // MARK: - Data Retention
    
    func getDataRetentionDays() -> Int {
        return userDefaults.integer(forKey: Keys.dataRetentionDays)
    }
    
    func setDataRetentionDays(_ days: Int) {
        userDefaults.set(days, forKey: Keys.dataRetentionDays)
    }
    
    func shouldDeleteEntry(_ entryDate: Date) -> Bool {
        let retentionDays = getDataRetentionDays()
        guard retentionDays > 0 else { return false }
        
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date())!
        return entryDate < cutoffDate
    }
    
    // MARK: - Privacy Controls
    
    func exportData() -> String {
        // Export data in a privacy-friendly format
        var export = "SmartJournal Privacy Export\n"
        export += "Generated: \(Date().formatted())\n"
        export += "Data Retention: \(getDataRetentionDays()) days\n"
        export += "Encryption: \(isDataEncrypted ? "Enabled" : "Disabled")\n"
        export += "Biometric Auth: \(biometricAuthEnabled ? "Enabled" : "Disabled")\n"
        export += "Auto Lock: \(autoLockEnabled ? "Enabled" : "Disabled")\n\n"
        
        return export
    }
    
    func deleteAllData() {
        // Clear all stored data
        keychain.removeAllKeys()
        
        // Clear UserDefaults
        let domain = Bundle.main.bundleIdentifier!
        userDefaults.removePersistentDomain(forName: domain)
        
        // Reset privacy settings
        loadPrivacySettings()
    }
    
    // MARK: - Privacy Analytics
    
    func isAnalyticsOptOut() -> Bool {
        return userDefaults.bool(forKey: Keys.analyticsOptOut)
    }
    
    func setAnalyticsOptOut(_ optOut: Bool) {
        userDefaults.set(optOut, forKey: Keys.analyticsOptOut)
    }
    
    // MARK: - Privacy Compliance
    
    func getPrivacyReport() -> [String: Any] {
        return [
            "encryption_enabled": isDataEncrypted,
            "biometric_auth": biometricAuthEnabled,
            "auto_lock": autoLockEnabled,
            "data_retention_days": getDataRetentionDays(),
            "analytics_opt_out": isAnalyticsOptOut(),
            "last_updated": Date().formatted()
        ]
    }
}

// MARK: - Keychain Wrapper
class KeychainWrapper {
    static let standard = KeychainWrapper()
    
    func set(_ data: Data, forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func data(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let _ = SecItemCopyMatching(query as CFDictionary, &result)
        
        return (result as? Data)
    }
    
    func removeAllKeys() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword
        ]
        SecItemDelete(query as CFDictionary)
    }
}
