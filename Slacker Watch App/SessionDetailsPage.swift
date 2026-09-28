//
//  SessionDetailsPage.swift
//  Slacker Watch App
//
//  Created by Gautam Menon on 19/07/26.
//

import SwiftUI

struct SessionDetailsPage: View {
    let session: StoredSession

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text(session.name)
                        .font(.headline)
                    Text(session.date, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }
                summaryRow(emoji: "⏱️", label: "Duration", value: formattedDuration)
                summaryRow(emoji: "💧", label: "Hydration", value: "\(session.hydrationCount)")
                summaryRow(emoji: "🧍", label: "Posture", value: "\(Int(session.postureRate))%")
                summaryRow(emoji: "😮‍💨", label: "Stress", value: stressLabel)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
        }
        .navigationTitle("Summary")
    }

    private var formattedDuration: String {
        let minutes = session.sessionDuration / 60
        let seconds = session.sessionDuration % 60
        return "\(minutes)m \(seconds)s"
    }

    private var stressLabel: String {
        switch session.stressValue {
        case ..<33: return "Low"
        case 33..<66: return "Medium"
        default: return "High"
        }
    }

    @ViewBuilder
    private func summaryRow(emoji: String, label: String, value: String) -> some View {
        HStack {
            Text(emoji)
            Text(label)
                .font(.footnote)
                .foregroundStyle(.gray)
            Spacer()
            Text(value)
                .font(.footnote)
                .fontWeight(.semibold)
        }
    }
}
