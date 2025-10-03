import SwiftUI
import WatchConnectivity

@main
struct SmartJournalWatchApp: App {
    @StateObject private var watchConnectivityManager = WatchConnectivityManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(watchConnectivityManager)
        }
    }
}

class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    @Published var lastMood: String = "😐"
    @Published var lastMoodTime: Date = Date()
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Handle activation completion
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let mood = message["mood"] as? String {
                self.lastMood = mood
                self.lastMoodTime = Date()
            }
        }
    }
    
    func sendMoodToiPhone(mood: String, value: Int) {
        let message: [String: Any] = [
            "mood": mood,
            "value": value,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("Failed to send mood to iPhone: \(error)")
            }
        }
    }
}
