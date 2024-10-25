//
//  ContentView.swift
//  HeartRateMonitorWatch Watch App
//
//  Created by Steven Ongkowidjojo on 16/10/24.
//

import SwiftUI
import HealthKit
import WatchConnectivity

struct ContentView: View {
    
    @State private var startTime: Date?
    
    @ObservedObject var connectivityManagerWatch = WatchConnectivityManagerWatch.shared
    private var healthStore = HKHealthStore()
    @State private var heartRateQuery: HKQuery?
    
    var body: some View {
        VStack {
            Text(formatTime(connectivityManagerWatch.elapsedTime))
            
            Text("Heart Rate: \(connectivityManagerWatch.currentHeartRate) bpm")
                .padding(.bottom, 20)
            
            Button(connectivityManagerWatch.isSessionRunning ? "End Session" : "Start Session") {
                if connectivityManagerWatch.isSessionRunning {
                    stopSession()
                } else {
                    startSession()
                }
            }
        }
        .onAppear {
            requestAuthorization()
            if connectivityManagerWatch.isSessionRunning {
                startTimer(from: Date().addingTimeInterval(-connectivityManagerWatch.elapsedTime))
            }
        }
        .padding()
    }
    
    func startSession() {
            connectivityManagerWatch.startSession()
        }
        
        func stopSession() {
            connectivityManagerWatch.stopSession()
        }
        
        func startHeartRateMonitoring() {
            connectivityManagerWatch.startHeartRateMonitoring()
        }
        
        func stopHeartRateMonitoring() {
            connectivityManagerWatch.stopHeartRateMonitoring()
        }
        
        func requestAuthorization() {
            connectivityManagerWatch.requestAuthorization()
        }
        
        func startTimer(from startTime: Date) {
            connectivityManagerWatch.startTimer(from: startTime)
        }
        
        func stopTimer() {
            connectivityManagerWatch.stopTimer()
        }
        
        func formatTime(_ timeInterval: TimeInterval) -> String {
            return connectivityManagerWatch.formatTime(timeInterval)
        }
}

#Preview {
    ContentView()
}
