import Foundation
import NaturalLanguage
import CoreML

@MainActor
class NLPAnalyzer: ObservableObject {
    private let tagger = NLTagger(tagSchemes: [.lexicalClass, .nameType, .tokenType])
    private let sentimentTagger = NLTagger(tagSchemes: [.sentimentScore])
    private let languageRecognizer = NLLanguageRecognizer()
    
    // Emotional trigger keywords
    private let emotionalTriggers: [String: [String]] = [
        "stress": ["deadline", "pressure", "overwhelm", "anxiety", "worry", "stress", "busy", "rush"],
        "work": ["meeting", "boss", "colleague", "project", "deadline", "work", "office", "job"],
        "relationships": ["friend", "family", "partner", "relationship", "argument", "fight", "love", "care"],
        "health": ["sick", "pain", "tired", "exhausted", "sleep", "exercise", "diet", "health"],
        "financial": ["money", "bill", "expense", "budget", "financial", "cost", "expensive", "cheap"],
        "social": ["party", "social", "alone", "lonely", "crowd", "people", "conversation"],
        "personal": ["goal", "achievement", "failure", "success", "dream", "aspiration", "self"]
    ]
    
    // Positive trigger keywords
    private let positiveTriggers: [String: [String]] = [
        "achievement": ["accomplished", "completed", "finished", "success", "achievement", "goal", "milestone"],
        "connection": ["friend", "family", "love", "hug", "conversation", "support", "care"],
        "nature": ["outdoor", "nature", "walk", "park", "sunshine", "fresh air", "exercise"],
        "creativity": ["art", "music", "writing", "creative", "inspiration", "project", "hobby"],
        "gratitude": ["thankful", "grateful", "blessed", "appreciate", "good", "wonderful", "amazing"]
    ]
    
    func analyzeText(_ text: String) async -> NLPAnalysis {
        // Detect language
        let detectedLanguage = detectLanguage(text)
        
        // Sentiment analysis
        let sentiment = await analyzeSentiment(text, language: detectedLanguage)
        
        // Keyword extraction
        let keywords = await extractKeywords(text)
        
        // Trigger detection
        let triggers = await detectTriggers(text)
        
        // Summary generation
        let summary = await generateSummary(text, sentiment: sentiment, triggers: triggers)
        
        return NLPAnalysis(
            sentiment: sentiment,
            keywords: keywords,
            summary: summary,
            triggers: triggers,
            detectedLanguage: detectedLanguage
        )
    }
    
    private func analyzeSentiment(_ text: String) async -> Double {
        sentimentTagger.string = text
        
        var totalSentiment: Double = 0
        var count = 0
        
        sentimentTagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .sentence, scheme: .sentimentScore) { tag, tokenRange in
            if let sentiment = tag?.rawValue, let score = Double(sentiment) {
                totalSentiment += score
                count += 1
            }
            return true
        }
        
