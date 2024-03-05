//
//  HealhKitService.swift
//  PulsePomodoro Watch App
//
//  Created by Mateus Henrique on 05/03/24.
//

import Foundation
import HealthKit

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
