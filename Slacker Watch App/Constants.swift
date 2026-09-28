//
//  Constants.swift
//  Slacker Watch App
//
//  Created by Gautam Menon on 16/07/26.
//

import Foundation
import SwiftUI

let appIcon = "appIcon"
let appTitle = "Slacker"
let appColor = Color.purple

let primary = Color(hex: "9B5DE5")
let secondary = Color(hex: "7333A6")
let bgColor = Color(hex: "381A66")

let leftButton      = Color(hex: "A855F7")
let rightButton     = Color(hex: "3B82F6")

//let appColor = Color(hex: "7333A6")

let accentColor = Color(red: 0.20, green: 1.0, blue: 0.45)

func postureStatusColor(_ posturePercentage: Int) -> Color {
    switch posturePercentage {
    case 80...100:
        return .green
    case 60..<80:
        return .orange
    case 30..<60:
        return .red
    default:
        return .blue
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = (int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}
