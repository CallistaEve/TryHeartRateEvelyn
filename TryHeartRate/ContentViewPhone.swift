//
//  ContentView.swift
//  HeartRateMonitorWatch
//
//  Created by Steven Ongkowidjojo on 16/10/24.
//

import SwiftUI
import WatchConnectivity

struct ContentView: View {
    
    @State private var currentHeartRate: Double = 0.0
    @State private var minimumHeartRate: String = "0"
    @State private var maximumHeartRate: String = "0"
    @State private var averageHeartRate: String = "0"
    
    // Timer management
    @State private var startTime: Date?
    
    // WatchConnectivityManager singleton instance
    @ObservedObject var connectivityManagerPhone = WatchConnectivityManagerPhone.shared
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section("Current Heart Rate") {
                        Text("\(connectivityManagerPhone.currentHeartRate, specifier: "%.2f") bpm")
                            .disabled(true)
                    }
                    
                    Section("Minimum Heart Rate") {
                        TextField("Minimum", text: $minimumHeartRate)
                            .disabled(true)
                    }
                    
                    Section("Maximum Heart Rate") {
                        TextField("Maximum", text: $maximumHeartRate)
                            .disabled(true)
                    }
                    
                    Section("Average Heart Rate") {
                        TextField("Average", text: $averageHeartRate)
                            .disabled(true)
                    }
                    
                    Text(formatTime(connectivityManagerPhone.elapsedTime))
                        .font(.title)
                    
                    Button(connectivityManagerPhone.isSessionRunning ? "End Session" : "Start Session") {
                        if connectivityManagerPhone.isSessionRunning {
                            endSession()
                        } else {
                            startSession()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(connectivityManagerPhone.isSessionRunning ? .red : .blue)
                }
            }
            .navigationTitle("HR Test Session")
            .onAppear {
                // Observe heart rate updates from NotificationCenter
                NotificationCenter.default.addObserver(forName: .heartRateUpdated, object: nil, queue: .main) { notification in
                    if let heartRate = notification.object as? Double {
                        self.currentHeartRate = heartRate
                    }
                }
            }
        }
    }
    
    private func startSession() {
        connectivityManagerPhone.isSessionRunning = true
        currentHeartRate = 0.0
        startTimer(from: Date())
        connectivityManagerPhone.sendMessage(["action": "start", "elapsedTime": connectivityManagerPhone.elapsedTime])
    }
    
    private func endSession() {
        connectivityManagerPhone.isSessionRunning = false
        connectivityManagerPhone.stopTimer()
        
        // Reset elapsed time
        connectivityManagerPhone.elapsedTime = 0
        
        // Send end session and reset timer message to the other device
        let message = ["stopHeartRateMonitoring": true]
            connectivityManagerPhone.sendMessage(message)
    }
    
    private func startTimer(from startDate: Date) {
        startTime = startDate
        connectivityManagerPhone.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            connectivityManagerPhone.elapsedTime = Date().timeIntervalSince(startDate)
            connectivityManagerPhone.sendElapsedTimeUpdate() // Sync time periodically
        }
    }
    
    
    private func resetTimer() {
        connectivityManagerPhone.elapsedTime = 0
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

#Preview {
    ContentView()
}
