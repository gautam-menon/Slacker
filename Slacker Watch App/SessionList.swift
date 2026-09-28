//
//  SessionList.swift
//  Slacker Watch App
//
//  Created by Gautam Menon on 19/07/26.
//

import SwiftUI
import SwiftData

struct SessionList: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StoredSession.date, order: .reverse) private var sessions: [StoredSession]

    var body: some View {
        Group {
            if sessions.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "clock")
                    Text("No saved sessions yet")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
            } else {
                List {
                    ForEach(sessions) { session in
                        NavigationLink {
                            SessionDetailsPage(session: session)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(session.name)
                                        .font(.footnote)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Text("\(session.postureRate, specifier: "%.1f")%")
                                        .foregroundStyle(postureStatusColor(Int(session.postureRate)))
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                }
                                HStack {
                                    Text(session.date, style: .date)
                                    Spacer()
                                    Text("\(session.sessionDuration / 60)m")
                                }
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Session List")
        .onAppear {
            SessionManager.shared.attach(modelContext: modelContext)
        }
    }
}

