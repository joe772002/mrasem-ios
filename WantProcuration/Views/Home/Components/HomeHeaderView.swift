//
//  HomeHeaderView.swift
//  WantProcuration
//
//  Created by Ebtehal Elsaid on 27/10/2025.
//

import SwiftUI
import SwiftfulRouting


// MARK: - Simple Header
struct HomeHeaderView: View {
    
    @Environment(\.router) private var router
    @ObservedObject var appManager: AppManager

    var body: some View {
        HStack(spacing: 16) {
            // settings Button
            Button(action: {
                
               
                
            }) {
                ZStack {
                    Circle()
                        .fill(Color.theme.themeBlue.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.theme.themeBlue)
                }
            }
            
            // Title
            VStack(alignment: .leading) {
                Text("welcome".localized())
                    .font(.setFontBold(size: 24))
                    .foregroundColor(.theme.text)
                
                Text("welcome2".localized())
                    .font(.setFontRegular(size: 15))
                    .foregroundColor(.theme.text)
            }
            
            Spacer()
            
            
            // settings Button
            Button(action: {
                router.showScreen(.push) { _ in
                    return  SettingsView(appManager: appManager)
                }
            }) {
                ZStack {
                    Circle()
                        .fill( Color.theme.white1)
                        .frame(width: 48, height: 48)
                        .shadow(color:  .black.opacity(0.06), radius: 8, y: 4)
                    
                    Image(systemName:  "gear")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor( .theme.text)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 4)
//        .background(Color.theme.white1)
    }
}
