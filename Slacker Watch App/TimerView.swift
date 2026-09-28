//
//  TimerView.swift
//  Slacker Watch App
//
//  Created by Gautam Menon on 19/07/26.
//

import SwiftUI

struct TimerView: View {
    @State private var value = 5
    @Binding var selectedDuration: Int
    @Environment(\.dismiss) var dismiss
    var body: some View {
        VStack {
            HStack {
                Button {
                    guard value != 5 else { return }
                    value -= 5
                } label: {
                    Image(systemName: "minus")
                        .bold()
                }
                .buttonBorderShape(.circle)
                .buttonStyle(.borderedProminent)
                .controlSize(.mini)
            .tint(primary)
                Text("\(value)")
                    .font(.largeTitle)
                    .bold()
                Button {
                    value += 5
                } label: {
                    Image(systemName: "plus")
                        .bold()
                }
                .buttonBorderShape(.circle)
                .buttonStyle(.borderedProminent)
                .controlSize(.mini)
                .tint(primary)
            }
            Text("Minutes")
                .font(.footnote)
            Button {
                selectedDuration = value * 60
                dismiss()
            } label: {
                Text("Set")
            }
            .buttonStyle(.borderedProminent)
            .tint(primary)
        }
    }
}

#Preview {
    TimerView(selectedDuration: .constant(10))
}
