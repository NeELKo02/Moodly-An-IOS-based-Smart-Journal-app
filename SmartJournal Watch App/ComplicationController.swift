import ClockKit
import SwiftUI

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    // MARK: - Complication Configuration
    
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(identifier: "complication", displayName: "SmartJournal", supportedFamilies: CLKComplicationFamily.allCases)
        ]
        handler(descriptors)
    }
    
    func handleSharedComplicationDescriptors(_ complicationDescriptors: [CLKComplicationDescriptor]) {
        // Handle shared complication descriptors
    }
    
    // MARK: - Timeline Configuration
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(nil)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        // Get the last recorded mood from UserDefaults or HealthKit
        let lastMood = UserDefaults.standard.string(forKey: "lastMood") ?? "😐"
        let lastMoodTime = UserDefaults.standard.object(forKey: "lastMoodTime") as? Date ?? Date()
        
        let template = createTemplate(for: complication, mood: lastMood, time: lastMoodTime)
        let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
        handler(entry)
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        handler(nil)
    }
    
    // MARK: - Sample Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        let template = createTemplate(for: complication, mood: "😊", time: Date())
        handler(template)
    }
    
    // MARK: - Template Creation
    
    private func createTemplate(for complication: CLKComplication, mood: String, time: Date) -> CLKComplicationTemplate {
        switch complication.family {
        case .modularSmall:
            return createModularSmallTemplate(mood: mood)
        case .circularSmall:
            return createCircularSmallTemplate(mood: mood)
        case .utilitarianSmall:
            return createUtilitarianSmallTemplate(mood: mood)
        case .utilitarianLarge:
            return createUtilitarianLargeTemplate(mood: mood, time: time)
        case .graphicCircular:
            return createGraphicCircularTemplate(mood: mood)
        case .graphicRectangular:
            return createGraphicRectangularTemplate(mood: mood, time: time)
        case .graphicExtraLarge:
            return createGraphicExtraLargeTemplate(mood: mood)
        default:
            return createModularSmallTemplate(mood: mood)
        }
    }
    
    private func createModularSmallTemplate(mood: String) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateModularSmallSimpleText()
        template.textProvider = CLKSimpleTextProvider(text: mood)
        return template
    }
    
    private func createCircularSmallTemplate(mood: String) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateCircularSmallSimpleText()
        template.textProvider = CLKSimpleTextProvider(text: mood)
        return template
    }
    
    private func createUtilitarianSmallTemplate(mood: String) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateUtilitarianSmallFlat()
        template.textProvider = CLKSimpleTextProvider(text: mood)
        return template
    }
    
    private func createUtilitarianLargeTemplate(mood: String, time: Date) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateUtilitarianLargeFlat()
        let timeString = time.formatted(date: .omitted, time: .shortened)
        template.textProvider = CLKSimpleTextProvider(text: "\(mood) \(timeString)")
        return template
    }
    
    private func createGraphicCircularTemplate(mood: String) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateGraphicCircularView()
        template.content = AnyView(
            VStack {
                Text(mood)
                    .font(.title2)
                Text("Mood")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        )
        return template
    }
    
    private func createGraphicRectangularTemplate(mood: String, time: Date) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateGraphicRectangularLargeView()
        let timeString = time.formatted(date: .omitted, time: .shortened)
        template.content = AnyView(
            HStack {
                VStack(alignment: .leading) {
                    Text("SmartJournal")
                        .font(.headline)
                    Text("Last mood: \(mood)")
                        .font(.body)
                    Text(timeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(mood)
                    .font(.title)
            }
            .padding()
        )
        return template
    }
    
    private func createGraphicExtraLargeTemplate(mood: String) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateGraphicExtraLargeCircularView()
        template.content = AnyView(
            VStack {
                Text(mood)
                    .font(.system(size: 60))
                Text("Mood")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        )
        return template
    }
}

// MARK: - Complication Update Helper

extension ComplicationController {
    static func updateComplication(mood: String) {
        UserDefaults.standard.set(mood, forKey: "lastMood")
        UserDefaults.standard.set(Date(), forKey: "lastMoodTime")
        
        let server = CLKComplicationServer.sharedInstance()
        for complication in server.activeComplications ?? [] {
            server.reloadTimeline(for: complication)
        }
    }
}
