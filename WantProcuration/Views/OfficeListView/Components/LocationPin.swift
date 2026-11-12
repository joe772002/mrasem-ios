//
//  LocationPin.swift
//  WantProcuration
//
//  Created by Ebtehal Elsaid on 27/10/2025.
//


import SwiftUI
// MARK: - Location Pin
struct LocationPin: View {
    let color: Color
    let isSpecial: Bool
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 50, height: 50)
                    .shadow(color: color.opacity(0.3), radius: 10, y: 5)
                
                Image(systemName: isSpecial ? "star.fill" : "building.2.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
                if isSpecial {
                    Circle()
                        .fill(color)
                        .frame(width: 18, height: 18)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .offset(x: 15, y: -15)
                }
            }
            
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .offset(y: -4)
        }
        .scaleEffect(animate ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: animate)
        .onAppear { animate = true }
    }
}
