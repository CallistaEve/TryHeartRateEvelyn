import SwiftUI
import Charts

struct LineGraphView: View {
    @Binding var heartRateData: [Double]  // Data for the graph
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                Chart {
                    if !heartRateData.isEmpty {
                        ForEach(Array(heartRateData.enumerated()), id: \.offset) { index, value in
                            LineMark(
                                x: .value("Time", index),
                                y: .value("Heart Rate", value)
                            )
                            .foregroundStyle(Color.red)  // Set line color to red
                            .lineStyle(StrokeStyle(lineWidth: 2))
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXScale(domain: 0...(heartRateData.count > 1 ? heartRateData.count - 1 : 1)) // Ensure minimum of 1
                .chartYScale(domain: (heartRateData.min() ?? 50) - 10...((heartRateData.max() ?? 50) + 10)) // Default to 50 if empty
                .frame(width: max(CGFloat(heartRateData.count) * 20, 300)) // Ensure minimum width
            }
            .padding()
        }
        .frame(height: 300) // Set desired height for the graph
    }
}


struct LineChart: View {
    var data: [Double]
    
    var body: some View {
        Chart {
            if !data.isEmpty {
                ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                    LineMark(
                        x: .value("Time", index),
                        y: .value("Heart Rate", value)
                    )
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartXScale(domain: 0...(data.count > 1 ? data.count - 1 : 1))  // Ensure minimum of 1
        .chartYScale(domain: (data.min() ?? 0) - 10...((data.max() ?? 0) + 10))  // Provide fallback for empty array
    }
}

