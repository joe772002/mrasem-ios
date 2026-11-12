//
//  CustomNavigationTitle.swift
//  MTCIT
//
//  Created by Ebtehal Elsaid on 07/10/2025.
//

import SwiftUI
struct AdaptiveNavigationTitle: ViewModifier {
    let title: String
    @ObservedObject var appManager: AppManager
    
    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(alignment: .trailing,spacing: 30) { // 👈 controls space inside the title view
                        Spacer(minLength: 16)
                        Text(title.localized())
                            .font(Font.setFontRegular(size: 20))
                            .multilineTextAlignment(.center)
//                            .lineSpacing(8)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom , 20)
                    }
                }
            }
    }
}
