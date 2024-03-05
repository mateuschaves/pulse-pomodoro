//
//  ContentView.swift
//  PulsePomodoro Watch App
//
//  Created by Mateus Henrique on 02/03/24.
//
import WatchKit
import SwiftUI
import UIKit
import HealthKit
import UserNotifications

extension Date {
    init(month: Int, day: Int, year: Int, hour: Int = 0, minute: Int = 0, second: Int = 0) {
        var dateComponents = DateComponents()
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.year = year
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.second = second
        dateComponents.timeZone = .current
        dateComponents.calendar = .current
        self = Calendar.current.date(from: dateComponents) ?? Date()
    }
}

class HeartRateMonitor {
    let healthStore = HKHealthStore()
    var query: HKObserverQuery?
    
    func requestAuthorization() {
        let typesToRead: Set<HKSampleType> = [HKObjectType.quantityType(forIdentifier: .heartRate)!, HKObjectType.quantityType(forIdentifier: .respiratoryRate)!]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { (success, error) in
            if success {
                print("Authorization granted")
            } else {
                print("Authorization denied")
            }
        }
    }
    
    func getHeartRateFromLastSeconds(seconds: Int, completion: @escaping (Int?) -> Void) {
        let healthStore = HKHealthStore()
        
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .minute, value: -seconds, to: endDate)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: HKObjectType.quantityType(forIdentifier: .heartRate)!, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            if let error = error {
                print("Error querying heart rate data: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            var heartRateToShow = 0
            if let heartRateSamples = samples as? [HKQuantitySample] {
                for sample in heartRateSamples {
                    let heartRate = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                    heartRateToShow += Int(heartRate)
                }
                
                heartRateToShow = heartRateToShow / max(1, heartRateSamples.count)
            }
            
            completion(heartRateToShow)
        }
        
        healthStore.execute(query)
    }
    
    func getRespirationRateFromLastSeconds(seconds: Int, completion: @escaping (Int?) -> Void) {
        let healthStore = HKHealthStore()
        
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .minute, value: -seconds, to: endDate)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: HKObjectType.quantityType(forIdentifier: .respiratoryRate)!, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            if let error = error {
                print("Error querying respiration rate data: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            var respirationRateToShow = 0
            if let respirationRateSamples = samples as? [HKQuantitySample] {
                for sample in respirationRateSamples {
                    let respirationRate = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                    respirationRateToShow += Int(respirationRate)
                }
                
                respirationRateToShow = respirationRateToShow / max(1, respirationRateSamples.count)
            }
            
            completion(respirationRateToShow)
        }
        
        healthStore.execute(query)
    }
    
    func isRestingHeartRateNormal(heartRate: Int) -> Bool {
        return heartRate < 100 && heartRate > 50
    }

    func isRespirationRateNormal(respirationRate: Int) -> Bool {
        return respirationRate < 25 && respirationRate > 10
    }
}

class LocalStorageManager {
    static let shared = LocalStorageManager()
    
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    func save(key: String, value: Any) {
        defaults.set(value, forKey: key)
    }
    
    func get(key: String) -> Any? {
        return defaults.value(forKey: key)
    }
}

struct Pomodoro: Codable {
    var heartRate: Int
    var respiratoryRate: Int
    var startDate: Date
    var endDate: Date
    var duration: Int
    var isHeartRateNormal: Bool
    var isRespirationRateNormal: Bool
    var isCompleted: Bool
}

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

struct ContentView: View {
    @State private var minutes = 0
    @State private var showRemainingMinutes = false
    @State private var heartRateToShow = 0
    
    let heartRateMonitor = HeartRateMonitor()
    
    var body: some View {
        NavigationView {
            VStack {
                Stepper(value: $minutes, in: 0...60, step: 1) {
                    Text("\(minutes) minutes")
                        .font(.headline)
                }
                .padding(.top, 18)
                .padding(.bottom, 18)
                
                NavigationLink(
                    destination: RemainingMinutesView(timerSeconds: minutes * 60),
                    label: {
                        Text("Confirm")
                    })
            }.navigationTitle("Focus time")
        }.onAppear(perform: {
            heartRateMonitor.requestAuthorization()
            // print previous pomodoros
            if let pomodoros = LocalStorageManager.shared.get(key: "pomodoros") as? [Data] {
                for pomodoro in pomodoros {
                    do {
                        let decodedPomodoro = try JSONDecoder().decode(Pomodoro.self, from: pomodoro)
                        print("Pomodoro: \(decodedPomodoro)")
                    } catch {
                        print("Error decoding pomodoro: \(error)")
                    }
                }
            }
        })
    }
}


