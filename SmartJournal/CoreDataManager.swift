import Foundation
import CoreData
import CryptoKit

@MainActor
class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    // MARK: - Core Data Stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "SmartJournalModel")
        
        // Configure for encrypted storage
        let description = container.persistentStoreDescriptions.first
        description?.setOption(FileProtectionType.complete as NSString, forKey: NSPersistentStoreFileProtectionKey)
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                print("Core Data error: \(error), \(error.userInfo)")
                // Don't fatal error, just log and continue
            }
        }
        
        // Enable automatic merging
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        return container
    }()
    
    // Safe access to context
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Encryption
    
    private let encryptionKey: SymmetricKey
    
    private init() {
        // Generate or retrieve encryption key
        self.encryptionKey = Self.getOrCreateEncryptionKey()
    }
    
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
    
    private func encryptText(_ text: String) -> Data? {
        guard let data = text.data(using: .utf8) else { return nil }
        
        do {
            let sealedBox = try AES.GCM.seal(data, using: encryptionKey)
            return sealedBox.combined
        } catch {
            print("Encryption failed: \(error)")
            return nil
        }
    }
    
    private func decryptText(_ encryptedData: Data) -> String? {
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: encryptionKey)
            return String(data: decryptedData, encoding: .utf8)
        } catch {
            print("Decryption failed: \(error)")
            return nil
        }
    }
    
    // MARK: - Core Data Operations
    
    func save() {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Save error: \(error)")
            }
        }
    }
    
    func createJournalEntry(
        text: String,
        sentiment: Double,
        keywords: [String],
        summary: [String],
        wellnessNudge: String?,
        triggers: [String],
        healthKitMoodValue: Int = 0,
        healthKitMoodCategory: String? = nil,
        healthKitUUID: String? = nil,
        detectedLanguage: String = "en",
        sleepDuration: Double? = nil,
        stepCount: Int? = nil,
        workoutMinutes: Int? = nil,
        voiceTranscribed: Bool = false
    ) {
        // Use the existing EncryptedCoreDataManager approach
        // This avoids CoreData KeyPath issues
        EncryptedCoreDataManager.shared.createEncryptedJournalEntry(
            text: text,
            sentiment: sentiment,
            keywords: keywords,
            summary: summary,
            healthKitMoodValue: healthKitMoodValue,
            healthKitMoodCategory: healthKitMoodCategory,
            healthKitUUID: healthKitUUID,
            wellnessNudge: wellnessNudge,
            triggers: triggers,
            detectedLanguage: detectedLanguage,
            sleepDuration: sleepDuration,
            stepCount: stepCount,
            workoutMinutes: workoutMinutes,
            voiceTranscribed: voiceTranscribed
        )
    }
    
    func fetchEntries() -> [JournalEntry] {
        // Use the existing EncryptedCoreDataManager to fetch entries
        let encryptedEntries = EncryptedCoreDataManager.shared.fetchEncryptedEntries()
        return encryptedEntries.compactMap { encryptedEntry in
            guard let decryptedEntry = EncryptedCoreDataManager.shared.decryptEntry(encryptedEntry) else {
                return nil
            }
            
            return JournalEntry(
                text: decryptedEntry.text,
                sentiment: decryptedEntry.sentiment,
                keywords: decryptedEntry.keywords,
                summary: decryptedEntry.summary,
                wellnessNudge: decryptedEntry.wellnessNudge,
                triggers: decryptedEntry.triggers,
                healthKitMoodValue: decryptedEntry.healthKitMoodValue,
                healthKitMoodCategory: decryptedEntry.healthKitMoodCategory,
                healthKitUUID: decryptedEntry.healthKitUUID,
                detectedLanguage: decryptedEntry.detectedLanguage,
                sleepDuration: decryptedEntry.sleepDuration,
                stepCount: decryptedEntry.stepCount,
                workoutMinutes: decryptedEntry.workoutMinutes,
                voiceTranscribed: decryptedEntry.voiceTranscribed
            )
        }
    }
    
    func deleteEntry(_ entry: JournalEntry) {
        // Find and delete the corresponding encrypted entry
        let encryptedEntries = EncryptedCoreDataManager.shared.fetchEncryptedEntries()
        if let encryptedEntry = encryptedEntries.first(where: { $0.id == entry.id }) {
            EncryptedCoreDataManager.shared.deleteEntry(encryptedEntry)
        }
    }
    
    func decryptEntry(_ entry: JournalEntry) -> DecryptedJournalEntry? {
        // Convert JournalEntry to DecryptedJournalEntry
        return DecryptedJournalEntry(
            id: entry.id,
            text: entry.text,
            sentiment: entry.sentiment,
            keywords: entry.keywords,
            summary: entry.summary,
            wellnessNudge: entry.wellnessNudge,
            triggers: entry.triggers,
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
}

// MARK: - Decrypted Entry Model (using existing from EncryptedCoreDataManager)
