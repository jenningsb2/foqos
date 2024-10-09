import SwiftUI
import Charts

struct WeeklyBarChart: View {
    let data: [(day: String, value: Double)] = [
        ("Mon", 30),
        ("Tue", 80),
        ("Wed", 20),
        ("Thu", 60),
        ("Fri", 15)
    ]
    
    var body: some View {
        Chart(data, id: \.day) { item in
            BarMark(
                x: .value("Day", item.day),
                y: .value("Value", item.value)
            )
            .foregroundStyle(Color.blue)
            .cornerRadius(10)
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel()
            }
        }
        .chartYAxis(.hidden)
        .frame(height: 200)
    }
}
