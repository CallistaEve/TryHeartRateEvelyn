//
//  WatchConnectivityManager.swift
//  TryHeartRate
//
//  Created by Steven Ongkowidjojo on 16/10/24.
//

import Foundation
import WatchConnectivity
import HealthKit

class WatchConnectivityManagerPhone: NSObject, ObservableObject, WCSessionDelegate {
    
    @Published var currentHeartRate: Double = 0.0
    @Published var isSessionRunning: Bool = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var timer: Timer?
    
    static let shared = WatchConnectivityManagerPhone()
    
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
        sendElapsedTimeUpdate()
    }
    
    func stopSession() {
        isSessionRunning = false
        stopTimer()
        sendMessage(["action": "end", "reset": true])
        print("iOS: End session message sent to watch")
    }
    
    func sendElapsedTimeUpdate() {
        guard isSessionRunning else { return } // Do not send updates if the session is not running
        sendMessage(["action": "sync", "elapsedTime": elapsedTime])
    }
    
    func updateCurrentHeartRate(_ heartRate: String) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .heartRateUpdated, object: heartRate)
        }
    }
    
    // Handle receiving messages
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            print("iOS: Received message: \(message)")
            if let action = message["action"] as? String {
                switch action {
                case "start":
                    self.isSessionRunning = true
                    if let elapsedTime = message["elapsedTime"] as? TimeInterval {
                        self.elapsedTime = elapsedTime
                    }
                case "sync":
                    guard self.isSessionRunning else { return }
                    if let elapsedTime = message["elapsedTime"] as? TimeInterval {
                        self.elapsedTime = elapsedTime
                    }
                case "end":
                    self.isSessionRunning = false
                    if let reset = message["reset"] as? Bool, reset {
                        self.elapsedTime = 0
                        self.stopTimer()
                    }
                case "updateHeartRate":
                    if let heartRate = message["currentHeartRate"] as? String {
                        print("iOS: Received heart rate: \(heartRate)")
                        self.updateCurrentHeartRate(heartRate)
                    }
                default:
                    break
                }
            }
            if let heartRate = message["currentHeartRate"] as? Double {
                DispatchQueue.main.async {
                    self.currentHeartRate = heartRate
                    print("Received heart rate: \(heartRate)")
                }
            }else {
                print("No heart rate received")
            }
        }
    }

    func stopTimer() {
        print("iOS: Stopping timer") // Log timer stop action
        timer?.invalidate()
        timer = nil
    }
    
    // WCSessionDelegate required methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    
    func sessionDidBecomeInactive(_ session: WCSession) {}
    
    func sessionDidDeactivate(_ session: WCSession) {}
}

extension NSNotification.Name {
    static let heartRateUpdated = NSNotification.Name("heartRateUpdated")
}
