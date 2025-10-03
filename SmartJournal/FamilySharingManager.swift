import SwiftUI
import MessageUI
import SwiftData

class FamilySharingManager: ObservableObject {
    static let shared = FamilySharingManager()
    
    @Published var isSharingEnabled: Bool = false
    @Published var includeRawText: Bool = false
    @Published var selectedMonth: Date = Date()
    
    private init() {}
    
    func generateFamilyShareablePDF(entries: [JournalEntry]) -> Data? {
        // Filter entries for the selected month
        let calendar = Calendar.current
        let monthStart = calendar.dateInterval(of: .month, for: selectedMonth)?.start ?? selectedMonth
        let monthEnd = calendar.dateInterval(of: .month, for: selectedMonth)?.end ?? selectedMonth
        
        let monthlyEntries = entries.filter { entry in
            entry.createdAt >= monthStart && entry.createdAt < monthEnd
        }
        
        // Generate sanitized PDF (no raw text unless explicitly opted in)
        return PDFExporter.shared.generateMonthlyReport(
            entries: monthlyEntries,
            month: selectedMonth,
            includeRawText: includeRawText
        )
    }
    
    func shareMonthlySummary(entries: [JournalEntry]) {
        guard let pdfData = generateFamilyShareablePDF(entries: entries) else {
            print("Failed to generate PDF for family sharing")
            return
        }
        
        // Save PDF to temporary file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SmartJournal_Summary_\(selectedMonth.formatted(.dateTime.month().year())).pdf")
        
        do {
            try pdfData.write(to: tempURL)
            
            // Create share sheet
            let activityVC = UIActivityViewController(
                activityItems: [tempURL],
                applicationActivities: nil
            )
            
            // Present share sheet
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(activityVC, animated: true)
            }
        } catch {
            print("Failed to save PDF: \(error)")
        }
    }
    
    func getMonthlySummaryText(entries: [JournalEntry]) -> String {
        let calendar = Calendar.current
        let monthStart = calendar.dateInterval(of: .month, for: selectedMonth)?.start ?? selectedMonth
        let monthEnd = calendar.dateInterval(of: .month, for: selectedMonth)?.end ?? selectedMonth
        
        let monthlyEntries = entries.filter { entry in
            entry.createdAt >= monthStart && entry.createdAt < monthEnd
        }
        
        var summary = "📊 SmartJournal Monthly Summary\n"
        summary += "📅 \(selectedMonth.formatted(.dateTime.month(.wide).year()))\n\n"
        
        // Total entries
        summary += "📝 Total Entries: \(monthlyEntries.count)\n"
        
        // Average sentiment
        let avgSentiment = monthlyEntries.compactMap { $0.sentiment }.reduce(0, +) / Double(max(monthlyEntries.count, 1))
        summary += "😊 Average Mood: \(String(format: "%.2f", avgSentiment))\n"
        
        // Top keywords
        let allKeywords = monthlyEntries.flatMap { $0.keywords }
        let keywordCounts = Dictionary(grouping: allKeywords, by: { $0 })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .prefix(3)
        
        if !keywordCounts.isEmpty {
            summary += "🏷️ Top Topics: \(keywordCounts.map { $0.key }.joined(separator: ", "))\n"
        }
        
        // Voice entries
        let voiceEntries = monthlyEntries.filter { $0.voiceTranscribed }.count
        summary += "🎤 Voice Entries: \(voiceEntries) of \(monthlyEntries.count)\n"
        
        // Wellness insights
        let positiveEntries = monthlyEntries.filter { ($0.sentiment ?? 0) > 0.3 }.count
        let negativeEntries = monthlyEntries.filter { ($0.sentiment ?? 0) < -0.3 }.count
        
        summary += "\n💚 Positive Days: \(positiveEntries)\n"
        summary += "💙 Challenging Days: \(negativeEntries)\n"
        
        if includeRawText {
            summary += "\n📖 Selected Journal Snippets:\n"
            let snippets = monthlyEntries.prefix(3).map { entry in
                let date = entry.createdAt.formatted(date: .abbreviated, time: .omitted)
                let preview = String(entry.text.prefix(100))
                return "• \(date): \(preview)..."
            }
            summary += snippets.joined(separator: "\n")
        }
        
        return summary
    }
}

// MARK: - Family Sharing View
struct FamilySharingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var familySharingManager = FamilySharingManager.shared
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)
                    
                    Text("Share Monthly Summary")
                        .font(.title2.weight(.bold))
                    
                    Text("Share your wellness journey with family and friends")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Month Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select Month")
                        .font(.headline)
                    
                    Picker("Month", selection: $familySharingManager.selectedMonth) {
                        ForEach(getAvailableMonths(), id: \.self) { month in
                            Text(month.formatted(.dateTime.month(.wide).year()))
                                .tag(month)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                }
                .padding(.horizontal, 20)
                
                // Privacy Options
                VStack(alignment: .leading, spacing: 16) {
                    Text("Privacy Settings")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        Toggle(isOn: $familySharingManager.includeRawText) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Include Journal Text")
                                    .font(.body.weight(.medium))
                                Text("Share actual journal entries (default: metrics only)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .tint(.blue)
                    }
                }
                .padding(.horizontal, 20)
                
                // Preview
                VStack(alignment: .leading, spacing: 12) {
                    Text("Preview")
                        .font(.headline)
                    
                    ScrollView {
                        Text(familySharingManager.getMonthlySummaryText(entries: entries))
                            .font(.body)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                    }
                    .frame(maxHeight: 200)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        familySharingManager.shareMonthlySummary(entries: entries)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Summary")
                        }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.blue)
                        )
                    }
                    
                    Button(action: {
                        // Export PDF to Files app
                        if let pdfData = familySharingManager.generateFamilyShareablePDF(entries: entries) {
                            let tempURL = FileManager.default.temporaryDirectory
                                .appendingPathComponent("SmartJournal_Summary_\(familySharingManager.selectedMonth.formatted(.dateTime.month().year())).pdf")
                            
                            do {
                                try pdfData.write(to: tempURL)
                                let activityVC = UIActivityViewController(
                                    activityItems: [tempURL],
                                    applicationActivities: nil
                                )
                                
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let window = windowScene.windows.first {
                                    window.rootViewController?.present(activityVC, animated: true)
                                }
                            } catch {
                                print("Failed to save PDF: \(error)")
                            }
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.fill")
                            Text("Export PDF")
                        }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(.blue, lineWidth: 2)
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Family Sharing")
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
    
    private func getAvailableMonths() -> [Date] {
        let calendar = Calendar.current
        let now = Date()
        var months: [Date] = []
        
        // Get last 12 months
        for i in 0..<12 {
            if let month = calendar.date(byAdding: .month, value: -i, to: now) {
                months.append(month)
            }
        }
        
        return months
    }
}
