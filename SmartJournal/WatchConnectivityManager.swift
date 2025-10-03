import Foundation
import WatchConnectivity
import SwiftData

class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    @Published var lastWatchMood: String = "😐"
    @Published var lastWatchMoodTime: Date = Date()
    @Published var isWatchConnected: Bool = false
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isWatchConnected = session.isReachable
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchConnected = false
        }
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchConnected = false
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let mood = message["mood"] as? String,
               let value = message["value"] as? Int,
               let timestamp = message["timestamp"] as? TimeInterval {
                
                self.lastWatchMood = mood
                self.lastWatchMoodTime = Date(timeIntervalSince1970: timestamp)
                
                // Save to HealthKit
                Task {
                    await self.saveWatchMoodToHealthKit(value: value)
                }
                
                // Create a quick journal entry from watch mood
                self.createQuickEntryFromWatch(mood: mood, value: value)
            }
        }
    }
    
    // MARK: - HealthKit Integration
    
    private func saveWatchMoodToHealthKit(value: Int) async {
        // This would integrate with your existing HealthKitManager
        // For now, we'll just log the mood
        print("Watch mood saved to HealthKit: \(value)")
    }
    
    // MARK: - Quick Entry Creation
    
    @MainActor
    private func createQuickEntryFromWatch(mood: String, value: Int) {
        // Convert watch mood value to sentiment score
        let sentimentScore: Double
        switch value {
        case 1...2: sentimentScore = -0.8
        case 3...4: sentimentScore = -0.4
        case 5: sentimentScore = 0.0
        case 6...7: sentimentScore = 0.4
        case 8...10: sentimentScore = 0.8
        default: sentimentScore = 0.0
        }
        
        // Create a quick entry using CoreData
        CoreDataManager.shared.createJournalEntry(
            text: "Quick mood check: \(mood) (Watch)",
            sentiment: sentimentScore,
            keywords: ["watch", "mood", "quick"],
            summary: ["Quick mood recorded from Apple Watch"],
            wellnessNudge: nil,
            triggers: [],
            healthKitMoodValue: value,
            healthKitMoodCategory: moodCategoryForValue(value),
            healthKitUUID: nil,
            detectedLanguage: "en",
            sleepDuration: nil,
            stepCount: nil,
            workoutMinutes: nil,
            voiceTranscribed: false
        )
        
        print("Quick entry created from watch: Quick mood check: \(mood) (Watch)")
    }
    
    private func moodCategoryForValue(_ value: Int) -> String {
        switch value {
        case 1...2: return "Very Unpleasant"
        case 3...4: return "Unpleasant"
        case 5: return "Neutral"
        case 6...7: return "Pleasant"
        case 8...10: return "Very Pleasant"
        default: return "Neutral"
        }
    }
    
    // MARK: - Send Data to Watch
    
    func sendJournalStatsToWatch(entries: [JournalEntry]) {
        guard WCSession.default.isReachable else { return }
        
        let totalEntries = entries.count
        let avgSentiment = entries.compactMap { $0.sentiment }.reduce(0, +) / Double(max(entries.count, 1))
        
        let message: [String: Any] = [
            "totalEntries": totalEntries,
            "avgSentiment": avgSentiment,
            "lastEntryDate": entries.first?.createdAt.timeIntervalSince1970 ?? 0
        ]
        
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("Failed to send stats to watch: \(error)")
        }
    }
    
    // MARK: - Send Mood to Phone (for Watch app)
    
    func sendMoodToPhone(mood: String, value: Int) {
        guard WCSession.default.isReachable else { return }
        
        let message: [String: Any] = [
            "mood": mood,
            "value": value,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("Failed to send mood to phone: \(error)")
        }
    }
}
