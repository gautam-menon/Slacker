//
//  SessionManager.swift
//  Slacker Watch App
//
//  Created by Gautam Menon on 19/07/26.
//

import Foundation
import SwiftUI
import Combine
import SwiftData

@MainActor
final class SessionManager: ObservableObject {
    static let shared = SessionManager()
    
    
    @Published var livePosturePercent: Double = 50  // raw instantaneous reading, sampled 1x/sec — drives navTitle

    @Published var sessionName = ""
    @Published var selectedDuration: Int = 30
    @Published var active: Bool = false
    @Published var remainingSeconds: Int = 0

    @Published var hydrationCount: Int = 0
    @Published var postureRate: Double = 0     // running average (0-100), single source of truth: drives nav title AND the stored session value
    @Published var stressValue: Double = 0

    @Published var lastSession: StoredSession?

    let durations = [1, 5, 10, 20, 30, 45, 60]

    // Owns the one shared inference source. Started/stopped with the session, so posture
    // is tracked the whole time regardless of which sub-screen (hydration, stress, ML) is visible.
    let motionManager = HandMotionManager()

    private var timerCancellable: AnyCancellable?
    private var modelContext: ModelContext?

    private var postureSampleCount: Int = 0

    // Low-posture alert (moved here from MLView, see note below)
    private var lastPostureAlertTime: Date = .distantPast
    private let postureAlertCooldown: TimeInterval = 60
    private let postureAlertThreshold: Double = 30

    private init() {}

    var progress: Double {
        guard selectedDuration > 0 else { return 0 }
        return Double(remainingSeconds) / Double(selectedDuration)
    }

    func attach(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func start(name: String, durationMinutes: Int) {
        sessionName = name
        selectedDuration = durationMinutes
        remainingSeconds = durationMinutes
        hydrationCount = 0
        postureRate = 0
        livePosturePercent = motionManager.postureProbability * 100   // seed with current value rather than a hardcoded default
        stressValue = 0
        postureSampleCount = 0
        active = true

        motionManager.start()

        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.remainingSeconds > 0 {
                    self.remainingSeconds -= 1
                    self.samplePosture()
                } else {
                    self.end()
                }
            }
    }

    private func samplePosture() {
        let currentPercent = motionManager.postureProbability * 100
        livePosturePercent = currentPercent          // what navTitle reads — raw, just throttled to 1/sec

        postureSampleCount += 1
        postureRate += (currentPercent - postureRate) / Double(postureSampleCount)   // running avg, storage-only
        print(currentPercent)
        if currentPercent < postureAlertThreshold {
            let now = Date()
            if now.timeIntervalSince(lastPostureAlertTime) > postureAlertCooldown {
                lastPostureAlertTime = now
                WKInterfaceDevice.current().play(.notification)
                sendPostureNotification()
            }
        }
    }
    func end() {
        active = false
        timerCancellable?.cancel()
        timerCancellable = nil
        motionManager.stop()

        let elapsed = max(selectedDuration - remainingSeconds, 0)
        let savedSession = StoredSession(
            name: sessionName.isEmpty ? "Session" : sessionName,
            date: Date(),
            sessionDuration: elapsed,
            hydrationCount: hydrationCount,
            postureRate: postureRate,   // already the final running average, no extra step needed
            stressValue: stressValue
        )
        lastSession = savedSession
        persist(session: savedSession)
    }

    private func persist(session: StoredSession) {
        guard let modelContext else { return }
        modelContext.insert(session)
        do {
            try modelContext.save()
        } catch {
            print("Failed to save session: \(error.localizedDescription)")
        }
    }

    var formattedRemaining: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

@Model
final class StoredSession: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var date: Date
    var sessionDuration: Int
    var hydrationCount: Int
    var postureRate: Double
    var stressValue: Double

    init(id: UUID = UUID(), name: String, date: Date, sessionDuration: Int, hydrationCount: Int, postureRate: Double, stressValue: Double) {
        self.id = id
        self.name = name
        self.date = date
        self.sessionDuration = sessionDuration
        self.hydrationCount = hydrationCount
        self.postureRate = postureRate
        self.stressValue = stressValue
    }
}
