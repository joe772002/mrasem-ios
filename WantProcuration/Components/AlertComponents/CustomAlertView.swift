//
//  CustomAlertView.swift
//  MTCIT
//
//  Created by Ebtehal Elsaid on 07/10/2025.
//

import SwiftUI
// MARK: - Custom Alert View
struct CustomAlertView: View {
    let type: CustomAlertType
    let title: String
    let message: String
    let primaryButton: CustomAlertButton
    let secondaryButton: CustomAlertButton?
    @Binding var isPresented: Bool
    
    init(
        type: CustomAlertType,
        title: String,
        message: String,
        primaryButton: CustomAlertButton,
        secondaryButton: CustomAlertButton? = nil,
        isPresented: Binding<Bool>
    ) {
        self.type = type
        self.title = title
        self.message = message
        self.primaryButton = primaryButton
        self.secondaryButton = secondaryButton
        self._isPresented = isPresented
    }
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        isPresented = false
                    }
                }
            
            // Alert content
            VStack(spacing: 10) {
                // Icon
                Image(systemName: type.iconName)
                    .font(.system(size: 50))
                    .foregroundColor(type.iconColor)
                
                // Title
                Text(title)
                    .font(.setFontBold())
                    .multilineTextAlignment(.center)
                
                // Message
                Text(message)
                    .font(.setFontRegular())
                    .foregroundColor(.theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Buttons
                HStack(spacing: 8) {
                    // Primary button
                    Button(action: {
                        withAnimation {
                            isPresented = false
                        }
                        primaryButton.action()
                    }) {
                        Text(primaryButton.title)
                            .font(.setFontSemiBold())
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(primaryButton.style.backgroundColor)
                            .foregroundColor(primaryButton.style.foregroundColor)
                            .cornerRadius(10)
                    }
                    
                    // Secondary button (if provided)
                    if let secondary = secondaryButton {
                        Button(action: {
                            withAnimation {
                                isPresented = false
                            }
                            secondary.action()
                        }) {
                            Text(secondary.title)
                                .font(.setFontSemiBold())
                                .frame(maxWidth: .infinity)
                                .padding(10)
                                .background(secondary.style.backgroundColor)
                                .foregroundColor(secondary.style.foregroundColor)
                                .cornerRadius(10)
                        }
                    }
                }
            }
            .padding(30)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding(40)
        }
    }
}
// MARK: - Alert Type Enum
enum CustomAlertType {
    case warning
    case error
    case correct
    case information
    
    var iconName: String {
        switch self {
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        case .correct: return "checkmark.circle.fill"
        case .information: return "info.circle.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .warning: return .orange
        case .error: return .red
        case .correct: return .green
        case .information: return .gold
        }
    }
}

// MARK: - Alert Button Model
struct CustomAlertButton {
    let title: String
    let action: () -> Void
    let style: ButtonStyle
    
    enum ButtonStyle {
        case primary
        case secondary
        case destructive
        
        var backgroundColor: Color {
            switch self {
            case .primary: return .theme.themeBlue
            case .secondary: return .theme.themeGray.opacity(0.2)
            case .destructive: return .red
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary: return .white
            case .secondary: return .theme.text
            case .destructive: return .white
            }
        }
    }
}
