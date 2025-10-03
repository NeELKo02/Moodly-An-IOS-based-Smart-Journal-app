import SwiftUI
import NaturalLanguage
import CoreData
import Charts
import CoreML
import Reductio
import UIKit
import HealthKit
import WatchConnectivity

@MainActor
struct ContentView: View {
    // CoreData
    @EnvironmentObject private var coreDataManager: CoreDataManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var entries: [JournalEntry] = []

    // UI state
    @State private var text: String = ""
    @State private var sentimentScore: Double? = nil
    @State private var sentimentEmoji: String = "😐"
    @State private var keywords: [String] = []
    @State private var summary: [String] = []
    @State private var triggers: [String] = []
    @State private var wellnessNudge: String? = nil

    // Share
    @State private var shareItem: ActivityItem? = nil

    // CoreML (loaded if present)
    @State private var coreMLClassifier: NLModel? = nil

    // Search + filter
    @State private var searchText: String = ""
    @State private var dateFilter: DateFilter = .all

    // UI animation
    @State private var moodScale: CGFloat = 1.0
    @State private var isAnalyzing: Bool = false
    
    // Managers
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var nlpAnalyzer = NLPAnalyzer()
    @StateObject private var privacyManager = PrivacyManager()
    @StateObject private var nudgeManager = NudgeManager()
    @StateObject private var voiceInputManager = VoiceInputManager()
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var watchConnectivityManager = WatchConnectivityManager()
    
    // Navigation
    @State private var showingWellnessInsights = false
    @State private var showingHealthCorrelations = false
    @State private var showingVoiceInput = false
    @State private var showingThemePicker = false
    @State private var showingFamilySharing = false
    @State private var showingPDFExport = false
    @State private var showingSideMenu = false
    @FocusState private var isTextEditorFocused: Bool
    @State private var selectedPromptIndex: Int? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Health App Style Header
                    headerSection
                    
                    // Journal Editor
                    journalEditorSection
                    
                    // Analysis Results
                    if sentimentScore != nil || !keywords.isEmpty || !summary.isEmpty || !triggers.isEmpty {
                        analysisResultsSection
                    }
                    
                    // Mood Trends Chart
                    if !entries.isEmpty {
                        moodTrendsSection
                    }
                    
