//
//  RemainingMinutesView.swift
//  PulsePomodoro Watch App
//
//  Created by Mateus Henrique on 05/03/24.
//
import WatchKit
import SwiftUI
import Foundation

struct RemainingMinutesView: View {
    var timerSeconds: Int
    
    @State private var remainingSeconds = 0
    @State private var countdownTimer: Timer?
    @State private var showAlert = false
    @State private var heartRate = 0
    @State private var repiratoryRate = 0
    @State private var startDate = Date()
    
    let heartRateMonitor = HeartRateMonitor()
    
    var body: some View {
        Text("\(self.formatSecondsToMMSS(seconds: remainingSeconds))")
            .font(.largeTitle)
            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
            .padding(.bottom, 20)
            .onAppear {
                startCountdown()
                WKExtension.shared().isFrontmostTimeoutExtended = true
            }.alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Time's Up!"),
                    message: Text("Now you can take a moment to relax 🧘"),
                    dismissButton: .default(Text("Ok!"))
                )
            }
    }
    
    func handleEndCountdown() {
        WKInterfaceDevice.current().play(.success)
        countdownTimer?.invalidate()
        showAlert = true
        
        let dispatchGroup = DispatchGroup()
        
        var heartRate: Int?
        var respiratoryRate: Int?
        
        // Enter dispatch group before starting the first asynchronous task
        dispatchGroup.enter()
        heartRateMonitor.getHeartRateFromLastSeconds(seconds: timerSeconds) { receivedHeartRate in
            heartRate = receivedHeartRate
            dispatchGroup.leave() // Leave the dispatch group when the first task is done
        }
        
        // Enter dispatch group before starting the second asynchronous task
        dispatchGroup.enter()
        heartRateMonitor.getRespirationRateFromLastSeconds(seconds: timerSeconds) { receivedRespiratoryRate in
            respiratoryRate = receivedRespiratoryRate
            dispatchGroup.leave() // Leave the dispatch group when the second task is done
        }
        
        // Notify when both tasks are completed
        dispatchGroup.notify(queue: .main) {
            // Both tasks are finished
            if let heartRate = heartRate, let respiratoryRate = respiratoryRate {
                print("Heart rate on last \(timerSeconds) seconds was \(heartRate)")
                let isHeartRateNormal = heartRateMonitor.isRestingHeartRateNormal(heartRate: heartRate)
                self.heartRate = heartRate
                
                print("Respiratory rate on last \(timerSeconds) seconds was \(respiratoryRate)")
                let isRespirationRateNormal = heartRateMonitor.isRespirationRateNormal(respirationRate: respiratoryRate)
                self.repiratoryRate = respiratoryRate
                // Save pomodoro as JSON array
                var previousPomodoros = LocalStorageManager.shared.get(key: "pomodoros") as? [Data] ?? []
                var currentPomodoroJson: Data?
                do {
                    currentPomodoroJson = try JSONEncoder().encode(
                        Pomodoro(
                            heartRate: heartRate,
                            respiratoryRate: respiratoryRate,
                            startDate: startDate,
                            endDate: Date(),
                            duration: timerSeconds,
                            isHeartRateNormal: isHeartRateNormal,
                            isRespirationRateNormal: isRespirationRateNormal,
                            isCompleted: true
                        )
                    )
                } catch {
                    print("Error encoding current pomodoro: \(error)")
                }
                
                if let currentPomodoroJson = currentPomodoroJson {
                    previousPomodoros.append(currentPomodoroJson)
                    LocalStorageManager.shared.save(key: "pomodoros", value: previousPomodoros)
                }
            }
        }
    }

    
    func startCountdown() {
        remainingSeconds = timerSeconds
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if self.remainingSeconds > 0 {
                self.remainingSeconds -= 1
            } else {
                self.handleEndCountdown()
            }
            NSLog("Segundos restantes: \(self.remainingSeconds)")
        }
    }
    
    func formatSecondsToMMSS(seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
