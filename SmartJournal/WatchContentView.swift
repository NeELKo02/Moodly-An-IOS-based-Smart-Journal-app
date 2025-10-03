import SwiftUI
import SwiftData
import WatchConnectivity

struct WatchContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @EnvironmentObject private var watchConnectivityManager: WatchConnectivityManager
    
    @State private var showingMoodPicker = false
    @State private var showingRecentEntries = false
    @State private var selectedMood: Int = 5
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 8) {
                        Text("SmartJournal")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.semibold)
                        
                        Text("How are you feeling?")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)
                    
                    // Quick Mood Button
                    Button(action: { showingMoodPicker = true }) {
                        VStack(spacing: 8) {
                            Image(systemName: "face.smiling")
                                .font(.system(size: 32))
                                .foregroundStyle(.blue)
                            
                            Text("Log Mood")
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    
                    // Today's Stats
                    if !entries.isEmpty {
                        VStack(spacing: 12) {
                            HStack {
                                Text("Today")
                                    .font(.system(.caption, design: .rounded))
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            
                            HStack(spacing: 16) {
                                StatItem(
                                    title: "Entries",
                                    value: "\(todayEntriesCount)",
                                    icon: "book.fill",
                                    color: .blue
                                )
                                
                                StatItem(
                                    title: "Mood",
                                    value: averageMoodEmoji,
                                    icon: "face.smiling",
                                    color: .orange
                                )
                            }
                        }
                        .padding(16)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Recent Entries Preview
                    if !entries.isEmpty {
                        Button(action: { showingRecentEntries = true }) {
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Recent")
                                        .font(.system(.caption, design: .rounded))
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                
                                // Show last 2 entries
                                VStack(spacing: 8) {
                                    ForEach(entries.prefix(2), id: \.id) { entry in
                                        HStack(spacing: 8) {
                                            Text(moodEmoji(for: entry.sentiment ?? 0.0))
                                                .font(.title3)
                                            
                                            Text(entry.text.prefix(20) + (entry.text.count > 20 ? "..." : ""))
                                                .font(.system(.caption2, design: .rounded))
                                                .lineLimit(1)
                                                .foregroundStyle(.secondary)
                                            
                                            Spacer()
                                        }
                                    }
                                }
                            }
                            .padding(16)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Connection Status
                    HStack {
                        Image(systemName: watchConnectivityManager.isWatchConnected ? "iphone" : "iphone.slash")
                            .font(.caption)
                            .foregroundStyle(watchConnectivityManager.isWatchConnected ? .green : .red)
                        
                        Text(watchConnectivityManager.isWatchConnected ? "Connected" : "Disconnected")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 16)
            }
        }
        .sheet(isPresented: $showingMoodPicker) {
            MoodPickerView(selectedMood: $selectedMood) { mood in
                logMood(mood)
                showingMoodPicker = false
            }
        }
        .sheet(isPresented: $showingRecentEntries) {
            RecentEntriesView(entries: entries)
        }
    }
    
    // MARK: - Computed Properties
    
    private var todayEntriesCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return entries.filter { entry in
            calendar.isDate(entry.createdAt, inSameDayAs: today)
        }.count
    }
    
    private var averageMoodEmoji: String {
        let todayEntries = entries.filter { entry in
            Calendar.current.isDate(entry.createdAt, inSameDayAs: Date())
        }
        
        if todayEntries.isEmpty { return "😐" }
        
        let averageSentiment = todayEntries.compactMap { $0.sentiment }.reduce(0, +) / Double(todayEntries.count)
        return moodEmoji(for: averageSentiment)
    }
    
    // MARK: - Helper Methods
    
    private func logMood(_ mood: Int) {
        let moodEmoji = moodEmojiForValue(mood)
        let sentimentScore = sentimentForValue(mood)
        
        // Create quick entry
        let entry = JournalEntry(
            text: "Quick mood: \(moodEmoji) (Watch)",
            sentiment: sentimentScore,
            keywords: ["watch", "mood", "quick"],
            summary: ["Quick mood recorded from Apple Watch"],
            healthKitMoodValue: mood,
            healthKitMoodCategory: moodCategoryForValue(mood),
            detectedLanguage: "en",
            voiceTranscribed: false
        )
        
        context.insert(entry)
        
        // Send to iPhone
        watchConnectivityManager.sendMoodToPhone(mood: moodEmoji, value: mood)
        
        // Haptic feedback
        // Haptic feedback for iOS
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    private func moodEmojiForValue(_ value: Int) -> String {
        switch value {
        case 1...2: return "😢"
        case 3...4: return "😔"
        case 5: return "😐"
        case 6...7: return "🙂"
        case 8...10: return "😊"
        default: return "😐"
        }
    }
    
    private func sentimentForValue(_ value: Int) -> Double {
        switch value {
        case 1...2: return -0.8
        case 3...4: return -0.4
        case 5: return 0.0
        case 6...7: return 0.4
        case 8...10: return 0.8
        default: return 0.0
        }
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
    
    private func moodEmoji(for sentiment: Double) -> String {
        switch sentiment {
        case -1.0..<(-0.6): return "😢"
        case -0.6..<(-0.2): return "😔"
        case -0.2..<0.2: return "😐"
        case 0.2..<0.6: return "🙂"
        case 0.6..<1.0: return "😊"
        default: return "😐"
        }
    }
}

// MARK: - Stat Item Component

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(.caption, design: .rounded))
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