        return count > 0 ? totalSentiment / Double(count) : 0.0
    }
    
    private func extractKeywords(_ text: String) async -> [String] {
        tagger.string = text
        
        var keywords: [String] = []
        var keywordScores: [String: Int] = [:]
        
        // Extract nouns, verbs, and adjectives
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass) { tag, tokenRange in
            let word = String(text[tokenRange]).lowercased()
            
            // Filter out common words and short words
            if word.count > 3 && !isCommonWord(word) {
                if let lexicalClass = tag {
                    switch lexicalClass {
                    case .noun, .verb, .adjective:
                        keywordScores[word, default: 0] += 1
                    default:
                        break
                    }
                }
            }
            return true
        }
        
        // Sort by frequency and take top keywords
        keywords = keywordScores.sorted { $0.value > $1.value }
            .prefix(8)
            .map { $0.key }
            .filter { !$0.isEmpty }
        
        return Array(keywords)
    }
    
    private func detectTriggers(_ text: String) async -> [String] {
        let lowercasedText = text.lowercased()
        var detectedTriggers: Set<String> = []
        
        // Check for emotional triggers
        for (category, triggers) in emotionalTriggers {
            for trigger in triggers {
                if lowercasedText.contains(trigger) {
                    detectedTriggers.insert(category)
                    break
                }
            }
        }
        
        // Check for positive triggers
        for (category, triggers) in positiveTriggers {
            for trigger in triggers {
                if lowercasedText.contains(trigger) {
                    detectedTriggers.insert(category)
                    break
                }
            }
        }
        
        // Additional context-based trigger detection
        if lowercasedText.contains("i feel") || lowercasedText.contains("i am") || lowercasedText.contains("i'm") {
            detectedTriggers.insert("emotional_state")
        }
        
        if lowercasedText.contains("because") || lowercasedText.contains("since") || lowercasedText.contains("due to") {
            detectedTriggers.insert("causal_thinking")
        }
        
        return Array(detectedTriggers)
    }
    
    private func generateSummary(_ text: String, sentiment: Double, triggers: [String]) async -> [String] {
        var summary: [String] = []
        
        // Sentiment-based summary
        if sentiment > 0.3 {
            summary.append("You're experiencing positive emotions")
        } else if sentiment < -0.3 {
            summary.append("You're feeling some negative emotions")
        } else {
            summary.append("Your mood appears neutral")
        }
        
        // Trigger-based insights
        if triggers.contains("stress") {
            summary.append("Stress-related factors are present")
        }
        
        if triggers.contains("work") {
            summary.append("Work-related thoughts are on your mind")
        }
        
        if triggers.contains("relationships") {
            summary.append("Relationship dynamics are affecting you")
        }
        
        if triggers.contains("achievement") {
            summary.append("You're focused on accomplishments")
        }
        
        if triggers.contains("gratitude") {
            summary.append("You're expressing gratitude")
        }
        
        // Length-based insights
        let wordCount = text.split(separator: " ").count
        if wordCount > 50 {
            summary.append("You had a lot to share today")
        } else if wordCount < 10 {
            summary.append("You kept it brief today")
        }
        
        return summary
    }
    
    private func isCommonWord(_ word: String) -> Bool {
        let commonWords: Set<String> = [
            "the", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by",
            "is", "are", "was", "were", "be", "been", "being", "have", "has", "had",
            "do", "does", "did", "will", "would", "could", "should", "may", "might",
            "this", "that", "these", "those", "i", "you", "he", "she", "it", "we", "they",
            "me", "him", "her", "us", "them", "my", "your", "his", "her", "its", "our", "their"
        ]
        return commonWords.contains(word)
    }
    
    // MARK: - Multi-language Support
    
    func detectLanguage(_ text: String) -> String? {
        languageRecognizer.processString(text)
        return languageRecognizer.dominantLanguage?.rawValue
    }
    
    func analyzeSentiment(_ text: String, language: String?) async -> Double {
        // Use language-specific sentiment analysis if available
        if let language = language {
            let _ = Locale(identifier: language)
            let languageTagger = NLTagger(tagSchemes: [.sentimentScore])
            
            languageTagger.string = text
            
            var totalSentiment: Double = 0
            var count = 0
            
            languageTagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .sentence, scheme: .sentimentScore) { tag, tokenRange in
                if let sentiment = tag?.rawValue, let score = Double(sentiment) {
                    totalSentiment += score
                    count += 1
                }
                return true
            }
            
            return count > 0 ? totalSentiment / Double(count) : 0.0
        }
        
        // Fall back to default sentiment analysis
        return await analyzeSentiment(text)
    }
    
    func isLanguageSupported(_ language: String) -> Bool {
        // Check if the language is supported for sentiment analysis
        let supportedLanguages = ["en", "es", "fr", "de", "it", "pt", "ja", "ko", "zh"]
        return supportedLanguages.contains(language.lowercased())
    }
    
    func getLanguageDisplayName(_ languageCode: String) -> String {
        let locale = Locale(identifier: languageCode)
        return locale.localizedString(forLanguageCode: languageCode) ?? languageCode
    }
}

// MARK: - NLP Analysis Data Structure
struct NLPAnalysis {
    let sentiment: Double
    let keywords: [String]
    let summary: [String]
    let triggers: [String]
    let detectedLanguage: String?
}