                    // Recent Entries
                    recentEntriesSection
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search entries")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { showingSideMenu = true }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: clearEntry) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingWellnessInsights) {
                WellnessInsightsView()
            }
            .sheet(isPresented: $showingHealthCorrelations) {
                NavigationStack {
                    HealthCorrelationsView(
                        correlations: healthKitManager.calculateCorrelations(entries: entries),
                        insights: healthKitManager.generateHealthInsights(entries: entries)
                    )
                    .navigationTitle("Health Correlations")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") {
                                showingHealthCorrelations = false
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingThemePicker) {
                ThemePickerView()
            }
            .sheet(isPresented: $showingFamilySharing) {
                FamilySharingView()
            }
            .sheet(isPresented: $showingPDFExport) {
                PDFExportView(entries: entries)
            }
            
            // Side Menu
            .sheet(isPresented: $showingSideMenu) {
                SideMenuView(
                    showingWellnessInsights: $showingWellnessInsights,
                    showingHealthCorrelations: $showingHealthCorrelations,
                    showingThemePicker: $showingThemePicker,
                    showingFamilySharing: $showingFamilySharing,
                    showingPDFExport: $showingPDFExport,
                    showingSideMenu: $showingSideMenu
                )
            }
            
            // Bottom Navigation Bar
            .safeAreaInset(edge: .bottom) {
                bottomNavigationBar
                    .padding(.bottom, 0)
            }
        }
        .onAppear {
            loadCoreMLIfPresent()
            autoSaveTodayIfNeeded()
            setupWatchConnectivity()
            loadEntries()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { autoSaveTodayIfNeeded() }
        }
        .sheet(item: $shareItem) { item in
            ActivityView(text: item.text)
        }
    }
    
    // MARK: - Apple Health Style Header
    private var headerSection: some View {
        VStack(spacing: 0) {
            // Main header with gradient
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(.primary)
                        Text(Date().formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    
                    // Watch connection indicator
                    if watchConnectivityManager.isWatchConnected {
                        HStack(spacing: 4) {
                            Image(systemName: "applewatch")
                                .font(.caption)
                            Text("Connected")
                                .font(.caption2)
                        }
                        .foregroundStyle(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.green.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
                
                // Quick stats row
                HStack(spacing: 16) {
                    StatCard(
                        title: "Entries",
                        value: "\(entries.count)",
                        icon: "book.fill",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "Avg Mood",
                        value: averageMoodEmoji,
                        icon: "face.smiling",
                        color: .orange
                    )
                    
                    StatCard(
                        title: "Streak",
                        value: "\(currentStreak)",
                        icon: "flame.fill",
                        color: .red
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 24)
            .background(
                LinearGradient(
                    colors: [.blue.opacity(0.1), .purple.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }
    
    // MARK: - Today's Summary Section
    private var todaySummarySection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Today's Summary")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Today's entry status
                    SummaryCard(
                        title: "Journal Entry",
                        subtitle: text.isEmpty ? "No entry yet" : "\(text.count) characters",
                        icon: "square.and.pencil",
                        color: .blue,
                        action: { /* Focus on text editor */ }
                    )
                    
                    // Analysis status
                    SummaryCard(
                        title: "Analysis",
                        subtitle: sentimentScore != nil ? "Completed" : "Ready to analyze",
                        icon: "sparkles",
                        color: .purple,
                        action: { Task { await performFullAnalysis() } }
                    )
                    
                    // Wellness insights
                    SummaryCard(
                        title: "Wellness",
                        subtitle: wellnessNudge != nil ? "Insights available" : "Generate insights",
                        icon: "heart.fill",
                        color: .red,
                        action: { Task { await generateWellnessNudge() } }
                    )
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Journal Editor Section
    private var journalEditorSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Today's Entry")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                // Text Editor
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "square.and.pencil")
                            .font(.title3)
                            .foregroundStyle(.blue)
                        Text("Write your thoughts")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Spacer()
                        
                        // Voice input button
                        Button(action: {
                            if voiceInputManager.isRecording {
                                voiceInputManager.stopRecording()
                            } else {
                                voiceInputManager.startRecording()
                            }
                        }) {
                            Image(systemName: voiceInputManager.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.title2)
                                .foregroundStyle(voiceInputManager.isRecording ? .red : .blue)
                        }
                        .disabled(!voiceInputManager.isAuthorized)
                    }
                    
                                            TextEditor(text: $text)
                            .font(.body)
                            .frame(minHeight: 120)
                            .padding(16)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(isTextEditorFocused ? .blue : Color(.separator), lineWidth: isTextEditorFocused ? 2 : 0.5)
                            )
                            .focused($isTextEditorFocused)
                            .onChange(of: text) { _, newValue in
                                // Clear prompt highlight when user starts typing
                                if !newValue.isEmpty && selectedPromptIndex != nil {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedPromptIndex = nil
                                    }
                                }
                            }
                    
                    // Analyze button (only show when there's text but no analysis)
                    if !text.isEmpty && sentimentScore == nil {
                        Button(action: { Task { await performFullAnalysis() } }) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .font(.body)
                                Text("Analyze Entry")
                                    .font(.body.weight(.medium))
                            }
                            .foregroundStyle(.purple)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(.purple.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.purple.opacity(0.3), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Quick presets
                    if text.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Quick Start")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                            
                            VStack(spacing: 12) {
                                ForEach(Array([
                                    ("🤔 What's on your mind today?", "Reflect on your current thoughts and feelings"),
                                    ("😊 What made you smile today?", "Share a moment of joy or gratitude"),
                                    ("😰 What's challenging you right now?", "Explore what's causing stress or difficulty"),
                                    ("💪 What are you working towards?", "Think about your goals and aspirations"),
                                    ("🎯 What did you learn today?", "Share insights or new discoveries"),
                                    ("🌟 What are you grateful for?", "Express appreciation for the good in your life")
                                ].enumerated()), id: \.offset) { item in
                                    let index = item.offset
                                    let question = item.element.0
                                    let subtitle = item.element.1
                                    Button(action: { 
                                        // Highlight the selected prompt and focus text editor
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedPromptIndex = index
                                        }
                                        
                                        // Focus the text editor
                                        isTextEditorFocused = true
                                    }) {
                                        HStack(spacing: 12) {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(question)
                                                    .font(.body.weight(.medium))
                                                    .foregroundStyle(.primary)
                                                    .multilineTextAlignment(.leading)
                                                
                                                Text(subtitle)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                    .multilineTextAlignment(.leading)
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "arrow.right.circle.fill")
                                                .font(.title3)
                                                .foregroundStyle(.blue)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(selectedPromptIndex == index ? Color.blue.opacity(0.1) : Color(.systemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .strokeBorder(selectedPromptIndex == index ? .blue : Color(.separator), lineWidth: selectedPromptIndex == index ? 2 : 0.5)
                                        )
                                        .scaleEffect(selectedPromptIndex == index ? 1.02 : 1.0)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(20)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color(.separator), lineWidth: 0.5)
                )
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Analysis Results Section
    private var analysisResultsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Analysis Results")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                // Sentiment Analysis
                if let sentiment = sentimentScore {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "face.smiling")
                                .font(.title3)
                                .foregroundStyle(.orange)
                            Text("Mood Analysis")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                        
                        HStack(spacing: 16) {
                            Text(sentimentEmoji)
                                .font(.system(size: 48))
                                .scaleEffect(moodScale)
                                .animation(.spring(response: 0.35, dampingFraction: 0.6), value: moodScale)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Sentiment Score")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(String(format: "%.1f", sentiment))
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(.primary)
                                Text(sentimentDescription(for: sentiment))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .padding(16)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color(.separator), lineWidth: 0.5)
                    )
                }
                
                // Keywords
                if !keywords.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "tag.fill")
                                .font(.title3)
                                .foregroundStyle(.blue)
                            Text("Key Topics")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                            ForEach(keywords, id: \.self) { keyword in
                                Text(keyword)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.blue.opacity(0.1))
                                    .foregroundStyle(.blue)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color(.separator), lineWidth: 0.5)
                    )
                }
                
                // Share Button (Optional)
                if !text.isEmpty {
                    Button(action: { shareItem = ActivityItem(text: exportString()) }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .font(.body)
                            Text("Share Entry")
                                .font(.body.weight(.medium))
                        }
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.blue.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Helper Functions
    private func sentimentDescription(for score: Double) -> String {
        switch score {
        case -1.0..<(-0.5): return "Very Negative"
        case -0.5..<0: return "Negative"
        case 0..<0.5: return "Neutral"
        case 0.5..<1.0: return "Positive"
        default: return "Very Positive"
        }
    }
    
    // MARK: - Action Button Component
    struct ActionButton: View {
        let title: String
        let icon: String
        let color: Color
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.title3)
                    Text(title)
                        .font(.caption2.weight(.semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(color.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Mood Trends Section
    private var moodTrendsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Mood Trends")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                // Simple mood chart
                HStack(spacing: 8) {
                    ForEach(entries.prefix(7).reversed(), id: \.id) { entry in
                        VStack(spacing: 4) {
                            Text(moodEmoji(for: entry.sentiment ?? 0.0))
                                .font(.title3)
                            Text(entry.createdAt.formatted(.dateTime.day().month(.abbreviated)))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(16)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color(.separator), lineWidth: 0.5)
                )
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Recent Entries Section
    private var recentEntriesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Recent Entries")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(.horizontal, 20)
            
            LazyVStack(spacing: 8) {
                ForEach(entries.prefix(5), id: \.id) { entry in
                    EntryRowView(entry: entry) {
                        // Edit entry
                    } onDelete: {
                        // Delete entry using CoreData
                        if let coreDataEntry = coreDataManager.fetchEntries().first(where: { $0.id == entry.id }) {
                            coreDataManager.deleteEntry(coreDataEntry)
                            loadEntries()
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 100)
    }
    
    // MARK: - Entry Row View
    struct EntryRowView: View {
        let entry: JournalEntry
        let onTap: () -> Void
        let onDelete: () -> Void
        
        var body: some View {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    Text(moodEmoji(for: entry.sentiment ?? 0.0))
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.text.split(separator: "\n").first.map(String.init) ?? "(No text)")
                            .font(.body)
                            .lineLimit(2)
                            .foregroundStyle(.primary)
                        
                        Text(entry.createdAt.formatted(.dateTime.day().month().hour().minute()))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color(.separator), lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)
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
    
    // MARK: - Side Menu View
    struct SideMenuView: View {
        @Binding var showingWellnessInsights: Bool
        @Binding var showingHealthCorrelations: Bool
        @Binding var showingThemePicker: Bool
        @Binding var showingFamilySharing: Bool
        @Binding var showingPDFExport: Bool
        @Binding var showingSideMenu: Bool
        
        var body: some View {
            NavigationView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("SmartJournal")
                                    .font(.largeTitle.weight(.bold))
                                    .foregroundStyle(.primary)
                                Text("Your wellness companion")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            
                            Button(action: { showingSideMenu = false }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Divider()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Menu Items
                    ScrollView {
                        VStack(spacing: 0) {
                            MenuSection(title: "Wellness & Health") {
                                MenuItem(
                                    icon: "heart.fill",
                                    title: "Wellness Insights",
                                    subtitle: "AI-powered wellness recommendations",
                                    color: .red
                                ) {
                                    showingWellnessInsights = true
                                    showingSideMenu = false
                                }
                                
                                MenuItem(
                                    icon: "chart.line.uptrend.xyaxis",
                                    title: "Health Correlations",
                                    subtitle: "Connect journal with health data",
                                    color: .blue
                                ) {
                                    showingHealthCorrelations = true
                                    showingSideMenu = false
                                }
                            }
                            
                            MenuSection(title: "Customization") {
                                MenuItem(
                                    icon: "paintbrush.fill",
                                    title: "Change Theme",
                                    subtitle: "Personalize your journal appearance",
                                    color: .purple
                                ) {
                                    showingThemePicker = true
                                    showingSideMenu = false
                                }
                            }
                            
                            MenuSection(title: "Sharing & Export") {
                                MenuItem(
                                    icon: "person.3.fill",
                                    title: "Family Sharing",
                                    subtitle: "Share wellness summaries with family",
                                    color: .green
                                ) {
                                    showingFamilySharing = true
                                    showingSideMenu = false
                                }
                                
                                MenuItem(
                                    icon: "doc.fill",
                                    title: "Export PDF",
                                    subtitle: "Generate monthly wellness reports",
                                    color: .orange
                                ) {
                                    showingPDFExport = true
                                    showingSideMenu = false
                                }
                            }
                            
                            MenuSection(title: "About") {
                                MenuItem(
                                    icon: "info.circle.fill",
                                    title: "About SmartJournal",
                                    subtitle: "Version 1.0 • Privacy-focused journaling",
                                    color: .gray
                                ) {
                                    // About action
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    
                    Spacer()
                }
                .background(Color(.systemGroupedBackground))
                .navigationBarHidden(true)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Menu Section Component
    struct MenuSection<Content: View>: View {
        let title: String
        let content: Content
        
        init(title: String, @ViewBuilder content: () -> Content) {
            self.title = title
            self.content = content()
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                
                VStack(spacing: 8) {
                    content
                }
                .padding(.bottom, 20)
            }
        }
    }
    
    // MARK: - Menu Item Component
    struct MenuItem: View {
        let icon: String
        let title: String
        let subtitle: String
        let color: Color
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                HStack(spacing: 16) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                        .frame(width: 32, height: 32)
                        .background(color.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color(.separator), lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Bottom Navigation Bar (Clean & Simple)
    private var bottomNavigationBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(.quaternary)
            
            HStack(spacing: 0) {
                // Menu
                Button(action: { showingSideMenu = true }) {
                    VStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title3)
                        Text("Menu")
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .buttonStyle(HoverButtonStyle())
                .help("Open Menu")
                
                // Quick Save
                Button(action: saveEntry) {
                    VStack(spacing: 4) {
                        Image(systemName: "tray.and.arrow.down.fill")
                            .font(.title3)
                        Text("Save")
                        .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(.green)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .buttonStyle(HoverButtonStyle())
                .help("Save Entry")
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(
            .regularMaterial,
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.quaternary, lineWidth: 0.5)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 0)
    }
    
    // MARK: - Helper Components
    private var averageMoodEmoji: String {
        let recentEntries = entries.prefix(7) // Last 7 entries
        let averageSentiment = recentEntries.map { $0.sentiment ?? 0.0 }.reduce(0, +) / Double(max(recentEntries.count, 1))
        return moodEmoji(for: averageSentiment)
    }
    
    private var currentStreak: Int {
        var streak = 0
        let calendar = Calendar.current
        var currentDate = Date()
        
        for entry in entries.sorted(by: { $0.createdAt > $1.createdAt }) {
            if calendar.isDate(entry.createdAt, inSameDayAs: currentDate) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        return streak
    }
    
    // MARK: - Stat Card Component
    struct StatCard: View {
        let title: String
        let value: String
        let icon: String
        let color: Color
        
        var body: some View {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                Text(value)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color(.separator), lineWidth: 0.5)
            )
        }
    }
    
    // MARK: - Summary Card Component
    struct SummaryCard: View {
        let title: String
        let subtitle: String
        let icon: String
        let color: Color
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundStyle(color)
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 160, height: 100)
                .padding(16)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color(.separator), lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Hover Button Style
    struct HoverButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
        }
    }
    
    // MARK: - Activity Item
    struct ActivityItem: Identifiable {
        let id = UUID()
        let text: String
    }
    
    // MARK: - Activity View
    struct ActivityView: UIViewControllerRepresentable {
        let text: String
        
        func makeUIViewController(context: Context) -> UIActivityViewController {
            let activityViewController = UIActivityViewController(activityItems: [text], applicationActivities: nil)
            return activityViewController
        }
        
        func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
    }
    
    // MARK: - Date Filter
    enum DateFilter: String, CaseIterable {
        case all = "All"
        case today = "Today"
        case week = "Week"
        case month = "Month"
        
        var title: String { rawValue }
    }
    
    // MARK: - Core Methods
    private func clearEntry() {
        text = ""
        sentimentScore = nil
        sentimentEmoji = "😐"
        keywords = []
        summary = []
        triggers = []
        wellnessNudge = nil
    }
    
    private func saveEntry() {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        coreDataManager.createJournalEntry(
            text: text,
            sentiment: sentimentScore ?? 0.0,
            keywords: keywords,
            summary: summary,
            wellnessNudge: wellnessNudge,
            triggers: triggers,
            healthKitMoodValue: 0,
            healthKitMoodCategory: nil,
            healthKitUUID: nil,
            detectedLanguage: nlpAnalyzer.detectLanguage(text) ?? "en",
            sleepDuration: nil,
            stepCount: nil,
            workoutMinutes: nil,
            voiceTranscribed: false
        )
        
        // Refresh entries
        loadEntries()
        
        // Clear the form
        clearEntry()
        
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    private func loadEntries() {
        entries = coreDataManager.fetchEntries()
    }
    
    private func loadEntry(_ entry: JournalEntry) {
        text = entry.text
        sentimentScore = entry.sentiment
        sentimentEmoji = moodEmoji(for: entry.sentiment ?? 0.0)
        keywords = entry.keywords
        summary = entry.summary
        triggers = entry.triggers
        wellnessNudge = entry.wellnessNudge
    }
    
    private func exportString() -> String {
        var export = "SmartJournal Entry\n\n"
        export += "Date: \(Date().formatted())\n"
        export += "Text: \(text)\n"
        
        if let sentiment = sentimentScore {
            export += "Sentiment: \(String(format: "%.2f", sentiment))\n"
        }
        
        if !keywords.isEmpty {
            export += "Keywords: \(keywords.joined(separator: ", "))\n"
        }
        
        if !summary.isEmpty {
            export += "Summary: \(summary.joined(separator: " "))\n"
        }
        
        return export
    }
    
    private func filteredEntries() -> [JournalEntry] {
        let calendar = Calendar.current
        let now = Date()
        
        return entries.filter { entry in
            switch dateFilter {
            case .all:
                return true
            case .today:
                return calendar.isDate(entry.createdAt, inSameDayAs: now)
            case .week:
                let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
                return entry.createdAt >= weekAgo
            case .month:
                let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
                return entry.createdAt >= monthAgo
            }
        }
    }
    
    private func loadCoreMLIfPresent() {
        // Load CoreML model if available
        if let modelURL = Bundle.main.url(forResource: "SentimentClassifier", withExtension: "mlmodelc") {
            do {
                coreMLClassifier = try NLModel(contentsOf: modelURL)
            } catch {
                print("Failed to load CoreML model: \(error)")
            }
        }
    }
    
    private func autoSaveTodayIfNeeded() {
        // Auto-save logic for today's entry
        let today = Calendar.current.startOfDay(for: Date())
        let hasTodayEntry = entries.contains { entry in
            Calendar.current.isDate(entry.createdAt, inSameDayAs: today)
        }
        
        if !hasTodayEntry && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Auto-save after 5 minutes of inactivity
            DispatchQueue.main.asyncAfter(deadline: .now() + 300) {
                if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    saveEntry()
                }
            }
        }
    }
    
    private func setupWatchConnectivity() {
        // Setup WatchConnectivity
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = watchConnectivityManager
            session.activate()
        }
    }
    
    // MARK: - Analysis Methods
    private func performFullAnalysis() async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isAnalyzing = true
        
        // Detect language
        _ = nlpAnalyzer.detectLanguage(text)
        
        // Perform comprehensive analysis
        let analysis = await nlpAnalyzer.analyzeText(text)
        
        // Fetch health data for today
        _ = await healthKitManager.fetchHealthDataForDate(Date())
        
        // Update UI on main thread
        await MainActor.run {
            sentimentScore = analysis.sentiment
            keywords = analysis.keywords
            summary = analysis.summary
            triggers = analysis.triggers
            sentimentEmoji = moodEmoji(for: sentimentScore ?? 0.0)
            
            // Generate wellness nudge
            wellnessNudge = healthKitManager.generateWellnessNudge(
                sentiment: sentimentScore ?? 0.0,
                keywords: keywords,
                triggers: triggers
            )
            
            isAnalyzing = false
            
            // Animate mood emoji
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                moodScale = 1.2
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                    moodScale = 1.0
                }
            }
        }
    }
    
    private func detectTriggers() async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let detectedTriggers = await nlpAnalyzer.analyzeText(text).triggers
        
        await MainActor.run {
            triggers = detectedTriggers
        }
    }
    
    private func generateWellnessNudge() async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        _ = await healthKitManager.fetchHealthDataForDate(Date())
        let nudge = healthKitManager.generateWellnessNudge(
            sentiment: sentimentScore ?? 0.0,
            keywords: keywords,
            triggers: triggers
        )
        
        await MainActor.run {
            wellnessNudge = nudge
        }
    }
    
    // MARK: - Conversion Helper (No longer needed since we use JournalEntry directly)
    
    // MARK: - Mood Emoji Helper
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

