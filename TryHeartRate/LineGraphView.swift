import SwiftUI
import Charts

struct LineGraphView: View {
    @Binding var heartRateData: [Double]  // Data for the graph
    
    var body: some View {
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
        .chartXScale(domain: 0...(heartRateData.count > 1 ? heartRateData.count - 1 : 1))
        .chartYScale(domain: (heartRateData.min() ?? 50) - 10...((heartRateData.max() ?? 50) + 10))
        .frame(width: UIScreen.main.bounds.width * 0.95, height: 250) // Width 95% of screen, fixed height
        .padding(.leading, 20) // Added padding on the left to prevent Y-axis label cutoff
        .padding(.horizontal, 10) // Reduced padding for other sides
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

