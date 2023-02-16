//
//  ContentView.swift
//  Protoype-HealthKit-API-OIS
//
//  Created by Brett Mulder on 16/02/2023.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    @State private var isHealthKitConnected = false
    let healthStore = HKHealthStore()
    @State private var heartRate = 0.0
    @State private var hrv = 0.0
    
    /**
     Check if the healtkit is succesfully connected
     */
    private func checkHealthKitConnection() {
        if HKHealthStore.isHealthDataAvailable() {
            let healthKitTypes: Set = [
                HKObjectType.quantityType(forIdentifier: .heartRate)!
            ]
            healthStore.requestAuthorization(toShare: nil, read: healthKitTypes) { (success, error) in
                if success {
                    isHealthKitConnected = true
                } else {
                    isHealthKitConnected = false
                }
            }
        } else {
            isHealthKitConnected = false
        }
    }
    /**
     Start the heart rate reading
     */
    private func startHeartRateQuery() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        let query = HKObserverQuery(sampleType: heartRateType, predicate: nil) { (query, completionHandler, error) in
            if let error = error {
                print("Error receiving heart rate updates: \(error.localizedDescription)")
                return
            }
            self.fetchLatestHeartRate(completion: { (heartRate) in
                self.heartRate = heartRate
            })
        }
        healthStore.execute(query)
    }
    
    private func fetchLatestHeartRate(completion: @escaping (Double) -> Void) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
            guard error == nil, let samples = samples as? [HKQuantitySample] else { return }
            let mostRecentSample = samples.max(by: { $0.endDate < $1.endDate })
            if let heartRate = mostRecentSample?.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) {
                completion(heartRate)
            }
        }
        healthStore.execute(query)
    }
    
    private func startHRVQuery() {
        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return }
        let query = HKObserverQuery(sampleType: hrvType, predicate: nil) { (query, completionHandler, error) in
            if let error = error {
                print("Error receiving HRV updates: \(error.localizedDescription)")
                return
            }
            self.fetchLatestHRV(completion: { (hrv) in
                self.hrv = hrv
            })
        }
        healthStore.execute(query)
    }
    
    private func fetchLatestHRV(completion: @escaping (Double) -> Void) {
        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return }
        let query = HKSampleQuery(sampleType: hrvType,
                                  predicate: nil,
                                  limit: HKObjectQueryNoLimit,
                                  sortDescriptors: nil) { (query, samples, error) in
            guard error == nil, let samples = samples as? [HKQuantitySample] else { return }
            let mostRecentSample = samples.max(by: { $0.endDate < $1.endDate })
            if let hrv = mostRecentSample?.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)) {
                completion(hrv)
            }
        }
        healthStore.execute(query)
    }
    
    var body: some View {
        VStack {
            Text("Current Heart Rate: \(Int(heartRate))")
            Text("Current HRV: \(hrv, specifier: "%.2f")")
            if isHealthKitConnected{
                Text("connected")
            }else {
                Text("Not connected")
            }
        }
        .onAppear {
            startHeartRateQuery()
            checkHealthKitConnection()
            startHRVQuery()
        }
        
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
