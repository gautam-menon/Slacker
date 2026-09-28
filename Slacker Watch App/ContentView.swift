//
//  ContentView.swift
//  Slacker Watch App
//
//  Created by Gautam Menon on 16/07/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var sessionManager = SessionManager.shared
    @Query(sort: \StoredSession.date, order: .reverse) private var sessions: [StoredSession]
    let size = 170.0
    let lineSize = 9.0
    
    private var recentPostureAverage: Double {
        let recentSessions = Array(sessions.prefix(10))
        guard !recentSessions.isEmpty else { return 0 }
        let total = recentSessions.reduce(0.0) { $0 + $1.postureRate }
        return total / Double(recentSessions.count)
    }
    
    private var posturePercentage: Int {
        Int(round(min(max(recentPostureAverage, 0), 100)))
    }
    
    private var recentPostureReadings: [Double] {
        let readings = sessions.prefix(10).map(\.postureRate)
        return Array(readings.reversed())
    }
    
    private var postureTrendGraph: some View {
        let barHeight = 55.0
        return VStack(alignment: .trailing) {
            if recentPostureReadings.isEmpty {
                Text("No data yet")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(minHeight: barHeight)
            } else {
                let values = recentPostureReadings
                let maxValue = max(100.0, values.max() ?? 0)
                let span = max(maxValue, 1.0)
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(values.indices, id: \.self) { index in
                        VStack(alignment: .center, spacing: 0) {
                            Spacer()
                            RoundedRectangle(cornerRadius: 2)
                                .fill(primary)
                                .frame(height: CGFloat(values[index]) / CGFloat(span) * barHeight)
                        }
                        .padding(.horizontal, 4)
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(minHeight: barHeight)
                Text("Session count: \(sessions.count)")
                    .font(.footnote)
                    .foregroundStyle(.gray)
            }
        }
    }
    
    private var postureStatusText: String {
        switch posturePercentage {
        case 80...100:
            return "👍 Posture"
        case 60..<80:
            return "👎 Posture"
        case 30..<60:
            return "🤮 Posture"
        default:
            return "No data"
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: -8) {
                    Text("\(posturePercentage)%")
                        .fontWeight(.semibold)
                        .font(.title2)
                        .foregroundStyle(postureStatusColor(posturePercentage))
                    Text(postureStatusText)
                        .font(.footnote)
                        .foregroundStyle(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                postureTrendGraph
                    .padding(.bottom)
                HStack {
                    NavigationLink {
                        NewSessionView()
                    } label: {
                        Image(systemName: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.circle)
                    .tint(primary)
                   
                    NavigationLink {
                        SessionList()
                    } label: {
                        Image(systemName: "list.bullet")
                            .foregroundStyle(.black)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.circle)
                    .tint(.white)
                    NavigationLink {
                        HandSensorLiveView()
                    } label: {
                        Image(systemName: "sensor")
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.circle)
                    .tint(primary)
                }
            }
        }
        .onAppear {
            sessionManager.attach(modelContext: modelContext)
        }
    }
}

//struct ContentView: View {
//    @State private var showSplash = true
//    var body: some View {
//        NavigationView {
//            if showSplash {
//                SplashView()
//            } else {
//                HomeView()
//            }
//        }
//        .task {
//            try? await Task.sleep(nanoseconds: 2000000000)
//            withAnimation {
//                showSplash = false
//            }
//        }
//    }
//}

#Preview {
    ContentView()
}
