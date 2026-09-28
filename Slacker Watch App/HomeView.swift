//
//  HomeView.swift
//  Slacker Watch App
//
//  Created by Gautam Menon on 16/07/26.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("92%")
                .font(.title3)
                .fontWeight(.semibold)
            Text("Completed")
                .font(.footnote)
                .foregroundStyle(.gray)
            Spacer()
            HStack {
                NavigationLink {
                    NewSessionView()
                } label: {
                    Image(systemName: "play.fill")
                }
                .buttonBorderShape(.circle)
                .foregroundStyle(appColor)
                Button {
                    
                } label: {
                    Image(systemName: "list.dash")
                }
                .buttonBorderShape(.circle)
                .foregroundStyle(.white)
                NavigationLink {
                    HandSensorLiveView()
                } label: {
                    Image(systemName: "sensor")
                }
                .buttonBorderShape(.circle)
                .foregroundStyle(appColor)
            }
        }
    }
}

#Preview {
    HomeView()
}
