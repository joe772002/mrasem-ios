//
//  CircleButtonView.swift
//  MTCIT
//
//  Created by Ebtehal Elsaid on 22/10/2025.
//

import SwiftUI

struct CircleButtonView: View {
    let icon : String
    var badge: Int?
    let action: () -> Void
    var body: some View {
        Button(action: {
            action()
        }) {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 42, height: 42)
                    .overlay(
                        Image(systemName: icon)
                            .font(Font.setFont(size: 17))
                            .foregroundColor(.white)
                    )
                
                if let count = badge, count > 0 {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 18, height: 18)
                        .overlay(
                            Text("\(count)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .offset(x: 4, y: -4)
                }
            }
        }
    }
}

#Preview {
    CircleButtonView(icon: "bell", badge: 3, action: {})
}
