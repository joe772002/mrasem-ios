//
//  HomeBackground.swift
//  WantProcuration
//
//  Created by Ebtehal Elsaid on 29/10/2025.
//

import SwiftUI

struct HomeBackground: View {
    var body: some View {
        // Mesh gradient background with animated layers
        ZStack {
            // Base layer - soft gradient
            LinearGradient(
                            gradient: Gradient(colors: [
                                Color.theme.accent.opacity(0.14),
                                Color.theme.accent.opacity(0.04),
                                Color.theme.background,
                                Color.theme.background
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
            
//            Color.theme.background
            // Geometric patterns
            GeometryReader { geometry in
                // Floating orbs with blur
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 98/255, green: 138/255, blue: 236/255).opacity(0.07),
                                    Color(red: 98/255, green: 138/255, blue: 236/255).opacity(0.05),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 20,
                                endRadius: 180
                            )
                        )
                        .frame(width: 360, height: 360)
                        .blur(radius: 40)
                        .offset(x: geometry.size.width * 0.8, y: -100)
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 110/255, green: 179/255, blue: 166/255).opacity(0.06),
                                    Color(red: 110/255, green: 179/255, blue: 166/255).opacity(0.04),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 20,
                                endRadius: 150
                            )
                        )
                        .frame(width: 300, height: 300)
                        .blur(radius: 35)
                        .offset(x: -80, y: geometry.size.height * 0.25)
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 195/255, green: 152/255, blue: 71/255).opacity(0.05),
                                    Color(red: 195/255, green: 152/255, blue: 71/255).opacity(0.03),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 20,
                                endRadius: 120
                            )
                        )
                        .frame(width: 240, height: 240)
                        .blur(radius: 30)
                        .offset(x: geometry.size.width * 0.5, y: geometry.size.height * 0.6)
                }
                
            }
        }
        .ignoresSafeArea()
        

    }
}





#Preview {
    HomeBackground()
}
