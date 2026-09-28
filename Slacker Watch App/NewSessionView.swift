//
//  NewSessionView.swift
//  Slacker Watch App
//
//  Created by Gautam Menon on 19/07/26.
//

import SwiftUI
import Combine

struct NewSessionView: View {
    @ObservedObject var sessionManager = SessionManager.shared
    let size = 90.0
    var body: some View {
            VStack {
                if sessionManager.active {
                    ZStack {
                        SpaceBackgroundView()
                            .ignoresSafeArea()
                        VStack(spacing: 0) {
                            Text(sessionManager.formattedRemaining)
                                .font(.title3)
                                .fontWeight(.bold)
                                .monospacedDigit()
                                .background {
                                    ZStack {
                                        Circle()
                                            .stroke(.gray.opacity(0.25), lineWidth: 4)
                                        Circle()
                                            .trim(from: 0, to: sessionManager.progress)
                                            .stroke(primary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                            .rotationEffect(.degrees(-90))
                                            .animation(.linear(duration: 1), value: sessionManager.progress)
                                        
                                        Text(sessionManager.formattedRemaining)
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .monospacedDigit()
                                    }
                                    .frame(width: size, height: size)
                                }
                                .padding(.vertical, 46)
                            HStack(spacing: 4) {
                                NavigationLink {
                                    MLView()
                                } label: {
                                    Text("👨🏻‍💻")
                                }
                                .buttonStyle(.borderedProminent)
                                .buttonBorderShape(.circle)
                                .tint(.green.opacity(0.2))
                                NavigationLink {
                                    HydrationPageView()
                                } label: {
                                    Text("💧")
                                }
                                .buttonStyle(.borderedProminent)
                                .buttonBorderShape(.circle)
                                .tint(.blue.opacity(0.2))
                                NavigationLink {
                                    StressView()
                                } label: {
                                    Text("😮‍💨")
                                }
                                .buttonStyle(.borderedProminent)
                                .buttonBorderShape(.circle)
                                .tint(.yellow.opacity(0.2))
                                Button {
                                    sessionManager.end()
                                } label: {
                                    Text("❌")
                                }
                                .buttonStyle(.borderedProminent)
                                .buttonBorderShape(.circle)
                                .tint(.red.opacity(0.2))
                            }
                        }
                        .navigationTitle(sessionManager.sessionName + "  \(Int(sessionManager.livePosturePercent.rounded()))%")
                    }
                } else {
                    ConfigView(sessionManager: sessionManager)
                }
            }
        
        .navigationDestination(item: $sessionManager.lastSession) { session in
            SessionDetailsPage(session: session)
        }
    }
}
#Preview {
    NewSessionView()
}
