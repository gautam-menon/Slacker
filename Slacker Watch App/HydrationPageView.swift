//
//  HydrationPageView.swift
//  Slacker Watch App
//
//  Created by Gautam Menon on 19/07/26.
//

import SwiftUI

struct HydrationPageView: View {
    @ObservedObject var sessionManager = SessionManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .lastTextBaseline) {
                Text("\(sessionManager.hydrationCount)")
                    .font(.system(size: 60))
                    .fontWeight(.bold)
                    .foregroundStyle(primary)
                Text("sips")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            Button {
                sessionManager.hydrationCount += 1
            } label: {
                Text("💧 Log Sip")
                    .font(.footnote)
            }
            .tint(Color.blue)
            Text(timeSinceSip)
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding()
        }
    }
    
    private var timeSinceSip: String {
        guard sessionManager.hydrationCount > 0 else { return "—" }
        return "Just now"
    }
}
