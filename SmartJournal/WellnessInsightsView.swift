import SwiftUI
import SwiftData
import Charts

struct WellnessInsightsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    
    @State private var selectedTimeframe: Timeframe = .week
    @State private var showingPrivacySettings = false
    
    enum Timeframe: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 24) {
                    // Wellness Score Card
                    wellnessScoreCard
                    
                    // Mood Trends Chart
                    moodTrendsChart
                    
                    // Trigger Analysis
                    triggerAnalysisCard
                    
                    // Wellness Suggestions
                    wellnessSuggestionsCard
                    
                    // Health Correlations
                    healthCorrelationsCard
                    
                    // Privacy Status
                    privacyStatusCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .navigationTitle("Wellness Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingPrivacySettings = true }) {
                        Image(systemName: "lock.shield")
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
        .sheet(isPresented: $showingPrivacySettings) {
            PrivacySettingsView()
        }
    }
    
    // MARK: - Wellness Score Card
    private var wellnessScoreCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "heart.fill")
                    .font(.title2)
                    .foregroundStyle(.red)
                Text("Wellness Score")
                    .font(.title2.weight(.bold))
                Spacer()
                
                Picker("Timeframe", selection: $selectedTimeframe) {
                    ForEach(Timeframe.allCases, id: \.self) { timeframe in
                        Text(timeframe.rawValue).tag(timeframe)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 200)
            }
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(wellnessScore, specifier: "%.0f")")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(wellnessScoreColor)
                    
                    Text(wellnessScoreDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text("Trend")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: wellnessTrendIcon)
                            .foregroundStyle(wellnessTrendColor)
                        Text("\(wellnessTrend, specifier: "%.1f")%")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(wellnessTrendColor)
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
        )
    }
    
    // MARK: - Mood Trends Chart
    private var moodTrendsChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Mood Trends", systemImage: "chart.line.uptrend.xyaxis")
                .font(.headline)
            
            Chart {
                ForEach(filteredEntriesForTimeframe(), id: \.createdAt) { entry in
                    if let sentiment = entry.sentiment {
                        LineMark(
                            x: .value("Date", entry.createdAt),
                            y: .value("Sentiment", sentiment)
                        )
                        .foregroundStyle(moodColor(for: sentiment))
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        
                        PointMark(
                            x: .value("Date", entry.createdAt),
                            y: .value("Sentiment", sentiment)
                        )
                        .foregroundStyle(moodColor(for: sentiment))
                    }
                }
            }
            .frame(height: 200)
            .chartYScale(domain: -1...1)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.day().month())
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
    
    // MARK: - Trigger Analysis Card
    private var triggerAnalysisCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Emotional Triggers", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            
            if triggerFrequency.isEmpty {
                Text("No triggers detected yet. Keep journaling to identify patterns.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(Array(triggerFrequency.prefix(6)), id: \.key) { trigger, count in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(trigger.capitalized)
                                .font(.subheadline.weight(.medium))
                            Text("\(count) times")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
    
    // MARK: - Wellness Suggestions Card
    private var wellnessSuggestionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Personalized Suggestions", systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundStyle(.yellow)
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(personalizedSuggestions, id: \.self) { suggestion in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                            .padding(.top, 2)
                        Text(suggestion)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
    
    // MARK: - Privacy Status Card
    private var privacyStatusCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Privacy Status", systemImage: "lock.shield.fill")
                .font(.headline)
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading, spacing: 8) {
                PrivacyStatusRow(
                    title: "Data Encryption",
                    status: "Enabled",
                    icon: "checkmark.shield.fill",
                    color: .green
                )
                
                PrivacyStatusRow(
                    title: "On-Device Processing",
                    status: "Active",
                    icon: "iphone",
                    color: .blue
                )
                
                PrivacyStatusRow(
                    title: "HealthKit Integration",
                    status: "Connected",
                    icon: "heart.fill",
                    color: .red
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
    
    // MARK: - Computed Properties
    
    private var wellnessScore: Double {
        let recentEntries = filteredEntriesForTimeframe()
        guard !recentEntries.isEmpty else { return 0 }
        
        let averageSentiment = recentEntries.compactMap { $0.sentiment }.reduce(0, +) / Double(recentEntries.count)
        return (averageSentiment + 1) * 50 // Convert to 0-100 scale
    }
    
    private var wellnessScoreColor: Color {
        if wellnessScore >= 70 { return .green }
        if wellnessScore >= 50 { return .orange }
        return .red
    }
    
    private var wellnessScoreDescription: String {
        if wellnessScore >= 70 { return "Excellent" }
        if wellnessScore >= 50 { return "Good" }
        return "Needs attention"
    }
    
    private var wellnessTrend: Double {
        // Calculate trend based on recent entries
        let recentEntries = filteredEntriesForTimeframe()
        guard recentEntries.count >= 2 else { return 0 }
        
        let sortedEntries = recentEntries.sorted { $0.createdAt < $1.createdAt }
        let firstHalf = Array(sortedEntries.prefix(sortedEntries.count / 2))
        let secondHalf = Array(sortedEntries.suffix(sortedEntries.count / 2))
        
        let firstAvg = firstHalf.compactMap { $0.sentiment }.reduce(0, +) / Double(firstHalf.count)
        let secondAvg = secondHalf.compactMap { $0.sentiment }.reduce(0, +) / Double(secondHalf.count)
        
        return ((secondAvg - firstAvg) / abs(firstAvg)) * 100
    }
    
    private var wellnessTrendIcon: String {
        if wellnessTrend > 5 { return "arrow.up" }
        if wellnessTrend < -5 { return "arrow.down" }
        return "arrow.right"
    }
    
    private var wellnessTrendColor: Color {
        if wellnessTrend > 5 { return .green }
        if wellnessTrend < -5 { return .red }
        return .gray
    }
    
    private var triggerFrequency: [(key: String, value: Int)] {
        let allTriggers = entries.flatMap { $0.triggers }
        let frequency = Dictionary(grouping: allTriggers, by: { $0 })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        return Array(frequency)
    }
    
    private var personalizedSuggestions: [String] {
        var suggestions: [String] = []
        
        if wellnessScore < 50 {
            suggestions.append("Consider practicing mindfulness for 5 minutes daily")
            suggestions.append("Try to identify what's causing stress in your life")
        }
        
        if triggerFrequency.contains(where: { $0.key == "stress" }) {
            suggestions.append("Set clear boundaries between work and personal time")
        }
        
        if triggerFrequency.contains(where: { $0.key == "work" }) {
            suggestions.append("Take regular breaks during your workday")
        }
        
        if wellnessTrend < -5 {
            suggestions.append("Consider talking to a friend or professional about your feelings")
        }
        
        if suggestions.isEmpty {
            suggestions.append("Keep up the great work with your journaling practice!")
        }
        
        return suggestions
    }
    
    // MARK: - Health Correlations Card
    private var healthCorrelationsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text("Health Correlations")
                    .font(.title2.weight(.bold))
                Spacer()
            }
            
            let filteredEntries = filteredEntriesForTimeframe()
            let healthKitManager = HealthKitManager()
            let correlations = healthKitManager.calculateCorrelations(entries: filteredEntries)
            let insights = healthKitManager.generateHealthInsights(entries: filteredEntries)
            
            if !insights.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Key Insights")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    ForEach(insights, id: \.self) { insight in
                        HStack(alignment: .top) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(insight)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            // Correlation summary
            if let sleepCorr = correlations.sleepCorrelation,
               let stepCorr = correlations.stepCorrelation,
               let workoutCorr = correlations.workoutCorrelation {
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Correlation Strength")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 8) {
                        CorrelationStrengthRow(
                            title: "Sleep",
                            correlation: sleepCorr,
                            icon: "bed.double.fill"
                        )
                        
                        CorrelationStrengthRow(
                            title: "Steps",
                            correlation: stepCorr,
                            icon: "figure.walk"
                        )
                        
                        CorrelationStrengthRow(
                            title: "Workout",
                            correlation: workoutCorr,
                            icon: "dumbbell.fill"
                        )
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            if insights.isEmpty && correlations.sleepCorrelation == nil {
                Text("Add more entries with health data to see correlations")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Helper Methods
    
    private func filteredEntriesForTimeframe() -> [JournalEntry] {
        let calendar = Calendar.current
        let now = Date()
        
        let startDate: Date
        switch selectedTimeframe {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now)!
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now)!
        case .quarter:
            startDate = calendar.date(byAdding: .month, value: -3, to: now)!
        }
        
        return entries.filter { $0.createdAt >= startDate }
    }
    
    private func moodColor(for sentiment: Double?) -> Color {
        guard let sentiment = sentiment else { return .gray }
        if sentiment > 0.3 { return .green }
        if sentiment < -0.3 { return .red }
        return .orange
    }
}

// MARK: - Privacy Status Row
struct PrivacyStatusRow: View {
    let title: String
    let status: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(status)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Privacy Settings View
struct PrivacySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var privacyManager = PrivacyManager()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Data Protection") {
                    Toggle("Enable Data Encryption", isOn: $privacyManager.isDataEncrypted)
                    Toggle("Biometric Authentication", isOn: $privacyManager.biometricAuthEnabled)
                    Toggle("Auto-Lock App", isOn: $privacyManager.autoLockEnabled)
                }
                
                Section("Data Retention") {
                    Picker("Keep Data For", selection: .constant(30)) {
                        Text("7 days").tag(7)
                        Text("30 days").tag(30)
                        Text("90 days").tag(90)
                        Text("1 year").tag(365)
                        Text("Forever").tag(0)
                    }
                }
                
                Section("Privacy Controls") {
                    Toggle("Opt out of Analytics", isOn: .constant(false))
                    Button("Export My Data") {
                        // Export functionality
                    }
                    Button("Delete All Data", role: .destructive) {
                        privacyManager.deleteAllData()
                    }
                }
            }
            .navigationTitle("Privacy Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Correlation Strength Row
struct CorrelationStrengthRow: View {
    let title: String
    let correlation: Double
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(correlationColor(correlation))
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(correlationDescription(correlation))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func correlationColor(_ correlation: Double) -> Color {
        let absCorrelation = abs(correlation)
        if absCorrelation > 0.7 {
            return correlation > 0 ? .green : .red
        } else if absCorrelation > 0.4 {
            return correlation > 0 ? .blue : .orange
        } else {
            return .gray
        }
    }
    
    private func correlationDescription(_ correlation: Double) -> String {
        let absCorrelation = abs(correlation)
        if absCorrelation > 0.7 {
            return correlation > 0 ? "Strong Positive" : "Strong Negative"
        } else if absCorrelation > 0.4 {
            return correlation > 0 ? "Moderate Positive" : "Moderate Negative"
        } else if absCorrelation > 0.2 {
            return correlation > 0 ? "Weak Positive" : "Weak Negative"
        } else {
            return "No Correlation"
        }
    }
}
