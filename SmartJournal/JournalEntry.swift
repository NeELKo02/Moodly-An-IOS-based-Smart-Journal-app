import Foundation
import SwiftData

@Model
class JournalEntry {
    var id: UUID
    var text: String
    var sentiment: Double?
    var keywords: [String]
    var summary: [String]
    var wellnessNudge: String?
    var triggers: [String]
    var createdAt: Date
    var updatedAt: Date
    
    // HealthKit integration
    var healthKitMoodValue: Int?
    var healthKitMoodCategory: String?
    var healthKitUUID: String?
    var sleepDuration: Double?
    var stepCount: Int?
    var workoutMinutes: Int?
    
    // Additional metadata
    var detectedLanguage: String
    var voiceTranscribed: Bool
    
    init(
        text: String,
        sentiment: Double? = nil,
        keywords: [String] = [],
        summary: [String] = [],
        wellnessNudge: String? = nil,
        triggers: [String] = [],
        healthKitMoodValue: Int? = nil,
        healthKitMoodCategory: String? = nil,
        healthKitUUID: String? = nil,
        detectedLanguage: String = "en",
        sleepDuration: Double? = nil,
        stepCount: Int? = nil,
        workoutMinutes: Int? = nil,
        voiceTranscribed: Bool = false
    ) {
        self.id = UUID()
        self.text = text
        self.sentiment = sentiment
        self.keywords = keywords
        self.summary = summary
        self.wellnessNudge = wellnessNudge
        self.triggers = triggers
        self.createdAt = Date()
        self.updatedAt = Date()
        self.healthKitMoodValue = healthKitMoodValue
        self.healthKitMoodCategory = healthKitMoodCategory
        self.healthKitUUID = healthKitUUID
        self.detectedLanguage = detectedLanguage
        self.sleepDuration = sleepDuration
        self.stepCount = stepCount
        self.workoutMinutes = workoutMinutes
        self.voiceTranscribed = voiceTranscribed
    }
}

