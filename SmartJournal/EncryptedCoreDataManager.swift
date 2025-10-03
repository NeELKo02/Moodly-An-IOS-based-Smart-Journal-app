import Foundation
import CryptoKit

@MainActor
class EncryptedCoreDataManager: ObservableObject {
    static let shared = EncryptedCoreDataManager()
    
    // File-based encrypted storage
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private let entriesFile: URL
    
    // MARK: - Encrypted Journal Entry Model
    
    struct EncryptedJournalEntry: Codable, Identifiable {
        let id: UUID
        let createdAt: Date
        let updatedAt: Date
        let encryptedText: Data
        let sentiment: Double
        let encryptedKeywords: Data?
        let encryptedSummary: Data?
        let encryptedWellnessNudge: Data?
        let encryptedTriggers: Data?
        let healthKitMoodValue: Int
        let healthKitMoodCategory: String?
        let healthKitUUID: String?
        let detectedLanguage: String
        let sleepDuration: Double?
        let stepCount: Int?
        let workoutMinutes: Int?
        let voiceTranscribed: Bool
    }
    
    // Encryption key management
    private let encryptionKey: SymmetricKey
    
    init() {
        // Generate or retrieve encryption key
        self.encryptionKey = Self.getOrCreateEncryptionKey()
        self.entriesFile = documentsDirectory.appendingPathComponent("encrypted_entries.json")
    }
    
    // MARK: - Encryption Key Management
    
    private static func getOrCreateEncryptionKey() -> SymmetricKey {
        let keychain = KeychainWrapper()
        let keyIdentifier = "SmartJournalEncryptionKey"
        
        if let existingKeyData = keychain.data(forKey: keyIdentifier) {
            return SymmetricKey(data: existingKeyData)
        } else {
            let newKey = SymmetricKey(size: .bits256)
            let keyData = Data(newKey.withUnsafeBytes { Data($0) })
            _ = keychain.set(keyData, forKey: keyIdentifier)
            return newKey
        }
    }
    
    // MARK: - Encryption/Decryption Methods
    
    func encryptText(_ text: String) -> Data? {
        guard let data = text.data(using: .utf8) else { return nil }
        
        do {
            let sealedBox = try AES.GCM.seal(data, using: encryptionKey)
            return sealedBox.combined
        } catch {
            print("Encryption failed: \(error)")
            return nil
        }
    }
    
