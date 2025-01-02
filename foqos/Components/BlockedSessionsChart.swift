import SwiftUI
import Charts

struct BlockedSessionsChart: View {
    let sessions: [BlockedProfileSession]
    
    private var weeklyData: [(date: Date, duration: TimeInterval)] {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        
        let dates = (0..<7).map { dayOffset in
            calendar.date(byAdding: .day, value: -dayOffset, to: startOfToday)!
        }.reversed()
        
        let dailySessions = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.startTime)
        }
        
        return dates.map { date in
            let sessionsForDay = dailySessions[date, default: []]
            let totalDuration = sessionsForDay.reduce(0) { $0 + $1.duration }
            return (date: date, duration: totalDuration)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    var body: some View {
        Chart(weeklyData, id: \.date) { data in
            BarMark(
                x: .value("Day", formatDate(data.date)),
                y: .value("Duration", data.duration/60)
            )
            .foregroundStyle(.green)
            .cornerRadius(4)
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel()
            }
        }
        .chartYAxis {
            AxisMarks { value in
                if let minutes = value.as(Int.self) {
                    AxisValueLabel {
                        Text("\(minutes)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        + Text(" min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .frame(height: 200)
        .padding(.vertical)
    }
}
