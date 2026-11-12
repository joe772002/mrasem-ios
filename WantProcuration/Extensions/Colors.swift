//
//  Colors.swift
//  MTCIT
//
//  Created by Ebtehal Elsaid on 01/10/2025.
//
import SwiftUI
// MARK: - Color Extensions
import Foundation
import SwiftUI

extension Color {
    
    static let theme = ColorTheme()
//    static let launch = LaunchTheme()
    
}

struct ColorTheme {
    let accent  : Color = Color("AccentColor") // blue
//    let themeBlue  : Color = Color("AccentColor")
    let themeBlue  : Color = Color("darkBlue")
    let background = Color("background")
    let themeGreen = Color("green")
    let lightGreen = Color("lightGreen")
    let lightBlue = Color("lightBlue")
    let themeGray = Color("gray")
    let white1 = Color("white")
    let text = Color("gray0")
   // let text = Color("darkBlue")
    
  
    let secondaryText = Color("gray1")
    let secondaryText2 = Color.gray
    let cardBackground = Color("cardBackground")
    let gold = Color("gold")
    let darkBlue = Color("darkBlue")
    
    
}

struct LaunchTheme {
    let accent = Color("LaunchAccentColor")
    let background = Color("LaunchBackgroundColor")
}
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
