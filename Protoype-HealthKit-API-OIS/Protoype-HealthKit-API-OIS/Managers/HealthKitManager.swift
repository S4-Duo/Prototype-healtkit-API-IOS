//
//  HealthKitManager.swift
//  Protoype-HealthKit-API-OIS
//
//  Created by Brett Mulder on 16/02/2023.
//

import Foundation
import HealthKit

func setUpHealthRequest(healthStore: HKHealthStore, readSteps: @escaping () -> Void) {
    if HKHealthStore.isHealthDataAvailable(), let stepCount = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount) {
        healthStore.requestAuthorization(toShare: [stepCount], read: [stepCount]) { success, error in
            if success {
                readSteps()
            } else if error != nil {
                // handle your error here
            }
        }
    }
}

func readStepCount(forToday: Date, healthStore: HKHealthStore, completion: @escaping (Double) -> Void) {
    guard let stepQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
    let now = Date()
    let startOfDay = Calendar.current.startOfDay(for: now)
    
    let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
    
    let query = HKStatisticsQuery(quantityType: stepQuantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
        
        guard let result = result, let sum = result.sumQuantity() else {
            completion(0.0)
            return
        }
        
        completion(sum.doubleValue(for: HKUnit.count()))
    
    }
    
    healthStore.execute(query)
    
}
