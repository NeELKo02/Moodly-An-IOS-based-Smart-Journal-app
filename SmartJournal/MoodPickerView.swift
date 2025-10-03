import SwiftUI

struct MoodPickerView: View {
    @Binding var selectedMood: Int
    let onMoodSelected: (Int) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    private let moods = [
        (1, "😢", "Terrible"),
        (2, "😔", "Bad"),
        (3, "😕", "Poor"),
        (4, "😐", "Okay"),
        (5, "🙂", "Good"),
        (6, "😊", "Great"),
        (7, "😄", "Excellent"),
        (8, "🤩", "Amazing"),
        (9, "🥰", "Fantastic"),
        (10, "😍", "Perfect")
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 8) {
                        Text("How are you feeling?")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                        
                        Text("Tap to select your mood")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)
                    
                    // Mood Grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(moods, id: \.0) { mood in
                            MoodButton(
                                number: mood.0,
                                emoji: mood.1,
                                label: mood.2,
                                isSelected: selectedMood == mood.0
                            ) {
                                selectedMood = mood.0
                                // Haptic feedback for iOS
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }
                        }
                    }
                    
                    // Selected Mood Display
                    if selectedMood > 0 {
                        VStack(spacing: 8) {
                            Text("Selected: \(selectedMood)")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.secondary)
                            
                            Text(moods.first { $0.0 == selectedMood }?.1 ?? "😐")
                                .font(.system(size: 48))
                            
                            Text(moods.first { $0.0 == selectedMood }?.2 ?? "Neutral")
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.medium)
                        }
                        .padding(16)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Save") {
                            onMoodSelected(selectedMood)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedMood == 0)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Mood Button Component

struct MoodButton: View {
    let number: Int
    let emoji: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(emoji)
                    .font(.system(size: 24))
                
                Text("\(number)")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text(label)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.blue.opacity(0.2) : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

