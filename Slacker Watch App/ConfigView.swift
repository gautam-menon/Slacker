//
//  ConfigView.swift
//  Slacker Watch App
//
//  Created by Gautam Menon on 19/07/26.
//

import SwiftUI

import SwiftData

struct ConfigView: View {
    @ObservedObject var sessionManager: SessionManager
    @State private var showTimerSheet = false
    var body: some View {
        VStack {
            TextField("Name", text: $sessionManager.sessionName)
                .multilineTextAlignment(.center)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(primary, lineWidth: 2)
                )
                .padding(.bottom)
            HStack(spacing: 10) {
                Image(systemName: "hourglass")
                Text("\(sessionManager.selectedDuration / 60) mins")
                    .font(.subheadline)
                    .bold()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundStyle(.black)
            .background(RoundedRectangle(cornerRadius: 10).fill(.white))
            .onTapGesture {
                showTimerSheet = true
                
            }
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                Text("Start")
                    .font(.subheadline)
                    .bold()
            }
            .padding().frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(RoundedRectangle(cornerRadius: 10).fill(primary))
            .onTapGesture {
                let trimmedName = sessionManager.sessionName.trimmingCharacters(in: .whitespacesAndNewlines)
                sessionManager.start(
                    name: trimmedName.isEmpty ? "Session" : trimmedName,
                    durationMinutes: sessionManager.selectedDuration
                )
            }
        }
        .navigationTitle("New Session")
        .sheet(isPresented: $showTimerSheet) {
            TimerView(selectedDuration: $sessionManager.selectedDuration)
        }
    }
}
