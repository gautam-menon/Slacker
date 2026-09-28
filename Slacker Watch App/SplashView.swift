//
//  SplashView.swift
//  Slacker Watch App
//
//  Created by Gautam Menon on 16/07/26.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        VStack {
            Image(appIcon)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: .infinity)
            Text(appTitle)
                .font(.title3)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    SplashView()
}
