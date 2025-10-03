import Foundation
import UserNotifications
import SwiftData

@MainActor
class NudgeManager: ObservableObject {
    @Published var notificationsEnabled = false
    @Published var breathingRemindersEnabled = true
    @Published var sleepRemindersEnabled = true
    @Published var wellnessInsightsEnabled = true
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    init() {
        loadSettings()
        checkNotificationPermissions()
    }
    
    func loadSettings() {
        let defaults = UserDefaults.standard
        breathingRemindersEnabled = defaults.bool(forKey: "breathingRemindersEnabled")
        sleepRemindersEnabled = defaults.bool(forKey: "sleepRemindersEnabled")
        wellnessInsightsEnabled = defaults.bool(forKey: "wellnessInsightsEnabled")
    }
    
    func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(breathingRemindersEnabled, forKey: "breathingRemindersEnabled")
        defaults.set(sleepRemindersEnabled, forKey: "sleepRemindersEnabled")
        defaults.set(wellnessInsightsEnabled, forKey: "wellnessInsightsEnabled")
    }
    
    func checkNotificationPermissions() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestNotificationPermissions() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.notificationsEnabled = granted
            }
            return granted
        } catch {
            print("Error requesting notification permissions: \(error)")
            return false
        }
    }
    
    func analyzeAndScheduleNudges(entries: [JournalEntry]) {
        guard notificationsEnabled else { return }
        
        // Clear existing notifications
        notificationCenter.removeAllPendingNotificationRequests()
        
        // Analyze recent mood patterns
        let recentEntries = entries.sorted { $0.createdAt > $1.createdAt }.prefix(5)
        let recentSentiments = recentEntries.compactMap { $0.sentiment }
        
        // Check for low mood pattern
        if recentSentiments.count >= 3 {
            let averageSentiment = recentSentiments.reduce(0, +) / Double(recentSentiments.count)
            if averageSentiment < -0.5 && breathingRemindersEnabled {
                scheduleBreathingReminder()
            }
        }
        
        // Check sleep patterns
        let sleepEntries = entries.filter { $0.sleepDuration != nil }.suffix(5)
        if sleepEntries.count >= 3 {
            let averageSleep = sleepEntries.compactMap { $0.sleepDuration }.reduce(0, +) / Double(sleepEntries.count)
            if averageSleep < 7.0 && sleepRemindersEnabled {
                scheduleSleepReminder()
            }
        }
        
        // Schedule wellness insights
        if wellnessInsightsEnabled {
            scheduleWellnessInsights()
        }
    }
    
    private func scheduleBreathingReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Take a Moment"
        content.body = "A 2-minute breathing break might help. Open Mindfulness app?"
        content.sound = .default
        content.categoryIdentifier = "BREATHING"
        
        // Schedule for 30 minutes from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 30 * 60, repeats: false)
        let request = UNNotificationRequest(identifier: "breathing-reminder", content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling breathing reminder: \(error)")
            }
        }
    }
    
    private func scheduleSleepReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Bedtime Reminder"
        content.body = "Getting enough sleep helps your mood. Consider winding down soon."
        content.sound = .default
        content.categoryIdentifier = "SLEEP"
        
        // Schedule for 9 PM tonight
        var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: Date())
        dateComponents.hour = 21
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "sleep-reminder", content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling sleep reminder: \(error)")
            }
        }
    }
    
    private func scheduleWellnessInsights() {
        let content = UNMutableNotificationContent()
        content.title = "Wellness Insight"
        content.body = "Check your SmartJournal for personalized wellness insights and mood patterns."
        content.sound = .default
        content.categoryIdentifier = "WELLNESS"
        
        // Schedule for tomorrow morning
        var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: Date())
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "wellness-insight", content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling wellness insight: \(error)")
            }
        }
    }
    
    func setupNotificationCategories() {
        let breathingCategory = UNNotificationCategory(
            identifier: "BREATHING",
            actions: [
                UNNotificationAction(identifier: "open-mindfulness", title: "Open Mindfulness", options: [.foreground]),
                UNNotificationAction(identifier: "dismiss", title: "Dismiss", options: [])
            ],
            intentIdentifiers: [],
            options: []
        )
        
        let sleepCategory = UNNotificationCategory(
            identifier: "SLEEP",
            actions: [
                UNNotificationAction(identifier: "open-health", title: "Open Health", options: [.foreground]),
                UNNotificationAction(identifier: "dismiss", title: "Dismiss", options: [])
            ],
            intentIdentifiers: [],
            options: []
        )
        
        let wellnessCategory = UNNotificationCategory(
            identifier: "WELLNESS",
            actions: [
                UNNotificationAction(identifier: "open-journal", title: "Open Journal", options: [.foreground]),
                UNNotificationAction(identifier: "dismiss", title: "Dismiss", options: [])
            ],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([breathingCategory, sleepCategory, wellnessCategory])
    }
    
    func generatePersonalizedNudge(entries: [JournalEntry]) -> String? {
        let recentEntries = entries.sorted { $0.createdAt > $1.createdAt }.prefix(7)
        let recentSentiments = recentEntries.compactMap { $0.sentiment }
        
        guard !recentSentiments.isEmpty else { return nil }
        
        let averageSentiment = recentSentiments.reduce(0, +) / Double(recentSentiments.count)
        
        if averageSentiment < -0.4 {
            return "Consider a 2-minute breathing break. Your recent mood suggests you might benefit from a moment of mindfulness."
        } else if averageSentiment > 0.4 {
            return "Great energy! Consider channeling this positive mood into a creative activity or sharing it with someone."
        } else {
            return "Take a moment to reflect on what would make you feel better today."
        }
    }
}
