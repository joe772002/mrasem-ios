//
//  View.swift
//  MTCIT
//
//  Created by Ebtehal Elsaid on 01/10/2025.
//

import SwiftUI
import UIKit
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func limitText(_ text: Binding<String>, to maxLength: Int) -> some View {
         self.onChange(of: text.wrappedValue) { oldValue, newValue in
             if newValue.count > maxLength {
                 text.wrappedValue = String(newValue.prefix(maxLength))
             }
         }
     }
    
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    func adaptiveNavigationTitle(_ title: String, appManager: AppManager) -> some View {
            modifier(AdaptiveNavigationTitle(title: title, appManager: appManager))
    }
    func customAlert(
        isPresented: Binding<Bool>,
        type: CustomAlertType,
        title: String,
        message: String,
        primaryButton: CustomAlertButton,
        secondaryButton: CustomAlertButton? = nil
    ) -> some View {
        ZStack {
            self
            
            if isPresented.wrappedValue {
                CustomAlertView(
                    type: type,
                    title: title,
                    message: message,
                    primaryButton: primaryButton,
                    secondaryButton: secondaryButton,
                    isPresented: isPresented
                )
                .transition(.opacity)
            }
        }
    }


  
}


struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
    
   
}
