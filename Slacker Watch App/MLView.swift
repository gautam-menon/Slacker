//
//  MLView.swift
//  Slacker Watch App
//
//  Created by Gautam Menon on 19/07/26.
//

import Foundation
import SwiftUI

struct MLView: View {
    @ObservedObject private var motion = SessionManager.shared.motionManager

    private var predictionPercent: Double {
        motion.postureProbability * 100
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Prediction")
                .font(.headline)

            Text("\(predictionPercent, specifier: "%.1f")%")
                .font(.largeTitle)
                .bold()
        }
        .padding()
    }
}

func sendPostureNotification() {
    let content = UNMutableNotificationContent()
    content.title = "Posture Check"
    content.body = "You've been slouching — sit up straight."
    content.sound = .default
    content.interruptionLevel = .timeSensitive

    let request = UNNotificationRequest(
        identifier: UUID().uuidString,
        content: content,
        trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
    )
    UNUserNotificationCenter.current().add(request)
}

#Preview {
    MLView()
}
