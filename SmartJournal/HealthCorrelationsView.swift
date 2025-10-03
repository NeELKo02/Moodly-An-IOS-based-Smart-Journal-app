import SwiftUI
import Charts

struct HealthCorrelationsView: View {
    let correlations: HealthCorrelations
    let insights: [String]
    
    var body: some View {
        VStack(spacing: 20) {
            // Insights Card
            if !insights.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text("Insights")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    ForEach(insights, id: \.self) { insight in
                        HStack(alignment: .top) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Text(insight)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            // Correlation Charts
            LazyVStack(spacing: 16) {
                // Sleep vs Mood Chart
                if !correlations.sleepMoodPairs.isEmpty {
                    CorrelationChartView(
                        title: "Sleep vs Mood",
                        data: correlations.sleepMoodPairs.map { 
                            (x: $0.sleep, y: $0.mood, label: "\(String(format: "%.1f", $0.sleep))h")
                        },
                        xAxisLabel: "Sleep Duration (hours)",
                        yAxisLabel: "Mood Score",
                        correlation: correlations.sleepCorrelation
                    )
                }
                
                // Steps vs Mood Chart
                if !correlations.stepMoodPairs.isEmpty {
                    CorrelationChartView(
                        title: "Steps vs Mood",
                        data: correlations.stepMoodPairs.map { 
                            (x: Double($0.steps), y: $0.mood, label: "\($0.steps)")
                        },
                        xAxisLabel: "Step Count",
                        yAxisLabel: "Mood Score",
                        correlation: correlations.stepCorrelation
                    )
                }
                
                // Workout vs Mood Chart
                if !correlations.workoutMoodPairs.isEmpty {
                    CorrelationChartView(
                        title: "Workout vs Mood",
                        data: correlations.workoutMoodPairs.map { 
                            (x: $0.workout, y: $0.mood, label: "\(String(format: "%.0f", $0.workout))m")
                        },
                        xAxisLabel: "Workout Duration (minutes)",
                        yAxisLabel: "Mood Score",
                        correlation: correlations.workoutCorrelation
                    )
                }
            }
            
            // Correlation Summary
            if let sleepCorr = correlations.sleepCorrelation,
               let stepCorr = correlations.stepCorrelation,
               let workoutCorr = correlations.workoutCorrelation {
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Correlation Summary")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 8) {
                        CorrelationRow(
                            title: "Sleep",
                            correlation: sleepCorr,
                            icon: "bed.double.fill"
                        )
                        
                        CorrelationRow(
                            title: "Steps",
                            correlation: stepCorr,
                            icon: "figure.walk"
                        )
                        
                        CorrelationRow(
                            title: "Workout",
                            correlation: workoutCorr,
                            icon: "dumbbell.fill"
                        )
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .padding()
    }
}

struct CorrelationChartView: View {
    let title: String
    let data: [(x: Double, y: Double, label: String)]
    let xAxisLabel: String
    let yAxisLabel: String
    let correlation: Double?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if let correlation = correlation {
                    Text("r = \(String(format: "%.2f", correlation))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(correlationColor(correlation).opacity(0.2))
                        .cornerRadius(8)
                }
            }
            
            Chart {
                ForEach(Array(data.enumerated()), id: \.offset) { index, point in
                    PointMark(
                        x: .value(xAxisLabel, point.x),
                        y: .value(yAxisLabel, point.y)
                    )
                    .foregroundStyle(correlationColor(correlation ?? 0))
                    .annotation(position: .top) {
                        Text(point.label)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let correlation = correlation, abs(correlation) > 0.3 {
                    LineMark(
                        x: .value(xAxisLabel, data.map { $0.x }.min() ?? 0),
                        y: .value(yAxisLabel, data.map { $0.y }.min() ?? 0)
                    )
                    .foregroundStyle(correlationColor(correlation).opacity(0.3))
                    
                    LineMark(
                        x: .value(xAxisLabel, data.map { $0.x }.max() ?? 0),
                        y: .value(yAxisLabel, data.map { $0.y }.max() ?? 0)
                    )
                    .foregroundStyle(correlationColor(correlation).opacity(0.3))
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(position: .bottom) {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func correlationColor(_ correlation: Double) -> Color {
        let absCorrelation = abs(correlation)
        if absCorrelation > 0.7 {
            return correlation > 0 ? .green : .red
        } else if absCorrelation > 0.4 {
            return correlation > 0 ? .blue : .orange
        } else {
            return .gray
        }
    }
}

struct CorrelationRow: View {
    let title: String
    let correlation: Double
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(correlationColor(correlation))
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(correlationDescription(correlation))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func correlationColor(_ correlation: Double) -> Color {
        let absCorrelation = abs(correlation)
        if absCorrelation > 0.7 {
            return correlation > 0 ? .green : .red
        } else if absCorrelation > 0.4 {
            return correlation > 0 ? .blue : .orange
        } else {
            return .gray
        }
    }
    
    private func correlationDescription(_ correlation: Double) -> String {
        let absCorrelation = abs(correlation)
        if absCorrelation > 0.7 {
            return correlation > 0 ? "Strong Positive" : "Strong Negative"
        } else if absCorrelation > 0.4 {
            return correlation > 0 ? "Moderate Positive" : "Moderate Negative"
        } else if absCorrelation > 0.2 {
            return correlation > 0 ? "Weak Positive" : "Weak Negative"
        } else {
            return "No Correlation"
        }
    }
}

#Preview {
    let sampleCorrelations = HealthCorrelations(
        sleepCorrelation: 0.65,
        stepCorrelation: 0.42,
        workoutCorrelation: 0.78,
        sleepMoodPairs: [
            (sleep: 7.5, mood: 0.8),
            (sleep: 6.0, mood: -0.2),
            (sleep: 8.0, mood: 0.9),
            (sleep: 5.5, mood: -0.5)
        ],
        stepMoodPairs: [
            (steps: 8000, mood: 0.6),
            (steps: 3000, mood: -0.1),
            (steps: 12000, mood: 0.8),
            (steps: 2000, mood: -0.3)
        ],
        workoutMoodPairs: [
            (workout: 45.0, mood: 0.9),
            (workout: 0.0, mood: 0.1),
            (workout: 30.0, mood: 0.7),
            (workout: 60.0, mood: 0.8)
        ]
    )
    
    let sampleInsights = [
        "Low mood often follows <6h sleep",
        "Best mood on days with 7k+ steps",
        "Exercise days show improved mood"
    ]
    
    return HealthCorrelationsView(
        correlations: sampleCorrelations,
        insights: sampleInsights
    )
}
