//
//  SmartJournalTests.swift
//  SmartJournalTests
//
//  Created by user275890 on 8/23/25.
//

import Testing
import SwiftData
import Foundation
@testable import SmartJournal

struct SmartJournalTests {

    @Test func testJournalEntryCreation() async throws {
        let entry = JournalEntry(
            text: "Today was a great day!",
            sentiment: 0.8,
            keywords: ["great", "day"],
            summary: ["Positive day", "Good mood"]
        )
        
        #expect(entry.text == "Today was a great day!")
        #expect(entry.sentiment == 0.8)
        #expect(entry.keywords.count == 2)
        #expect(entry.summary.count == 2)
        #expect(entry.createdAt <= Date())
    }
    
    @Test func testJournalEntryDefaultValues() async throws {
        let entry = JournalEntry(
            text: "Test entry",
            sentiment: nil,
            keywords: [],
            summary: []
        )
        
        #expect(entry.text == "Test entry")
        #expect(entry.sentiment == nil)
        #expect(entry.keywords.isEmpty)
        #expect(entry.summary.isEmpty)
        #expect(entry.createdAt <= Date())
    }
    
    @Test func testJournalEntryProperties() async throws {
        let testDate = Date()
        let entry = JournalEntry(
            text: "Sample text",
            sentiment: -0.5,
            keywords: ["sample", "text"],
            summary: ["Sample summary"],
            createdAt: testDate
        )
        
        #expect(entry.text == "Sample text")
        #expect(entry.sentiment == -0.5)
        #expect(entry.keywords == ["sample", "text"])
        #expect(entry.summary == ["Sample summary"])
        #expect(entry.createdAt == testDate)
    }
}
