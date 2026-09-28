//
//  SensorView.swift
//  Slacker Watch App
//
//  Created by Gautam Menon on 16/07/26.
//

import Combine
import SwiftUI
import CoreMotion
import CoreML
import WatchConnectivity

enum PostureLabel: String {
    case none = "none"
    case incorrect = "incorrect"
    case correct = "correct"
}

@MainActor
final class HandMotionManager: ObservableObject {

    @Published var motionWindow: [CMDeviceMotion] = []

    let postureModel = try! PostureClassifier(configuration: .init())

    @Published var acceleration: CMAcceleration = .init()
    @Published var rotationRate: CMRotationRate = .init()
    @Published var gravity: CMAcceleration = .init()
    @Published var attitude: (roll: Double, pitch: Double, yaw: Double) = (0, 0, 0)
    @Published var isStreaming = false

    @Published var recordingLabel: PostureLabel = .none
    @Published var sampleCount: Int = 0
    @Published var postureProbability: Double = 0.5

    private let motionManager = CMMotionManager()
    private let connectivity = WatchConnectivityBridge.shared

    private var lastSendTime: TimeInterval = 0
    private let sendThrottleInterval: TimeInterval = 1.0 / 20.0

    // Separate throttle just for console logging so we don't flood Xcode's console at 50Hz.
    private var lastLogTime: TimeInterval = 0
    private let logInterval: TimeInterval = 1.0 / 5.0
    private let windowSize = 100
    private var classificationCounter = 0
    private let classificationStride = 10
    private let samplesPerSecond: Double = 50
    

    // Replace these with the 12 mean values and 12 scale values exported from Python.
    private static let featureMean: [Double] = Array(repeating: 0.0, count: 12)
    private static let featureScale: [Double] = Array(repeating: 1.0, count: 12)

    func start() {
        guard motionManager.isDeviceMotionAvailable, !isStreaming else { return }

        motionManager.deviceMotionUpdateInterval = 1.0 / samplesPerSecond
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self, let motion else {
                if let error { print("Device motion error: \(error.localizedDescription)") }
                return
            }
            self.handle(motion)
        }
        isStreaming = true
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
        stopRecording()
        isStreaming = false
    }

    // MARK: Recording controls

    func startRecording(_ label: PostureLabel) {
        recordingLabel = label
        sampleCount = 0
        if !isStreaming { start() }
    }

    func stopRecording() {
        recordingLabel = .none
    }

    private func features(from motion: CMDeviceMotion) -> [Double] {
        [
            motion.userAcceleration.x,
            motion.userAcceleration.y,
            motion.userAcceleration.z,
            motion.rotationRate.x,
            motion.rotationRate.y,
            motion.rotationRate.z,
            motion.gravity.x,
            motion.gravity.y,
            motion.gravity.z,
            motion.attitude.roll,
            motion.attitude.pitch,
            motion.attitude.yaw
        ]
    }

    func modelInput() -> MLMultiArray? {
        guard motionWindow.count == windowSize,
              Self.featureMean.count == 12,
              Self.featureScale.count == 12,
              let array = try? MLMultiArray(shape: [1, 12, windowSize as NSNumber], dataType: .float32)
        else { return nil }

        for (t, motion) in motionWindow.enumerated() {
            let raw = features(from: motion)
            for c in 0..<12 {
                let normalized = (raw[c] - Self.featureMean[c]) / Self.featureScale[c]
                array[[0, c, t] as [NSNumber]] = NSNumber(value: normalized)
            }
        }

        return array
    }

    func classifyPosture() -> Double? {
        guard let input = modelInput(),
              let output = try? postureModel.prediction(input: PostureClassifierInput(x: input))
        else { return nil }
        let logit = output.var_45[0].doubleValue
        return 1.0 / (1.0 + exp(-logit))
    }

    private func extractLogit(from output: Any) -> Double? {
        let mirror = Mirror(reflecting: output)

        for child in mirror.children {
            if let array = child.value as? MLMultiArray {
                return array[[0] as [NSNumber]].doubleValue
            }

            if let number = child.value as? NSNumber {
                return number.doubleValue
            }

            if let number = child.value as? Double {
                return number
            }
        }

        return nil
    }

    private func handle(_ motion: CMDeviceMotion) {
        acceleration = motion.userAcceleration
        rotationRate = motion.rotationRate
        gravity = motion.gravity
        attitude = (motion.attitude.roll, motion.attitude.pitch, motion.attitude.yaw)
        motionWindow.append(motion)

        if motionWindow.count > windowSize {
            motionWindow.removeFirst()
        }

        if motionWindow.count == windowSize {
            classificationCounter += 1
            if classificationCounter >= classificationStride {
                classificationCounter = 0
                if let probability = classifyPosture() {
                    postureProbability = probability
                }
            }
        }

        let now = Date().timeIntervalSince1970

        // Log to console (CSV) only while actively recording a labeled session.
        if recordingLabel != .none {
//            lastLogTime = now
            sampleCount += 1
            let row = String(
                format: "%@,%.2f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f",
                recordingLabel.rawValue,
                now,
                acceleration.x, acceleration.y, acceleration.z,
                rotationRate.x, rotationRate.y, rotationRate.z,
                gravity.x, gravity.y, gravity.z,
                attitude.roll, attitude.pitch, attitude.yaw
            )
            print(row)
        }

        // WatchConnectivity relay stays independent of recording/logging.
        guard now - lastSendTime >= sendThrottleInterval else { return }
        lastSendTime = now

        let payload: [String: Any] = [
            "t": now,
            "accel": [acceleration.x, acceleration.y, acceleration.z],
            "rotRate": [rotationRate.x, rotationRate.y, rotationRate.z],
            "gravity": [gravity.x, gravity.y, gravity.z],
            "attitude": [attitude.roll, attitude.pitch, attitude.yaw]
        ]
        connectivity.sendLiveSample(payload)
    }
}

