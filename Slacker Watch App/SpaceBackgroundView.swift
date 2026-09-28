//
//  SpaceBackgroundView.swift
//  Slacker Watch App
//
//  Created by Gautam Menon on 19/07/26.
//

import SwiftUI

struct SpaceBackgroundView: View {
    var body: some View {
        RadialGradient(
            gradient: Gradient(stops: [
                .init(color: secondary, location: 0.0),
                .init(color: bgColor, location: 0.30),
                .init(color: .black, location: 1.0)
            ]),
            center: .center,
            startRadius: 5,
            endRadius: 110
        )
        .ignoresSafeArea()
    }
}
