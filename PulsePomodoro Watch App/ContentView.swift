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
        let typesToRead: Set<HKSampleType> = [HKObjectType.quantityType(forIdentifier: .heartRate)!]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { (success, error) in
            if success {
                print("Authorization granted")
            } else {
                print("Authorization denied")
            }
        }
    }
    
    func fetchHeartRateData() -> Int {
        // Define the range for the last minute
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .minute, value: -30, to: endDate)!

        // Define the predicate for the query
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        // Define the sort descriptor
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        var heartRateToShow = 0
        // Create the query
        let query = HKSampleQuery(sampleType: HKObjectType.quantityType(forIdentifier: .heartRate)!, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            if let error = error {
                print("Error querying heart rate data: \(error.localizedDescription)")
                return
            }

            // Process the heart rate samples
            
            if let heartRateSamples = samples as? [HKQuantitySample] {
                for sample in heartRateSamples {
                    let heartRate = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                    let timestamp = sample.startDate
                    heartRateToShow = heartRateToShow + Int(heartRate)
                }
                
                heartRateToShow = heartRateToShow / (samples?.count ?? 1)
                
            }
        }

        // Execute the query
        healthStore.execute(query)
        
        return heartRateToShow
    }
    
    func getHeartRateFromLastSeconds(seconds: Double) {
        print("getHeartRateFromLastSeconds \(seconds)")
        // Check if HealthKit is available on this device
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device.")
            return
        }
        
        let healthStore = HKHealthStore()
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        
        
        // Set up the query to retrieve heart rate samples from the last 5 minutes
        let startDate = Date().addingTimeInterval(-300) // 5 minutes ago
        let endDate = Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKStatisticsCollectionQuery(quantityType: heartRateType,
                                                quantitySamplePredicate: predicate,
                                                options: .discreteAverage,
                                                anchorDate: startDate,
                                                intervalComponents: DateComponents(minute: 1))
        
        query.initialResultsHandler = { query, statisticsCollection, error in
            guard let statisticsCollection = statisticsCollection else {
                print("Failed to fetch heart rate data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            // Process the statistics collection to get the average heart rate over the last 5 minutes
            var dateStart = Date(month: 2, day: 3, year: 2024)
            
            var dateEnd = Date(month: 2, day: 5, year: 2024)

            statisticsCollection.enumerateStatistics(from: dateStart, to: dateEnd) { statistics, _ in
                if let averageHeartRate = statistics.averageQuantity() {
                    print("aqui")
                    let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
                    let value = averageHeartRate.doubleValue(for: heartRateUnit)
                    print("Average heart rate over the last 5 minutes: \(value) beats per minute")
                }
                print("statistics \(statistics)")
            }
        }
        
        // Execute the query
        healthStore.execute(query)
    }
}


struct RemainingMinutesView: View {
    var timerSeconds: Int
    
    @State private var remainingSeconds = 0
    @State private var countdownTimer: Timer?
    @State private var showAlert = false
    
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
    
    func startCountdown() {
        remainingSeconds = timerSeconds
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if self.remainingSeconds > 0 {
                self.remainingSeconds -= 1
            } else {
                WKInterfaceDevice.current().play(.success)
                timer.invalidate()
                showAlert = true
                
                heartRateMonitor.fetchHeartRateData()         }
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
        })
    }
}

#Preview {
    ContentView()
}
