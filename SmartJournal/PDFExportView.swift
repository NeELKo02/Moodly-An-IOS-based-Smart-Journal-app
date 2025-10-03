import SwiftUI

struct PDFExportView: View {
    @Environment(\.dismiss) private var dismiss
    let entries: [JournalEntry]
    
    @State private var selectedMonth: Date = Date()
    @State private var includeRawText: Bool = false
    @State private var isExporting: Bool = false
    @State private var showingShareSheet: Bool = false
    @State private var pdfData: Data?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)
                    
                    Text("Export Monthly Report")
                        .font(.title2.weight(.bold))
                    
                    Text("Generate a comprehensive PDF report of your wellness journey")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Month Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select Month")
                        .font(.headline)
                    
                    Picker("Month", selection: $selectedMonth) {
                        ForEach(getAvailableMonths(), id: \.self) { month in
                            Text(month.formatted(.dateTime.month(.wide).year()))
                                .tag(month)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                }
                .padding(.horizontal, 20)
                
                // Export Options
                VStack(alignment: .leading, spacing: 16) {
                    Text("Export Options")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        Toggle(isOn: $includeRawText) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Include Journal Text")
                                    .font(.body.weight(.medium))
                                Text("Add actual journal entries to the PDF (default: metrics only)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .tint(.orange)
                    }
                }
                .padding(.horizontal, 20)
                
                // Report Preview
                VStack(alignment: .leading, spacing: 12) {
                    Text("Report Contents")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ReportContentRow(icon: "doc.text", title: "Title Page", description: "Monthly overview with date range")
                        ReportContentRow(icon: "chart.bar", title: "Summary Statistics", description: "Total entries, average mood, top keywords")
                        ReportContentRow(icon: "tag", title: "Keyword Analysis", description: "Word cloud of most common topics")
                        ReportContentRow(icon: "chart.line.uptrend.xyaxis", title: "Mood Trends", description: "Visual chart of sentiment over time")
                        
                        if includeRawText {
                            ReportContentRow(icon: "text.quote", title: "Journal Entries", description: "Complete text of all entries")
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: generatePDF) {
                        HStack(spacing: 8) {
                            if isExporting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "doc.badge.plus")
                            }
                            Text(isExporting ? "Generating..." : "Generate PDF")
                        }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isExporting ? .gray : .orange)
                        )
                    }
                    .disabled(isExporting)
                    
                    if pdfData != nil {
                        Button(action: {
                            showingShareSheet = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share PDF")
                            }
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.orange)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(.orange, lineWidth: 2)
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("PDF Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let data = pdfData {
                    ShareSheet(items: [data])
                }
            }
        }
    }
    
    private func generatePDF() {
        isExporting = true
        
        // Filter entries for selected month
        let calendar = Calendar.current
        let monthStart = calendar.dateInterval(of: .month, for: selectedMonth)?.start ?? selectedMonth
        let monthEnd = calendar.dateInterval(of: .month, for: selectedMonth)?.end ?? selectedMonth
        
        let monthlyEntries = entries.filter { entry in
            entry.createdAt >= monthStart && entry.createdAt < monthEnd
        }
        
        // Generate PDF on background thread
        Task {
            let data = PDFExporter.shared.generateMonthlyReport(
                entries: monthlyEntries,
                month: selectedMonth,
                includeRawText: includeRawText
            )
            
            await MainActor.run {
                pdfData = data
                isExporting = false
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

struct ReportContentRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    PDFExportView(entries: [])
}

