import SwiftUI
import HealthKit

struct ContentView: View {
    @EnvironmentObject var watchConnectivityManager: WatchConnectivityManager
    @StateObject private var healthKitManager = WatchHealthKitManager()
    
    let moods = [
        ("😢", "Very Bad", 1),
        ("😔", "Bad", 3),
        ("😐", "Okay", 5),
        ("😊", "Good", 7),
        ("😄", "Very Good", 9)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 8) {
                        Text("How are you feeling?")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        
                        Text(watchConnectivityManager.lastMoodTime.formatted(date: .omitted, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)
                    
                    // Mood Buttons
                    VStack(spacing: 12) {
                        ForEach(moods, id: \.0) { emoji, label, value in
                            Button(action: {
                                recordMood(emoji: emoji, value: value)
                            }) {
                                HStack(spacing: 8) {
                                    Text(emoji)
                                        .font(.title2)
                                    Text(label)
                                        .font(.body.weight(.medium))
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // Last Mood Display
                    if watchConnectivityManager.lastMood != "😐" {
                        VStack(spacing: 8) {
                            Text("Last recorded:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            HStack(spacing: 8) {
                                Text(watchConnectivityManager.lastMood)
                                    .font(.title2)
                                Text(watchConnectivityManager.lastMoodTime.formatted(date: .omitted, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.top, 8)
                    }
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("SmartJournal")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func recordMood(emoji: String, value: Int) {
        // Save to HealthKit
        Task {
            await healthKitManager.saveMoodToHealthKit(value: value)
        }
        
        // Send to iPhone
        watchConnectivityManager.sendMoodToiPhone(mood: emoji, value: value)
        
        // Update local state
        watchConnectivityManager.lastMood = emoji
        watchConnectivityManager.lastMoodTime = Date()
        
        // Haptic feedback
        WKInterfaceDevice.current().play(.success)
    }
}

class WatchHealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    
    init() {
        requestAuthorization()
    }
    
    private func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        ]
        
        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        ]
        
        healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { success, error in
            if let error = error {
                print("HealthKit authorization failed: \(error)")
            }
        }
    }
    
    func saveMoodToHealthKit(value: Int) async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        // Convert mood value to HealthKit State of Mind category
        let moodCategory: HKCategoryValueStateOfMind
        switch value {
        case 1...2: moodCategory = .veryUnpleasant
        case 3...4: moodCategory = .unpleasant
        case 5: moodCategory = .neutral
        case 6...7: moodCategory = .pleasant
        case 8...10: moodCategory = .veryPleasant
        default: moodCategory = .neutral
        }
        
        let sample = HKCategorySample(
            type: HKObjectType.categoryType(forIdentifier: .stateOfMind)!,
            value: moodCategory.rawValue,
            start: Date(),
            end: Date()
        )
        
        do {
            try await healthStore.save(sample)
            print("Mood saved to HealthKit: \(moodCategory)")
        } catch {
            print("Failed to save mood to HealthKit: \(error)")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WatchConnectivityManager())
}