    func decryptText(_ encryptedData: Data) -> String? {
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: encryptionKey)
            return String(data: decryptedData, encoding: .utf8)
        } catch {
            print("Decryption failed: \(error)")
            return nil
        }
    }
    
    // MARK: - File-based Storage Operations
    
    private func loadEntriesFromFile() -> [EncryptedJournalEntry] {
        guard FileManager.default.fileExists(atPath: entriesFile.path) else {
            return []
        }
        
        do {
            let data = try Data(contentsOf: entriesFile)
            return try JSONDecoder().decode([EncryptedJournalEntry].self, from: data)
        } catch {
            print("Error loading entries: \(error)")
            return []
        }
    }
    
    private func saveEntriesToFile(_ entries: [EncryptedJournalEntry]) {
        do {
            let data = try JSONEncoder().encode(entries)
            try data.write(to: entriesFile)
        } catch {
            print("Error saving entries: \(error)")
        }
    }
    
    func createEncryptedJournalEntry(
        text: String,
        sentiment: Double?,
        keywords: [String],
        summary: [String],
        healthKitMoodValue: Int? = nil,
        healthKitMoodCategory: String? = nil,
        healthKitUUID: String? = nil,
        wellnessNudge: String? = nil,
        triggers: [String] = [],
        detectedLanguage: String = "en",
        sleepDuration: Double? = nil,
        stepCount: Int? = nil,
        workoutMinutes: Int? = nil,
        voiceTranscribed: Bool = false
    ) {
        var entries = loadEntriesFromFile()
        
        // Encrypt sensitive text data
        guard let encryptedText = encryptText(text) else {
            print("Failed to encrypt text")
            return
        }
        
        // Encrypt keywords array
        var encryptedKeywords: Data? = nil
        if let keywordsData = try? JSONEncoder().encode(keywords),
           let keywordsString = String(data: keywordsData, encoding: .utf8),
           let encrypted = encryptText(keywordsString) {
            encryptedKeywords = encrypted
        }
        
        // Encrypt summary array
        var encryptedSummary: Data? = nil
        if let summaryData = try? JSONEncoder().encode(summary),
           let summaryString = String(data: summaryData, encoding: .utf8),
           let encrypted = encryptText(summaryString) {
            encryptedSummary = encrypted
        }
        
        // Encrypt wellness nudge
        var encryptedWellnessNudge: Data? = nil
        if let nudge = wellnessNudge,
           let encrypted = encryptText(nudge) {
            encryptedWellnessNudge = encrypted
        }
        
        // Encrypt triggers
        var encryptedTriggers: Data? = nil
        if let triggersData = try? JSONEncoder().encode(triggers),
           let triggersString = String(data: triggersData, encoding: .utf8),
           let encrypted = encryptText(triggersString) {
            encryptedTriggers = encrypted
        }
        
        let entry = EncryptedJournalEntry(
            id: UUID(),
            createdAt: Date(),
            updatedAt: Date(),
            encryptedText: encryptedText,
            sentiment: sentiment ?? 0.0,
            encryptedKeywords: encryptedKeywords,
            encryptedSummary: encryptedSummary,
            encryptedWellnessNudge: encryptedWellnessNudge,
            encryptedTriggers: encryptedTriggers,
            healthKitMoodValue: healthKitMoodValue ?? 0,
            healthKitMoodCategory: healthKitMoodCategory,
            healthKitUUID: healthKitUUID,
            detectedLanguage: detectedLanguage,
            sleepDuration: sleepDuration,
            stepCount: stepCount,
            workoutMinutes: workoutMinutes,
            voiceTranscribed: voiceTranscribed
        )
        
        entries.append(entry)
        saveEntriesToFile(entries)
    }
    
    func fetchEncryptedEntries() -> [EncryptedJournalEntry] {
        let entries = loadEntriesFromFile()
        return entries.sorted { $0.createdAt > $1.createdAt }
    }
    
    func decryptEntry(_ entry: EncryptedJournalEntry) -> DecryptedJournalEntry? {
        guard let decryptedText = decryptText(entry.encryptedText) else {
            return nil
        }
        
        var keywords: [String] = []
        if let encryptedKeywords = entry.encryptedKeywords,
           let decryptedKeywords = decryptText(encryptedKeywords),
           let keywordsData = decryptedKeywords.data(using: .utf8) {
            keywords = (try? JSONDecoder().decode([String].self, from: keywordsData)) ?? []
        }
        
        var summary: [String] = []
        if let encryptedSummary = entry.encryptedSummary,
           let decryptedSummary = decryptText(encryptedSummary),
           let summaryData = decryptedSummary.data(using: .utf8) {
            summary = (try? JSONDecoder().decode([String].self, from: summaryData)) ?? []
        }
        
        var wellnessNudge: String? = nil
        if let encryptedNudge = entry.encryptedWellnessNudge {
            wellnessNudge = decryptText(encryptedNudge)
        }
        
        var triggers: [String] = []
        if let encryptedTriggers = entry.encryptedTriggers,
           let decryptedTriggers = decryptText(encryptedTriggers),
           let triggersData = decryptedTriggers.data(using: .utf8) {
            triggers = (try? JSONDecoder().decode([String].self, from: triggersData)) ?? []
        }
        
        return DecryptedJournalEntry(
            id: entry.id,
            text: decryptedText,
            sentiment: entry.sentiment,
            keywords: keywords,
            summary: summary,
            wellnessNudge: wellnessNudge,
            triggers: triggers,
            healthKitMoodValue: entry.healthKitMoodValue,
            healthKitMoodCategory: entry.healthKitMoodCategory,
            healthKitUUID: entry.healthKitUUID,
            detectedLanguage: entry.detectedLanguage,
            sleepDuration: entry.sleepDuration,
            stepCount: entry.stepCount,
            workoutMinutes: entry.workoutMinutes,
            voiceTranscribed: entry.voiceTranscribed,
            createdAt: entry.createdAt,
            updatedAt: entry.updatedAt
        )
    }
    
    func deleteEntry(_ entry: EncryptedJournalEntry) {
        var entries = loadEntriesFromFile()
        entries.removeAll { $0.id == entry.id }
        saveEntriesToFile(entries)
    }
}

// MARK: - Decrypted Entry Model

struct DecryptedJournalEntry {
    let id: UUID
    let text: String
    let sentiment: Double?
    let keywords: [String]
    let summary: [String]
    let wellnessNudge: String?
    let triggers: [String]
    let healthKitMoodValue: Int?
    let healthKitMoodCategory: String?
    let healthKitUUID: String?
    let detectedLanguage: String
    let sleepDuration: Double?
    let stepCount: Int?
    let workoutMinutes: Int?
    let voiceTranscribed: Bool
    let createdAt: Date
    let updatedAt: Date
}
