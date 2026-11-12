//
//  UpdateRequiredView.swift
//  WantProcuration
//
//  Created by Ebtehal Elsaid on 02/11/2025.
//

import SwiftUI


// MARK: - Update Required View
struct UpdateRequiredView: View {
    let onUpdate: () -> Void
    
    var body: some View {
        ZStack {
            Color.theme.themeBlue.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                
                Text("تحديث مطلوب")
                    .font(.setFontSemiBold(size: 28))
                    .foregroundColor(.white)
                
                Text("Update Required")
                    .font(.setFontSemiBold(size: 24))
                    .foregroundColor(.white.opacity(0.9))
                
                Text("يتوفر إصدار جديد من التطبيق. يرجى التحديث للمتابعة.")
                    .font(.setFont())
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 32)
                
                Text("A new version is available. Please update to continue.")
                    .font(.setFont())
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 32)
                
                Button(action: onUpdate) {
                    Text("تحديث الآن | Update Now")
                        .font(.setFontSemiBold(size: 18))
                        .foregroundColor(Color.theme.themeBlue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                .padding(.top, 16)
                
                Spacer()
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}
