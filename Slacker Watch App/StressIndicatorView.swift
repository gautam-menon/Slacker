//
//  StressIndicatorView.swift
//  Slacker Watch App
//
//  Created by Gautam Menon on 19/07/26.
//

import SwiftUI
import Combine
import HealthKit

struct StressView: View {
    @StateObject private var monitor = StressMonitor()

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 10)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        monitor.stressLevel.color,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.6), value: progress)

                VStack(spacing: 2) {
                    Image(systemName: monitor.stressLevel.systemImage)
                        .font(.title3)
                        .foregroundStyle(monitor.stressLevel.color)
                    Text(monitor.stressLevel.rawValue)
                        .font(.headline)
                }
            }
            .frame(width: 90, height: 90)

            if let hrv = monitor.currentHRV, let base = monitor.baselineHRV {
                VStack(spacing: 1) {
                    Text("HRV \(Int(hrv))ms")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("baseline \(Int(base))ms")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else if let error = monitor.errorMessage {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            } else {
                Text("Waiting for data…")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .task {
            await monitor.refresh()
        }
        .refreshable {
            await monitor.refresh()
        }
    }

    private var progress: CGFloat {
        switch monitor.stressLevel {
        case .low: return 0.33
        case .medium: return 0.66
        case .high: return 1.0
        case .unknown: return 0.0
        }
    }
}

enum StressLevel: String {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case unknown = "—"

    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .red
        case .unknown: return .gray
        }
    }

    var systemImage: String {
        switch self {
        case .low: return "checkmark.circle.fill"
        case .medium: return "exclamationmark.triangle.fill"
        case .high: return "flame.fill"
        case .unknown: return "questionmark.circle"
        }
    }
}

@MainActor
final class StressMonitor: ObservableObject {

    @Published var stressLevel: StressLevel = .unknown
    @Published var currentHRV: Double?      // ms, SDNN
    @Published var baselineHRV: Double?     // ms, 7-day trailing average
    @Published var currentHeartRate: Double? // bpm
    @Published var isAuthorized = false
    @Published var errorMessage: String?

    private let healthStore = HKHealthStore()

    private let hrvType = HKQuantityType(.heartRateVariabilitySDNN)
    private let hrType = HKQuantityType(.heartRate)

    // Thresholds: % deviation from personal baseline HRV
    // HRV drop -> more stress. These are starting points; tune to taste.
    private let mediumThreshold: Double = 0.85  // below 85% of baseline = medium
    private let highThreshold: Double = 0.65    // below 65% of baseline = high

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = "Health data not available on this device."
            return
        }

        let readTypes: Set<HKObjectType> = [hrvType, hrType]

        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
            await refresh()
        } catch {
            errorMessage = "HealthKit authorization failed: \(error.localizedDescription)"
        }
    }

    func refresh() async {
        guard isAuthorized else {
            await requestAuthorization()
//            guard isAuthorized else { return }
            return
        }

        async let latestHRV = fetchLatestSample(type: hrvType, unit: .secondUnit(with: .milli))
        async let baseline = fetchAverageHRV(daysBack: 7)
        async let latestHR = fetchLatestSample(type: hrType, unit: .count().unitDivided(by: .minute()))

        let (hrv, base, hr) = await (latestHRV, baseline, latestHR)

        currentHRV = hrv
        baselineHRV = base
        currentHeartRate = hr

        classify()
    }

    private func classify() {
        guard let current = currentHRV, let base = baselineHRV, base > 0 else {
            stressLevel = .unknown
            return
        }

        let ratio = current / base

        if ratio < highThreshold {
            stressLevel = .high
        } else if ratio < mediumThreshold {
            stressLevel = .medium
        } else {
            stressLevel = .low
        }
    }

    // MARK: - HealthKit Queries

    private func fetchLatestSample(type: HKQuantityType, unit: HKUnit) async -> Double? {
        await withCheckedContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: sample.quantity.doubleValue(for: unit))
            }
            healthStore.execute(query)
        }
    }

    private func fetchAverageHRV(daysBack: Int) async -> Double? {
        await withCheckedContinuation { continuation in
            let end = Date()
            guard let start = Calendar.current.date(byAdding: .day, value: -daysBack, to: end) else {
                continuation.resume(returning: nil)
                return
            }
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

            let query = HKStatisticsQuery(
                quantityType: hrvType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, statistics, _ in
                let unit = HKUnit.secondUnit(with: .milli)
                let avg = statistics?.averageQuantity()?.doubleValue(for: unit)
                continuation.resume(returning: avg)
            }
            healthStore.execute(query)
        }
    }
}
