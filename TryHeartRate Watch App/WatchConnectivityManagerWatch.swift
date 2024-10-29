//
//  WatchConnectivityManager.swift
//  TryHeartRate
//
//  Created by Steven Ongkowidjojo on 16/10/24.
//

import Foundation
import WatchConnectivity
import HealthKit

class WatchConnectivityManagerWatch: NSObject, ObservableObject, WCSessionDelegate {
    
    @Published var currentHeartRate: Double = 0.0
    @Published var isSessionRunning: Bool = false
    
    @Published var elapsedTime: TimeInterval = 0
    @Published var timer: Timer?
    
    private var count: Int = 0
    private var healthStore = HKHealthStore()
    private var heartRateQuery: HKQuery?
    
    static let shared = WatchConnectivityManagerWatch()
    
    private override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    // Send message to iPhone or Apple Watch
    func sendMessage(_ message: [String: Any]) {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("Error sending message: \(error.localizedDescription)")
            }
        }
    }
    
    // Sync elapsed time when starting or updating the session
    func startSession() {
        isSessionRunning = true
        startTimer(from: Date())
        startHeartRateMonitoring()
        sendMessage(["action": "start", "reset": true])
    }

    func stopSession() {
            isSessionRunning = false
            stopTimer()
            stopHeartRateMonitoring()
            elapsedTime = 0
            sendMessage(["action": "end", "reset": true])
    }

    func sendElapsedTimeUpdate() {
        sendMessage(["action": "sync", "elapsedTime": elapsedTime, "reset": true])
    }
    
    func sendCurrentHeartRate (_ heartRate: String) {
        let message: [String: Any] = ["action": "updateHeartRate", "currentHeartRate": heartRate]
        sendMessage(message)
    }
    
    func sendHeartRateToPhone(currentHeartRate: Double) {
        if WCSession.default.isReachable {
            let message: [String: Any] = ["currentHeartRate": currentHeartRate]
            WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: { error in
                print("Error sending heart rate: \(error.localizedDescription)")
            })
        }
    }

    
    func startHeartRateMonitoring() {
            let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
            let predicate = HKQuery.predicateForSamples(withStart: Date(), end: nil)

            let query = HKAnchoredObjectQuery(type: heartRateType, predicate: predicate, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] (query, samples, deletedObjects, anchor, error) in
                self?.processHeartRateSamples(samples)
            }

            query.updateHandler = { [weak self] (query, samples, deletedObjects, anchor, error) in
                self?.processHeartRateSamples(samples)
            }

            heartRateQuery = query
            healthStore.execute(query)
        }

        func stopHeartRateMonitoring() {
            if let query = heartRateQuery {
                healthStore.stop(query)
                print("Heart rate monitoring stopped")
            }
        }

        func requestAuthorization() {
            let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
            let typesToShare: Set = [heartRateType]
            let typesToRead: Set = [heartRateType]

            healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
                if !success {
                    print("Authorization failed")
                }
            }
        }

    // Handle receiving messages
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let action = message["action"] as? String {
                switch action {
                case "start":
                    self.isSessionRunning = true
                    if let elapsedTime = message["elapsedTime"] as? TimeInterval {
                        self.elapsedTime = elapsedTime
                    }
                    self.startHeartRateMonitoring()
                case "sync":
                    if let elapsedTime = message["elapsedTime"] as? TimeInterval {
                        self.elapsedTime = elapsedTime
                    }
                case "end":
                    self.isSessionRunning = false
                    // Stop the timer and reset if needed
                    if let reset = message["reset"] as? Bool, reset {
                        self.elapsedTime = 0
                        self.stopTimer()
                        self.stopHeartRateMonitoring()
                    }
                case "send":
                    self.isSessionRunning = true
                    if let elapsedTime = message["elapsedTime"] as? TimeInterval {
                        self.elapsedTime = elapsedTime
                    }
                    self.sendMessage(message)
                default:
                    break
                }
            }
        }
    }

    func startTimer(from startTime: Date) {
            elapsedTime = 0
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                self.elapsedTime = Date().timeIntervalSince(startTime)
            }
        }

        func stopTimer() {
            timer?.invalidate()
            timer = nil
        }

        func formatTime(_ timeInterval: TimeInterval) -> String {
            let minutes = Int(timeInterval) / 60
            let seconds = Int(timeInterval) % 60
            return String(format: "%02d:%02d", minutes, seconds)
        }

    func processHeartRateSamples(_ samples: [HKSample]?) {
        guard let heartRateSamples = samples as? [HKQuantitySample] else { return }

        if let sample = heartRateSamples.first {
            let heartRateUnit = HKUnit(from: "count/min")
            currentHeartRate = sample.quantity.doubleValue(for: heartRateUnit)
            sendHeartRateToPhone(currentHeartRate: currentHeartRate) // Send the updated heart rate
            DispatchQueue.main.async {
                print("Heart Rate: \(self.currentHeartRate)")
                print("Count: \(self.count)")
                self.count += 1
            }
        }
    }

    
    // WCSessionDelegate required methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
}
