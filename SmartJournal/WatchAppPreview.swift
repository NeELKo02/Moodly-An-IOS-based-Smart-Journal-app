import SwiftUI

// MARK: - Watch App Preview

struct WatchAppPreview: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("SmartJournal Watch App")
                .font(.title2)
                .fontWeight(.bold)
            
            // Apple Watch Series 9 (45mm) Preview
            VStack(spacing: 16) {
                Text("Apple Watch Series 9 (45mm)")
                    .font(.headline)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black)
                        .frame(width: 180, height: 220)
                    
                    VStack(spacing: 12) {
                        // Header
                        VStack(spacing: 4) {
                            Text("SmartJournal")
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            
                            Text("How are you feeling?")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.gray)
                        }
                        
                        // Quick Mood Button
                        VStack(spacing: 6) {
                            Image(systemName: "face.smiling")
                                .font(.system(size: 24))
                                .foregroundStyle(.blue)
                            
                            Text("Log Mood")
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        // Today's Stats
                        HStack(spacing: 12) {
                            VStack(spacing: 2) {
                                Image(systemName: "book.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.blue)
                                Text("3")
                                    .font(.system(.caption, design: .rounded))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                Text("Entries")
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundStyle(.gray)
                            }
                            
                            VStack(spacing: 2) {
                                Image(systemName: "face.smiling")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.orange)
                                Text("😊")
                                    .font(.system(.caption, design: .rounded))
                                    .fontWeight(.semibold)
                                Text("Mood")
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundStyle(.gray)
                            }
                        }
                        .padding(8)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        // Connection Status
                        HStack {
                            Image(systemName: "iphone")
                                .font(.caption)
                                .foregroundStyle(.green)
                            Text("Connected")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(.gray)
                        }
                    }
                    .padding(12)
                }
            }
            
            // Apple Watch SE (40mm) Preview
            VStack(spacing: 16) {
                Text("Apple Watch SE (40mm)")
                    .font(.headline)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black)
                        .frame(width: 140, height: 180)
                    
                    VStack(spacing: 8) {
                        // Header
                        VStack(spacing: 2) {
                            Text("SmartJournal")
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            
                            Text("How are you feeling?")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(.gray)
                        }
                        
                        // Quick Mood Button
                        VStack(spacing: 4) {
                            Image(systemName: "face.smiling")
                                .font(.system(size: 20))
                                .foregroundStyle(.blue)
                            
                            Text("Log Mood")
                                .font(.system(.caption2, design: .rounded))
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        
                        // Today's Stats
                        HStack(spacing: 8) {
                            VStack(spacing: 1) {
                                Image(systemName: "book.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.blue)
                                Text("3")
                                    .font(.system(.caption2, design: .rounded))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                Text("Entries")
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundStyle(.gray)
                            }
                            
                            VStack(spacing: 1) {
                                Image(systemName: "face.smiling")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.orange)
                                Text("😊")
                                    .font(.system(.caption2, design: .rounded))
                                    .fontWeight(.semibold)
                                Text("Mood")
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundStyle(.gray)
                            }
                        }
                        .padding(6)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        
                        // Connection Status
                        HStack {
                            Image(systemName: "iphone")
                                .font(.caption2)
                                .foregroundStyle(.green)
                            Text("Connected")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(.gray)
                        }
                    }
                    .padding(8)
                }
            }
            
            // Features List
            VStack(alignment: .leading, spacing: 12) {
                Text("Watch App Features:")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    FeatureRow(icon: "face.smiling", title: "Quick Mood Logging", description: "Tap to log your mood on a 1-10 scale")
                    FeatureRow(icon: "book.fill", title: "Today's Stats", description: "See your entry count and average mood")
                    FeatureRow(icon: "clock", title: "Recent Entries", description: "View your latest journal entries")
                    FeatureRow(icon: "iphone", title: "iPhone Sync", description: "Seamlessly sync with your iPhone app")
                    FeatureRow(icon: "heart.fill", title: "Health Integration", description: "Mood data integrates with HealthKit")
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
    }
}

// MARK: - Feature Row Component

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    WatchAppPreview()
}

