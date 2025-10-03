import SwiftUI

struct RecentEntriesView: View {
    let entries: [JournalEntry]
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Recent Entries")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.semibold)
                        
                        Text("\(entries.count) total entries")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)
                    
                    // Entries List
                    if entries.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "book.closed")
                                .font(.system(size: 32))
                                .foregroundStyle(.secondary)
                            
                            Text("No entries yet")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.secondary)
                            
                            Text("Start journaling to see your entries here")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 32)
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(entries.prefix(10), id: \.id) { entry in
                                EntryRowView(entry: entry)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
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

// MARK: - Entry Row View

struct EntryRowView: View {
    let entry: JournalEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with mood and date
            HStack {
                Text(moodEmoji(for: entry.sentiment ?? 0.0))
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.createdAt.formatted(.dateTime.day().month(.abbreviated)))
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Text(entry.createdAt.formatted(.dateTime.hour().minute()))
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Quick stats
                if let sentiment = entry.sentiment {
                    Text(String(format: "%.1f", sentiment))
                        .font(.system(.caption2, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundStyle(sentimentColor(for: sentiment))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(sentimentColor(for: sentiment).opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            
            // Entry text
            Text(entry.text)
                .font(.system(.caption, design: .rounded))
                .lineLimit(3)
                .foregroundStyle(.primary)
            
            // Keywords if available
            if !entry.keywords.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(entry.keywords.prefix(3), id: \.self) { keyword in
                            Text(keyword)
                                .font(.system(.caption2, design: .rounded))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Helper Methods
    
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
    
    private func sentimentColor(for sentiment: Double) -> Color {
        switch sentiment {
        case -1.0..<(-0.2): return .red
        case -0.2..<0.2: return .orange
        case 0.2..<1.0: return .green
        default: return .gray
        }
    }
}

