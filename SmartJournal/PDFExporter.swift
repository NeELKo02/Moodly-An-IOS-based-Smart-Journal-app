import SwiftUI
import PDFKit
import Charts

class PDFExporter: ObservableObject {
    static let shared = PDFExporter()
    
    private init() {}
    
    func generateMonthlyReport(entries: [JournalEntry], month: Date, includeRawText: Bool = false) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "SmartJournal",
            kCGPDFContextAuthor: "SmartJournal User",
            kCGPDFContextTitle: "Monthly Wellness Report"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            // Title Page
            context.beginPage()
            drawTitlePage(context: context, month: month, pageRect: pageRect)
            
            // Summary Stats Page
            context.beginPage()
            drawSummaryPage(context: context, entries: entries, pageRect: pageRect)
            
            // Keywords/Word Cloud Page
            context.beginPage()
            drawKeywordsPage(context: context, entries: entries, pageRect: pageRect)
            
            // Charts Page
            context.beginPage()
            drawChartsPage(context: context, entries: entries, pageRect: pageRect)
            
            // Optional: Raw Text Page (only if user opts in)
            if includeRawText {
                context.beginPage()
                drawRawTextPage(context: context, entries: entries, pageRect: pageRect)
            }
        }
        
        return data
    }
    
    private func drawTitlePage(context: UIGraphicsPDFRendererContext, month: Date, pageRect: CGRect) {
        let titleFont = UIFont.boldSystemFont(ofSize: 32)
        let subtitleFont = UIFont.systemFont(ofSize: 18)
        let dateFont = UIFont.systemFont(ofSize: 16)
        
        let title = "Monthly Wellness Report"
        let subtitle = "Your mental health journey"
        let dateString = month.formatted(.dateTime.month(.wide).year())
        
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.systemBlue
        ]
        
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: subtitleFont,
            .foregroundColor: UIColor.secondaryLabel
        ]
        
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: dateFont,
            .foregroundColor: UIColor.secondaryLabel
        ]
        
        let titleSize = title.size(withAttributes: titleAttributes)
        let subtitleSize = subtitle.size(withAttributes: subtitleAttributes)
        let dateSize = dateString.size(withAttributes: dateAttributes)
        
        let titleRect = CGRect(
            x: (pageRect.width - titleSize.width) / 2,
            y: pageRect.height * 0.3,
            width: titleSize.width,
            height: titleSize.height
        )
        
        let subtitleRect = CGRect(
            x: (pageRect.width - subtitleSize.width) / 2,
            y: titleRect.maxY + 20,
            width: subtitleSize.width,
            height: subtitleSize.height
        )
        
        let dateRect = CGRect(
            x: (pageRect.width - dateSize.width) / 2,
            y: subtitleRect.maxY + 10,
            width: dateSize.width,
            height: dateSize.height
        )
        
        title.draw(in: titleRect, withAttributes: titleAttributes)
        subtitle.draw(in: subtitleRect, withAttributes: subtitleAttributes)
        dateString.draw(in: dateRect, withAttributes: dateAttributes)
        
        // Draw decorative elements
        let iconSize: CGFloat = 60
        let iconRect = CGRect(
            x: (pageRect.width - iconSize) / 2,
            y: pageRect.height * 0.6,
            width: iconSize,
            height: iconSize
        )
        
        if let heartImage = UIImage(systemName: "heart.fill") {
            heartImage.withTintColor(.systemRed, renderingMode: .alwaysOriginal)
                .draw(in: iconRect)
        }
    }
    
    private func drawSummaryPage(context: UIGraphicsPDFRendererContext, entries: [JournalEntry], pageRect: CGRect) {
        let titleFont = UIFont.boldSystemFont(ofSize: 24)
        let headerFont = UIFont.boldSystemFont(ofSize: 16)
        let bodyFont = UIFont.systemFont(ofSize: 14)
        
        let title = "Summary Statistics"
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.label
        ]
        
        title.draw(at: CGPoint(x: 40, y: 40), withAttributes: titleAttributes)
        
        var yPosition: CGFloat = 100
        
        // Total entries
        let totalEntries = entries.count
        drawStatRow(
            context: context,
            title: "Total Entries",
            value: "\(totalEntries)",
            yPosition: yPosition,
            headerFont: headerFont,
            bodyFont: bodyFont
        )
        yPosition += 40
        
        // Average sentiment
        let avgSentiment = entries.compactMap { $0.sentiment }.reduce(0, +) / Double(max(entries.count, 1))
        drawStatRow(
            context: context,
            title: "Average Sentiment",
            value: String(format: "%.2f", avgSentiment),
            yPosition: yPosition,
            headerFont: headerFont,
            bodyFont: bodyFont
        )
        yPosition += 40
        
        // Most common keywords
        let allKeywords = entries.flatMap { $0.keywords }
        let keywordCounts = Dictionary(grouping: allKeywords, by: { $0 })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .prefix(5)
        
        drawStatRow(
            context: context,
            title: "Top Keywords",
            value: keywordCounts.map { "\($0.key) (\($0.value))" }.joined(separator: ", "),
            yPosition: yPosition,
            headerFont: headerFont,
            bodyFont: bodyFont
        )
        yPosition += 40
        
        // Voice entries
        let voiceEntries = entries.filter { $0.voiceTranscribed }.count
        drawStatRow(
            context: context,
            title: "Voice Entries",
            value: "\(voiceEntries) of \(totalEntries)",
            yPosition: yPosition,
            headerFont: headerFont,
            bodyFont: bodyFont
        )
    }
    
    private func drawStatRow(context: UIGraphicsPDFRendererContext, title: String, value: String, yPosition: CGFloat, headerFont: UIFont, bodyFont: UIFont) {
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.label
        ]
        
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: UIColor.secondaryLabel
        ]
        
        title.draw(at: CGPoint(x: 40, y: yPosition), withAttributes: titleAttributes)
        value.draw(at: CGPoint(x: 200, y: yPosition), withAttributes: valueAttributes)
    }
    
    private func drawKeywordsPage(context: UIGraphicsPDFRendererContext, entries: [JournalEntry], pageRect: CGRect) {
        let titleFont = UIFont.boldSystemFont(ofSize: 24)
        let _ = UIFont.systemFont(ofSize: 14)
        
        let title = "Keyword Analysis"
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.label
        ]
        
        title.draw(at: CGPoint(x: 40, y: 40), withAttributes: titleAttributes)
        
        let allKeywords = entries.flatMap { $0.keywords }
        let keywordCounts = Dictionary(grouping: allKeywords, by: { $0 })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .prefix(10)
        
        var yPosition: CGFloat = 100
        for (keyword, count) in keywordCounts {
            let fontSize = min(max(12, CGFloat(count) * 2), 24)
            let font = UIFont.systemFont(ofSize: fontSize)
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.systemBlue.withAlphaComponent(min(1.0, CGFloat(count) / 10.0))
            ]
            
            let text = "\(keyword) (\(count))"
            text.draw(at: CGPoint(x: 40, y: yPosition), withAttributes: attributes)
            yPosition += fontSize + 10
        }
    }
    
    private func drawChartsPage(context: UIGraphicsPDFRendererContext, entries: [JournalEntry], pageRect: CGRect) {
        let titleFont = UIFont.boldSystemFont(ofSize: 24)
        let title = "Mood Trends"
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.label
        ]
        
        title.draw(at: CGPoint(x: 40, y: 40), withAttributes: titleAttributes)
        
        // Simple chart representation
        let chartRect = CGRect(x: 40, y: 100, width: pageRect.width - 80, height: 300)
        drawSimpleChart(context: context, entries: entries, rect: chartRect)
    }
    
    private func drawSimpleChart(context: UIGraphicsPDFRendererContext, entries: [JournalEntry], rect: CGRect) {
        let sortedEntries = entries.sorted { $0.createdAt < $1.createdAt }
        let validEntries = sortedEntries.compactMap { entry -> (Date, Double)? in
            guard let sentiment = entry.sentiment else { return nil }
            return (entry.createdAt, sentiment)
        }
        
        guard validEntries.count > 1 else { return }
        
        let path = UIBezierPath()
        let xStep = rect.width / CGFloat(validEntries.count - 1)
        let yRange: CGFloat = 2.0 // -1 to 1
        let yStep = rect.height / yRange
        
        for (index, (date, sentiment)) in validEntries.enumerated() {
            let x = rect.minX + CGFloat(index) * xStep
            let y = rect.maxY - (sentiment + 1.0) * yStep / 2
            
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        UIColor.systemBlue.setStroke()
        path.lineWidth = 2
        path.stroke()
        
        // Draw points
        for (index, (date, sentiment)) in validEntries.enumerated() {
            let x = rect.minX + CGFloat(index) * xStep
            let y = rect.maxY - (sentiment + 1.0) * yStep / 2
            
            let pointRect = CGRect(x: x - 3, y: y - 3, width: 6, height: 6)
            let pointPath = UIBezierPath(ovalIn: pointRect)
            UIColor.systemBlue.setFill()
            pointPath.fill()
        }
    }
    
    private func drawRawTextPage(context: UIGraphicsPDFRendererContext, entries: [JournalEntry], pageRect: CGRect) {
        let titleFont = UIFont.boldSystemFont(ofSize: 24)
        let entryFont = UIFont.systemFont(ofSize: 12)
        
        let title = "Journal Entries (Raw Text)"
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.label
        ]
        
        title.draw(at: CGPoint(x: 40, y: 40), withAttributes: titleAttributes)
        
        var yPosition: CGFloat = 80
        let maxWidth = pageRect.width - 80
        
        for entry in entries.sorted(by: { $0.createdAt > $1.createdAt }) {
            let dateString = entry.createdAt.formatted(date: .abbreviated, time: .shortened)
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 14),
                .foregroundColor: UIColor.secondaryLabel
            ]
            
            dateString.draw(at: CGPoint(x: 40, y: yPosition), withAttributes: dateAttributes)
            yPosition += 20
            
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: entryFont,
                .foregroundColor: UIColor.label
            ]
            
            let textRect = CGRect(x: 40, y: yPosition, width: maxWidth, height: 200)
            entry.text.draw(in: textRect, withAttributes: textAttributes)
            
            yPosition += 220
            
            if yPosition > pageRect.height - 100 {
                context.beginPage()
                yPosition = 40
            }
        }
    }
}
