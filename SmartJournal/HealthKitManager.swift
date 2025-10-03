import Foundation
import HealthKit
import NaturalLanguage

@MainActor
class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    @Published var isAuthorized = false
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    
    // State of Mind categories
    private let stateOfMindType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
    
    // Additional HealthKit types for correlations
    private let sleepAnalysisType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    private let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    private let workoutType = HKObjectType.workoutType()
    
    // Mood mapping from sentiment to HealthKit values
    private let moodMapping: [String: (value: Int, category: String)] = [
        "excellent": (9, "Excellent"),
        "very_good": (8, "Very Good"),
        "good": (7, "Good"),
        "fair": (6, "Fair"),
        "neutral": (5, "Neutral"),
        "poor": (4, "Poor"),
        "very_poor": (3, "Very Poor"),
        "terrible": (2, "Terrible"),
        "awful": (1, "Awful")
    ]
    
    init() {
        // Don't request authorization immediately - wait until needed
        // This prevents crashes when Info.plist doesn't have usage descriptions
    }
    
            func requestAuthorization() async {
            guard HKHealthStore.isHealthDataAvailable() else {
                print("HealthKit is not available on this device")
                return
            }

            let typesToRead: Set<HKObjectType> = [
                stateOfMindType,
                sleepAnalysisType,
                stepCountType,
                workoutType
            ]

            let typesToWrite: Set<HKSampleType> = [
                stateOfMindType
            ]

            do {
                try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
                await MainActor.run {
                    self.isAuthorized = true
                }
            } catch {
                print("HealthKit authorization error: \(error)")
                await MainActor.run {
                    self.isAuthorized = false
                }
            }
        }
    
    func saveMoodToHealthKit(sentiment: Double, text: String, keywords: [String]) async -> (moodValue: Int, moodCategory: String, uuid: String)? {
        // Request authorization if not already authorized
        if !isAuthorized {
            await requestAuthorization()
        }
        
        guard isAuthorized else {
            print("HealthKit not authorized")
            return nil
        }
        
        // Convert sentiment score to HealthKit mood value (1-10)
        let moodValue = convertSentimentToHealthKitValue(sentiment)
        let moodCategory = getMoodCategory(for: moodValue)
        
        // Create HealthKit sample
        let sample = HKCategorySample(
            type: stateOfMindType,
            value: moodValue,
            start: Date(),
            end: Date(),
            metadata: [
                "source": "SmartJournal",
                "sentiment_score": sentiment,
                "keywords": keywords.joined(separator: ", "),
                "text_length": text.count
            ]
        )
        
        do {
            try await healthStore.save(sample)
            return (moodValue, moodCategory, sample.uuid.uuidString)
        } catch {
            print("Failed to save mood to HealthKit: \(error)")
            return nil
        }
    }
    
    func fetchMoodHistory(days: Int = 30) async -> [HKCategorySample] {
        guard isAuthorized else { return [] }
        
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate)!
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        
        let _ = HKSampleQuery(
            sampleType: stateOfMindType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
        ) { _, samples, error in
            if let error = error {
                print("Error fetching mood history: \(error)")
            }
        }
        
        return []
    }
    
    // MARK: - Health Data Correlations
    
    func fetchHealthDataForDate(_ date: Date) async -> (sleepDuration: Double?, stepCount: Int?, workoutMinutes: Double?) {
        guard isAuthorized else { return (nil, nil, nil) }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )
        
        async let sleepDuration = fetchSleepDuration(predicate: predicate)
        async let stepCount = fetchStepCount(predicate: predicate)
        async let workoutMinutes = fetchWorkoutMinutes(predicate: predicate)
        
        return await (sleepDuration, stepCount, workoutMinutes)
    }
    
    private func fetchSleepDuration(predicate: NSPredicate) async -> Double? {
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepAnalysisType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    print("Error fetching sleep data: \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let totalSleepHours = samples.reduce(0.0) { total, sample in
                    let duration = sample.endDate.timeIntervalSince(sample.startDate)
                    return total + (duration / 3600.0) // Convert to hours
                }
                
                continuation.resume(returning: totalSleepHours > 0 ? totalSleepHours : nil)
            }
            
            healthStore.execute(query)
        }
    }
    
    private func fetchStepCount(predicate: NSPredicate) async -> Int? {
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepCountType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    print("Error fetching step count: \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                
                let stepCount = statistics?.sumQuantity()?.doubleValue(for: HKUnit.count())
                continuation.resume(returning: stepCount.map { Int($0) })
            }
            
            healthStore.execute(query)
        }
    }
    
    private func fetchWorkoutMinutes(predicate: NSPredicate) async -> Double? {
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    print("Error fetching workout data: \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                
                guard let workouts = samples as? [HKWorkout] else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let totalMinutes = workouts.reduce(0.0) { total, workout in
                    return total + (workout.duration / 60.0) // Convert to minutes
                }
                
                continuation.resume(returning: totalMinutes > 0 ? totalMinutes : nil)
            }
            
            healthStore.execute(query)
        }
    }
    
    func calculateCorrelations(entries: [JournalEntry]) -> HealthCorrelations {
        var sleepMoodPairs: [(sleep: Double, mood: Double)] = []
        var stepMoodPairs: [(steps: Int, mood: Double)] = []
        var workoutMoodPairs: [(workout: Double, mood: Double)] = []
        
        for entry in entries {
            if let sentiment = entry.sentiment,
               let sleepDuration = entry.sleepDuration {
                sleepMoodPairs.append((sleep: sleepDuration, mood: sentiment))
            }
            
            if let sentiment = entry.sentiment,
               let stepCount = entry.stepCount {
                stepMoodPairs.append((steps: stepCount, mood: sentiment))
            }
            
            if let sentiment = entry.sentiment,
               let workoutMinutes = entry.workoutMinutes {
                workoutMoodPairs.append((workout: Double(workoutMinutes), mood: sentiment))
            }
        }
        
        let sleepCorrelation = calculatePearsonCorrelation(sleepMoodPairs.map { $0.sleep }, sleepMoodPairs.map { $0.mood })
        let stepCorrelation = calculatePearsonCorrelation(stepMoodPairs.map { Double($0.steps) }, stepMoodPairs.map { $0.mood })
        let workoutCorrelation = calculatePearsonCorrelation(workoutMoodPairs.map { $0.workout }, workoutMoodPairs.map { $0.mood })
        
        return HealthCorrelations(
            sleepCorrelation: sleepCorrelation,
            stepCorrelation: stepCorrelation,
            workoutCorrelation: workoutCorrelation,
            sleepMoodPairs: sleepMoodPairs,
            stepMoodPairs: stepMoodPairs,
            workoutMoodPairs: workoutMoodPairs
        )
    }
    
    private func calculatePearsonCorrelation(_ x: [Double], _ y: [Double]) -> Double? {
        guard x.count == y.count && x.count > 1 else { return nil }
        
        let n = Double(x.count)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map(*).reduce(0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)
        let sumY2 = y.map { $0 * $0 }.reduce(0, +)
        
        let numerator = (n * sumXY) - (sumX * sumY)
        let denominator = sqrt(((n * sumX2) - (sumX * sumX)) * ((n * sumY2) - (sumY * sumY)))
        
        guard denominator != 0 else { return nil }
        return numerator / denominator
    }
    
    func generateHealthInsights(entries: [JournalEntry]) -> [String] {
        var insights: [String] = []
        
        // Sleep insights
        let lowSleepEntries = entries.filter { $0.sleepDuration != nil && $0.sleepDuration! < 6.0 }
        let lowSleepMoodAvg = lowSleepEntries.compactMap { $0.sentiment }.reduce(0, +) / Double(max(lowSleepEntries.count, 1))
        
        if lowSleepEntries.count >= 3 && lowSleepMoodAvg < -0.3 {
            insights.append("Low mood often follows <6h sleep")
        }
        
        // Step insights
        let highStepEntries = entries.filter { $0.stepCount != nil && $0.stepCount! >= 7000 }
        let highStepMoodAvg = highStepEntries.compactMap { $0.sentiment }.reduce(0, +) / Double(max(highStepEntries.count, 1))
        
        if highStepEntries.count >= 3 && highStepMoodAvg > 0.3 {
            insights.append("Best mood on days with 7k+ steps")
        }
        
        // Workout insights
        let workoutEntries = entries.filter { $0.workoutMinutes != nil && $0.workoutMinutes! > 0 }
        let workoutMoodAvg = workoutEntries.compactMap { $0.sentiment }.reduce(0, +) / Double(max(workoutEntries.count, 1))
        
        if workoutEntries.count >= 3 && workoutMoodAvg > 0.2 {
            insights.append("Exercise days show improved mood")
        }
        
        return insights
    }
    
    private func convertSentimentToHealthKitValue(_ sentiment: Double) -> Int {
        // Map sentiment score (-1 to 1) to HealthKit mood value (1-10)
        let normalizedSentiment = (sentiment + 1) / 2 // Convert to 0-1 range
        let healthKitValue = Int(round(normalizedSentiment * 9)) + 1 // Convert to 1-10 range
        return max(1, min(10, healthKitValue))
    }
    
    private func getMoodCategory(for value: Int) -> String {
        switch value {
        case 9...10: return "Excellent"
        case 8: return "Very Good"
        case 7: return "Good"
        case 6: return "Fair"
        case 5: return "Neutral"
        case 4: return "Poor"
        case 3: return "Very Poor"
        case 2: return "Terrible"
        case 1: return "Awful"
        default: return "Neutral"
        }
    }
    
    func generateWellnessNudge(sentiment: Double, keywords: [String], triggers: [String]) -> String {
        var suggestions: [String] = []
        
        // Sentiment-based suggestions
        if sentiment < -0.3 {
            suggestions.append("Consider taking a few deep breaths")
            suggestions.append("Try a short mindfulness exercise")
            suggestions.append("Reach out to a friend or family member")
        } else if sentiment > 0.3 {
            suggestions.append("Channel this positive energy into a creative activity")
            suggestions.append("Share your good mood with someone else")
            suggestions.append("Document what made today special")
        } else {
            suggestions.append("Take a moment to reflect on your day")
            suggestions.append("Consider what would make you feel better")
            suggestions.append("Try a quick stretching break")
        }
        
        // Keyword-based suggestions
        if keywords.contains(where: { $0.lowercased().contains("work") || $0.lowercased().contains("stress") }) {
            suggestions.append("Set boundaries for work-life balance")
        }
        
        if keywords.contains(where: { $0.lowercased().contains("sleep") || $0.lowercased().contains("tired") }) {
            suggestions.append("Consider your sleep hygiene tonight")
        }
        
        if keywords.contains(where: { $0.lowercased().contains("exercise") || $0.lowercased().contains("workout") }) {
            suggestions.append("Great job staying active!")
        }
        
        // Trigger-based suggestions
        if !triggers.isEmpty {
            suggestions.append("Notice patterns in what affects your mood")
        }
        
        return suggestions.randomElement() ?? "Take a moment to breathe and center yourself"
    }
}

// MARK: - Health Correlations Data Structure
struct HealthCorrelations {
    let sleepCorrelation: Double?
    let stepCorrelation: Double?
    let workoutCorrelation: Double?
    let sleepMoodPairs: [(sleep: Double, mood: Double)]
    let stepMoodPairs: [(steps: Int, mood: Double)]
    let workoutMoodPairs: [(workout: Double, mood: Double)]
}