// MARK: - WatchConnectivity Bridge

/// Relays sensor samples to the paired iPhone in real time.
/// Uses `sendMessage` (requires the iPhone app to be reachable/foregrounded)
/// and falls back to `updateApplicationContext` (always delivered, but coalesced —
/// only the latest sample survives) so you still get state when the phone isn't active.
final class WatchConnectivityBridge: NSObject, WCSessionDelegate {

    static let shared = WatchConnectivityBridge()

    private let session: WCSession? = WCSession.isSupported() ? .default : nil

    override init() {
        super.init()
        session?.delegate = self
        session?.activate()
    }

    func sendLiveSample(_ payload: [String: Any]) {
        guard let session, session.activationState == .activated else { return }

        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { error in
                print("WC sendMessage failed: \(error.localizedDescription)")
            }
        } else {
            // Best-effort fallback; iPhone gets only the most recent sample.
            try? session.updateApplicationContext(payload)
        }
    }

    // MARK: WCSessionDelegate (required stubs on watchOS)

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error { print("WC activation error: \(error.localizedDescription)") }
    }
}

// MARK: - SwiftUI View

struct HandSensorLiveView: View {
    @StateObject private var motion = HandMotionManager()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {

                Button(action: toggleStreaming) {
                    Label(motion.isStreaming ? "Stop" : "Start",
                          systemImage: motion.isStreaming ? "stop.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .tint(motion.isStreaming ? .red : .green)
                .buttonStyle(.borderedProminent)

                sensorRow("Accel", motion.acceleration.x, motion.acceleration.y, motion.acceleration.z)
                sensorRow("Gyro", motion.rotationRate.x, motion.rotationRate.y, motion.rotationRate.z)
                sensorRow("Gravity", motion.gravity.x, motion.gravity.y, motion.gravity.z)
                sensorRow("Attitude", motion.attitude.roll, motion.attitude.pitch, motion.attitude.yaw)

                Text(motion.isStreaming ? "● Live" : "○ Idle")
                    .font(.caption2)
                    .foregroundStyle(motion.isStreaming ? .green : .secondary)
            }
            .padding(.horizontal, 4)
        }
    }

    private func toggleStreaming() {
        motion.isStreaming ? motion.stop() : motion.start()
    }

    @ViewBuilder
    private func sensorRow(_ label: String, _ x: Double, _ y: Double, _ z: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(String(format: "x:%+.2f y:%+.2f z:%+.2f", x, y, z))
                .font(.system(.caption, design: .monospaced))
        }
    }
}

// MARK: - Preview

#Preview {
    HandSensorLiveView()
}
