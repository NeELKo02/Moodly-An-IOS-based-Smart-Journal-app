//
//  SmartJournalApp.swift
//  SmartJournal
//
//  Created by user275890 on 8/23/25.
//

import SwiftUI
import CoreData
import UserNotifications

@main
struct SmartJournalApp: App {
    @StateObject private var coreDataManager = CoreDataManager.shared
    
    init() {
        // Setup notification categories
        let nudgeManager = NudgeManager()
        nudgeManager.setupNotificationCategories()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(coreDataManager)
                .onAppear {
                    // Ensure CoreData is properly initialized
                    _ = coreDataManager.context
                }
        }
    }
}
