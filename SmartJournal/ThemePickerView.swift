import SwiftUI

struct ThemePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedTheme: JournalTheme
    
    init() {
        _selectedTheme = State(initialValue: ThemeManager.shared.selectedTheme)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "paintbrush.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(selectedTheme.accentColor)
                    
                    Text("Choose Your Theme")
                        .font(.title2.weight(.bold))
                    
                    Text("Customize your journaling experience")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Theme Options
                VStack(spacing: 16) {
                    ForEach(JournalTheme.allCases, id: \.self) { theme in
                        ThemeOptionCard(
                            theme: theme,
                            isSelected: selectedTheme == theme
                        ) {
                            selectedTheme = theme
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Preview Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Preview")
                        .font(.headline)
                        .padding(.horizontal, 20)
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            // Preview Card
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "square.and.pencil")
                                        .font(.title3)
                                        .foregroundStyle(.white)
                                        .frame(width: 32, height: 32)
                                        .background(
                                            LinearGradient(
                                                colors: [selectedTheme.accentColor, selectedTheme.secondaryAccentColor],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .clipShape(Circle())
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Sample Entry")
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Text("This is how your journal will look")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                                
                                Text("This is a sample journal entry to show how the theme will look in your actual journal. The colors, gradients, and styling will be applied throughout the app.")
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedTheme.cardBackground)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(
                                                selectedTheme.cardBorderGradient,
                                                lineWidth: 1
                                            )
                                    )
                                
                                // Sample Keywords
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                    ForEach(["Sample", "Keywords"], id: \.self) { keyword in
                                        Text(keyword)
                                            .font(.caption.weight(.medium))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .frame(maxWidth: .infinity)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(selectedTheme.cardFillGradient)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .strokeBorder(
                                                        selectedTheme.cardBorderGradient,
                                                        lineWidth: 1
                                                    )
                                            )
                                            .foregroundStyle(.primary)
                                    }
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(selectedTheme.cardBackground)
                                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                    .frame(maxHeight: 300)
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        themeManager.setTheme(selectedTheme)
                        dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Apply Theme")
                        }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedTheme.accentColor)
                        )
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(.secondary, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(selectedTheme.backgroundGradient)
            .navigationTitle("Theme Picker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        themeManager.setTheme(selectedTheme)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ThemeOptionCard: View {
    let theme: JournalTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Theme Icon
                Image(systemName: theme.icon)
                    .font(.title2)
                    .foregroundStyle(theme.accentColor)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(theme.cardFillGradient)
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(
                                isSelected ? theme.accentColor : Color.clear,
                                lineWidth: 2
                            )
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(themeDescription(for: theme))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(theme.accentColor)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isSelected ? theme.accentColor : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private func themeDescription(for theme: JournalTheme) -> String {
        switch theme {
        case .calm:
            return "Peaceful greens and blues for a serene journaling experience"
        case .focus:
            return "Energetic oranges and yellows to boost concentration"
        case .midnight:
            return "Deep purples and indigos for evening reflection"
        }
    }
}

#Preview {
    ThemePickerView()
}
