//
//  GovernmentPickerSheet.swift
//  WantProcuration
//
//  Created by Ebtehal Elsaid on 27/10/2025.
//

import SwiftUI

struct GovernmentPickerSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: OfficeViewModel
    @State private var searchText = ""
    @ObservedObject var appManager: AppManager
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.theme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Search bar with enhanced design
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.theme.themeGray)
                        
                        TextField("searchGovernorate", text: $searchText)
                            .font(Font.setFontRegular())
                            .textAlignedToReadingSide()
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.theme.themeGray)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.theme.white1)
                            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // List with enhanced cards
                    ScrollView {
                        VStack(spacing: 12) {
                            // All option card
                            GovernmentOptionCard(
                                icon: "globe",
                                title: "allGovernorates".localized(),
                                isSelected: viewModel.selectedGovernment == nil,
                                action: {
                                    viewModel.selectGovernment(nil)
                                    isPresented = false
                                }
                            )
                            
                            // Government list cards
                            ForEach(filteredGovernments, id: \.desc) { gov in
                                GovernmentOptionCard(
                                    icon: "building.columns.fill",
                                    title: gov.desc,
                                    isSelected: viewModel.selectedGovernment?.desc == gov.desc,
                                    action: {
                                        viewModel.selectGovernment(gov)
                                        isPresented = false
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    
                    if filteredGovernments.isEmpty && !searchText.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 50, weight: .light))
                                .foregroundColor(.theme.themeGray.opacity(0.4))
                            
                            Text("noGovernorateFound".localized())
                                .font(Font.setFontRegular())
                                .foregroundColor(.theme.text)
                        }
                        Spacer()
                    }
                }
            }
            .navigationTitle("selectGovernorate".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .font(Font.setFontSemiBold())
                    .foregroundColor(.theme.themeBlue)
                }
            }
        }
        .environment(\.locale, appManager.locale)           // Add this
        .environment(\.layoutDirection, appManager.layoutDirection)  // Add this
       

    }
    
    private var filteredGovernments: [lookupData] {
        if searchText.isEmpty {
            return viewModel.governments
        } else {
            return viewModel.governments.filter {
                $0.desc.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}
// Enhanced card component with elegant design
struct GovernmentOptionCard: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            withAnimation(.easeInOut(duration: 0.1)) { isPressed = true }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) { isPressed = false }
                action()
            }
        }) {
            HStack(spacing: 16) {
                // Icon with circular background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    isSelected ? Color.theme.themeBlue.opacity(0.15) : Color.theme.darkBlue.opacity(0.1),
                                    isSelected ? Color.theme.themeBlue.opacity(0.1) : Color.theme.darkBlue.opacity(0.05)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(isSelected ? .theme.themeBlue : .theme.darkBlue)
                }
                
                // Text section - now stays next to icon
                Text(title)
                    .font(Font.setFontSemiBold())
                    .foregroundColor(.theme.text)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.theme.themeBlue)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 24))
                        .foregroundColor(.theme.themeGray.opacity(0.3))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(height: 70)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.theme.white1)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Color.theme.themeBlue.opacity(0.3) : Color.theme.themeGray.opacity(0.15),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .shadow(
                color: isSelected ? Color.theme.themeBlue.opacity(0.15) : Color.black.opacity(0.05),
                radius: isPressed ? 8 : 6,
                x: 0,
                y: isPressed ? 4 : 3
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
